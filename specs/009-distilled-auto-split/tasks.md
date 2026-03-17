# Tasks: Distilled File Auto-Splitting (Feature 009)

**Input**: Design documents from `/specs/009-distilled-auto-split/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅

**Organization**: Tasks grouped by user story — each story is independently testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other tasks in the same phase
- **[Story]**: User story this task belongs to (US1/US2/US3)
- All implementation tasks target `.claude/commands/refine.md` unless stated otherwise

---

## Phase 1: Setup

**Purpose**: Load context and verify the insertion point before making any edits.

- [X] T001 Read `.claude/commands/refine.md` in full — confirm Step 6 ends and Step 6.5 begins; identify exact prose location for Step 6.2 insertion
- [X] T002 [P] Read `specs/009-distilled-auto-split/research.md` — internalize the 7 decisions (insertion point, entry-count method, threshold config format, recency determination, retirement, changelog, governed decision format)
- [X] T003 [P] Read `specs/009-distilled-auto-split/contracts/threshold-config.md` and `contracts/split-changelog-entry.md` — these are the canonical formats to implement

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the Step 6.2 skeleton and threshold-config loading. No split logic yet — just the scaffolding that all three user stories depend on.

**⚠️ CRITICAL**: US1, US2, and US3 all depend on this phase.

- [X] T004 Insert `## Step 6.2 — Split-Check Pre-Processing Phase` heading and introductory sentence into `.claude/commands/refine.md` immediately after the end of Step 6 (after the `similarity_config` paragraph) and before the `---` separator that precedes Step 6.5
- [X] T005 Add threshold-config loading to Step 6.2 in `.claude/commands/refine.md`: attempt to read `config/split-thresholds.md`; parse `**Threshold**:` value from `## Default` section as `default_threshold` (integer, default 50 if file absent or unparseable); parse `## Per-File Overrides` table into a `per_file_thresholds` map (file path → integer); document that value `0` means "never split"
- [X] T006 Add entry-counting logic to Step 6.2 in `.claude/commands/refine.md`: for each file loaded in Step 6, count level-2 (`## `) headings that represent distilled entries — exclude the file-level `# Title` h1, exclude headings not followed by `**Type**:` metadata (e.g., `## Done` in backlog.md); store result as `entry_count`
- [X] T007 Add split-candidates list construction to Step 6.2 in `.claude/commands/refine.md`: for each file, look up threshold (per-file override → `default_threshold`); skip if threshold is 0; if `entry_count > threshold`, add file to `split_candidates` list; if `entry_count == 1`, add file to `single_entry_warnings` list; if `split_candidates` and `single_entry_warnings` are both empty, skip to Step 6.5 with no output

**Checkpoint**: Step 6.2 now loads config and builds the candidates list. No user-facing output yet.

---

## Phase 3: User Story 1 — Detect an Oversized Distilled File (Priority: P1) 🎯 MVP

**Goal**: `/refine` surfaces a split proposal governed decision before any raw items are processed when a distilled file exceeds the threshold.

**Independent Test**: Seed `domain/distilled/requirements.md` with >50 entries (or lower the threshold in `config/split-thresholds.md` to a small number). Run `/refine`. Confirm: (1) the split proposal appears before any raw items are processed, (2) multiple oversized files surface one at a time, (3) the proposal shows file name, entry count, threshold, active/archived breakdown with date ranges, and all 4 options (A/B/C/Z).

### Implementation for User Story 1

- [X] T008 [US1] Add split-proposal generation logic to Step 6.2 in `.claude/commands/refine.md`: for each `split_candidate`, parse all distilled entries (split on `## ` heading + `---` separator); extract `**Captured**: YYYY-MM-DD` from each entry; sort entries by captured date descending; assign top ⌈N/2⌉ → active group, remainder → archived group; if all captured dates identical, fall back to `**Type**` field grouping; generate sub-file names following `{base}-{group-label}-{n}.md` convention (increment `{n}` if a file with that name already exists)
- [X] T009 [US1] Add governed decision presentation to Step 6.2 in `.claude/commands/refine.md` for each split_candidate: output the decision block using the `file_split_required` trigger format defined in `research.md` Decision 7 — include file name, entry count, threshold, active/archived sub-file names with entry counts and captured date ranges, and options A/B/C/Z; present one candidate at a time (not batched)
- [X] T010 [US1] Add single-entry warning output to Step 6.2 in `.claude/commands/refine.md`: for each file in `single_entry_warnings`, output a warning (not a governed decision) stating the file cannot be split because it contains only one entry, and suggest condensing the entry's body; continue session without blocking

**Checkpoint**: US1 fully functional — detection surfaces correctly, warning surfaces for single-entry files. Options A/B/C/Z visible. Session can be tested end-to-end by choosing B (skip) to continue.

---

## Phase 4: User Story 2 — Confirm and Execute a Split (Priority: P2)

**Goal**: Choosing option A confirms the split, creates sub-files, retires the original, and the refine session continues.

**Independent Test**: With an oversized file and a split proposal visible, choose option A. Confirm: (1) active and archived sub-files created with correct entries, (2) original file overwritten with redirect notice, (3) distilled context reloaded, (4) refine session proceeds to raw item processing, (5) changelog entry contains `### File Splits` subsection with source, sub-files, entry counts, rationale.

### Implementation for User Story 2

- [X] T011 [US2] Add option A handling (confirm) to Step 6.2 in `.claude/commands/refine.md`: collect optional one-line rationale from steward (default "no rationale provided"); proceed to split execution
- [X] T012 [US2] Add sub-file write logic to Step 6.2 in `.claude/commands/refine.md`: for each sub-file in the confirmed proposal, construct its content (file-level `# Title` heading + all assigned entries preserving original Markdown); write to `domain/distilled/{name}` using Write tool
- [X] T013 [US2] Add original file retirement logic to Step 6.2 in `.claude/commands/refine.md`: overwrite the original oversized file using the retirement redirect notice format defined in `research.md` Decision 5 (title heading + blockquote listing split date, active sub-file path, archived sub-file path, and git history note)
- [X] T014 [US2] Add distilled-context reload step to Step 6.2 in `.claude/commands/refine.md`: after each confirmed split, reload the affected file paths — add sub-files to loaded context, remove retired original — so that Step 6.5 semantic duplicate detection has accurate context
- [X] T015 [US2] Add option C handling (redirect/custom grouping) to Step 6.2 in `.claude/commands/refine.md`: accept steward's natural language grouping description; re-generate `SplitProposal` with `grouping_axis = steward_directed`; re-present updated proposal for confirmation (same governed decision turn, not a new one); on re-confirm, execute split
- [X] T016 [US2] Extend Step 12 changelog template in `.claude/commands/refine.md`: add `### File Splits` subsection immediately after `### Autonomous actions` (per contract in `contracts/split-changelog-entry.md`); omit subsection if no splits were executed
- [X] T017 [US2] Extend Step 13 session summary in `.claude/commands/refine.md`: add split count line to the summary output (e.g., `✓ Split <n> oversized files`)

**Checkpoint**: US2 fully functional — confirmed splits execute correctly, changelog updated, session resumes.

---

## Phase 5: User Story 3 — Dismiss or Flag a Split Proposal (Priority: P3)

**Goal**: Options B (skip) and Z (flag as unresolved) work without blocking the session.

**Independent Test**: With an oversized file and split proposal visible, choose option B. Confirm session continues and original file unchanged. Repeat, choose option Z. Confirm an open ADR appears in `decisions.md` and session continues.

### Implementation for User Story 3

- [X] T018 [P] [US3] Add option B handling (skip) to Step 6.2 in `.claude/commands/refine.md`: make no file writes; do not log to changelog (skipped proposals are silent); continue to the next split candidate or to Step 6.5 if no more candidates
- [X] T019 [P] [US3] Add option Z handling (flag as unresolved) to Step 6.2 in `.claude/commands/refine.md`: generate and append an open ADR to `domain/distilled/decisions.md` using the standard `[OPEN] ADR-<NNN>` format per `contracts/split-changelog-entry.md`; determine ADR number by reading `decisions.md` for the highest existing ADR number + 1; continue to next candidate or Step 6.5

**Checkpoint**: All three user stories functional. `/refine` handles every split decision path (confirm / skip / redirect / flag).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Config file, interface contract update, and manual validation.

- [X] T020 Create `domain/config/split-thresholds.md` for this domain brain using the format in `contracts/threshold-config.md` — set default threshold to 50; add per-file override `domain/distilled/changelog.md | 0` (never split the changelog)
- [X] T021 Update `domain/distilled/interfaces.md` — append a new `## /refine Step 6.2 — Split-Check Phase` subsection to the `/refine` Interface Contract entry documenting: trigger conditions, threshold config file path, governed decision options, sub-file naming convention, changelog entry format; add `**Describes**: .claude/commands/refine.md` link if not already present
- [ ] T022 [P] Manual end-to-end validation — US1: lower threshold to 5 in `config/split-thresholds.md`, run `/refine`, confirm split proposal surfaces before raw items with correct entry counts and date ranges; restore threshold after test
- [ ] T023 [P] Manual end-to-end validation — US2: confirm a split proposal, verify active and archived sub-files created with correct entries, original file shows redirect notice, changelog has `### File Splits` entry
- [ ] T024 [P] Manual end-to-end validation — US3: dismiss a proposal (option B) and confirm session continues unchanged; flag a proposal (option Z) and confirm open ADR in `decisions.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user story phases
- **Phase 3 (US1)**: Depends on Phase 2
- **Phase 4 (US2)**: Depends on Phase 3 (US1 detection must work before execute logic is meaningful)
- **Phase 5 (US3)**: Depends on Phase 2; can run in parallel with Phase 4 (options B and Z are independent branches from option A)
- **Phase 6 (Polish)**: Depends on Phases 3, 4, and 5

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no dependencies on US2 or US3
- **US2 (P2)**: Depends on US1 (needs a working governed decision surface to wire option A)
- **US3 (P3)**: Can start after Phase 2 in parallel with US2 (options B and Z are independent of option A)

### Within Each Phase

- Tasks within a phase that are not marked [P] must run sequentially (each builds on the previous)
- Tasks marked [P] can execute concurrently

### Parallel Opportunities

- T002 and T003 (Phase 1 reads) can run in parallel
- T018 and T019 (Phase 5) can run in parallel — they handle independent option branches
- T022, T023, T024 (Phase 6 manual validations) can be run in sequence or parallel

---

## Parallel Example: Phase 5

Both US3 tasks work on different option branches in the same Step 6.2 block:

```
Task: T018 — Add option B (skip) handling
Task: T019 — Add option Z (flag) handling
```

Both can be written simultaneously as they modify independent `if/elif` branches of the decision handler.

---

## Implementation Strategy

### MVP First (User Story 1 + dismiss path only)

1. Complete Phase 1: Setup reads
2. Complete Phase 2: Foundational (scaffolding + config loading)
3. Complete Phase 3: US1 (detection and proposal presentation)
4. Complete T018 from Phase 5: Add option B skip (so the session isn't blocked during testing)
5. **STOP and VALIDATE**: Run `/refine` against an oversized file, confirm detection works, confirm B dismisses cleanly
6. Demo this increment if ready

### Incremental Delivery

1. Setup + Foundational → Step 6.2 scaffolding ready
2. US1 + option B → Detection works, session never blocked → **Testable MVP**
3. US2 → Execution works → Full happy path operational
4. US3 option Z → Governed escalation path complete
5. Phase 6 → Interface contract updated, config in place, manual validation done

---

## Notes

- All tasks modify `.claude/commands/refine.md` except T020 (new config file), T021 (interfaces.md update), and T022–T024 (manual validation)
- No programming language — tasks are prose editing tasks on a Markdown command file
- Each task is granular enough to be completed and committed independently
- The [P] marker on Phase 5 tasks reflects that T018 and T019 modify logically independent branches, not the same paragraph
- Manual validation tasks (T022–T024) are the acceptance test for each user story
