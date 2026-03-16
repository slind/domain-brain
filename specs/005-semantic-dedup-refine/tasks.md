# Tasks: Semantic Duplicate Detection in /refine

**Input**: Design documents from `/specs/005-semantic-dedup-refine/`
**Branch**: `005-semantic-dedup-refine`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**Tests**: Not requested — verification via quickstart.md manual scenarios.

**Organization**: Tasks are grouped by user story. All delivery is edits to a single command
file (`.claude/commands/refine.md`) plus one new config template. Tasks referencing the same
file are sequential; tasks on different files are marked [P].

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Confirm exact edit locations in the current `refine.md` before making changes.

- [x] T001 Read `.claude/commands/refine.md` Step 6 (lines loading distilled context + config files) and Step 6.5 (6.5a exact-duplicate + 6.5b out-of-scope + empty-batch handler) to confirm current structure and identify the three insertion points: (a) end of Step 6 config-loading block, (b) between Step 6.5b and the empty-batch handler, (c) Steps 11/12 pre-filter summary and changelog format

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish `similarity_config` in Step 6 — the in-memory entity that Step 6.5c and the changelog both depend on. Must complete before any user-story phase begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Edit `.claude/commands/refine.md` Step 6: after the existing `config/priorities.md` read block, insert the `config/similarity.md` read block as specified in `contracts/refine-step-6.5c.md` § "Modified Step 6" — populate `similarity_config = { level, source }`, handle missing file (default moderate + session notice), and handle invalid level value (fallback to moderate + warning)
- [x] T003 [P] Create `domain/config/similarity.md` with the template content from `data-model.md` § "New Persistent Entity" — include the `## Threshold` section with `**Level**: moderate` and the full comment block listing allowed values and behavioral definitions

**Checkpoint**: `similarity_config` is populated in every `/refine` session. `domain/config/similarity.md` template exists for domain owners to customise.

---

## Phase 3: User Story 1 — Near-Duplicates Filtered Before Subagent (P1) 🎯 MVP

**Goal**: Raw items that semantically paraphrase an existing distilled entry are removed from
the subagent batch by host pre-filtering, with no governed decision consumed.

**Independent Test**: Run Quickstart Scenario 1 from `quickstart.md` — prepare a batch with a
known paraphrase item, run `/refine`, confirm the item is suppressed and the subagent receives
a smaller batch.

### Implementation for User Story 1

- [x] T004 [US1] Edit `.claude/commands/refine.md`: insert the full Step 6.5c instruction block (from `contracts/refine-step-6.5c.md` § "New Step 6.5c") between Step 6.5b and the existing "Empty batch after pre-filtering" block — include the minimum-length check (20 words), the similarity comparison loop with the three-level behavioral table (`conservative` / `moderate` / `aggressive`), the Edit-tool status update to `refined`, the `pre_filter_results` record with `filter_reason: "semantic_duplicate"`, `matched_entry`, and `similarity_basis` fields, and the pass-through rule for uncertain items
- [x] T005 [US1] Verify the sequential order of the three sub-steps in `.claude/commands/refine.md` Step 6.5: confirm 6.5a (exact-duplicate) runs first, then 6.5b (out-of-scope), then 6.5c (semantic), then the empty-batch handler — no existing sub-step text was accidentally displaced

**Checkpoint**: User Story 1 is fully functional. Run Quickstart Scenario 1 (near-duplicate suppressed) and Scenario 2 (new item passes through) to validate.

---

## Phase 4: User Story 2 — Configurable Similarity Threshold (P2)

**Goal**: Domain owners can change the suppression aggressiveness by editing
`domain/config/similarity.md` without touching any command file.

**Independent Test**: Run Quickstart Scenario 4 from `quickstart.md` — confirm that switching
from `moderate` to `conservative` causes a previously-suppressed paraphrase to pass through
to the subagent.

### Implementation for User Story 2

- [x] T006 [US2] Verify that Step 6.5c in `.claude/commands/refine.md` references `similarity_config.level` (set in T002/Foundational) for every comparison decision — confirm the three behavioral descriptions in the table match the research.md § "Decision 2" definitions exactly and no hardcoded level values appear
- [x] T007 [P] [US2] Verify `domain/config/similarity.md` (created in T003) uses the exact config key and file path documented in `data-model.md` § "New Persistent Entity" — confirm path matches what Step 6 reads (`<domain-root>/config/similarity.md`) and the `**Level**:` key matches what the parser expects

**Checkpoint**: User Story 2 is functional. Threshold changes in `domain/config/similarity.md` take effect on the next `/refine` run. Run Quickstart Scenarios 3, 4, and 5 to validate.

---

## Phase 5: User Story 3 — Semantic Duplicate Outcomes Visible in Changelog (P3)

**Goal**: Every `/refine` session that suppresses semantic duplicates appends a
`### Semantic Duplicates` subsection to the changelog entry; sessions with zero
suppressions produce no empty section.

**Independent Test**: Run Quickstart Scenario 6 from `quickstart.md` — run `/refine` with
no semantic duplicates and verify no `### Semantic Duplicates` section appears in the
changelog. Then run Scenario 1 and verify the section does appear with the correct fields.

### Implementation for User Story 3

- [x] T008 [US3] Edit `.claude/commands/refine.md` Step 11 (session summary output): after the existing exact-duplicate and out-of-scope counts, add the conditional semantic-duplicate count block as specified in `contracts/refine-step-6.5c.md` § "Modified Steps 11/12 — Session summary output" — show count and per-item `<item_id> → matched: <matched_entry>` lines only when count > 0
- [x] T009 [US3] Edit `.claude/commands/refine.md` Step 12 (changelog entry format): after the existing `### Out of Scope` subsection template, add the conditional `### Semantic Duplicates` subsection as specified in `contracts/refine-step-6.5c.md` § "Modified Steps 11/12 — Changelog entry" — include `matched_entry` and `similarity_basis` fields; confirm the conditional (`if any semantic_duplicate entries`) ensures the section is entirely absent when count = 0

**Checkpoint**: All three user stories are independently functional. Run all six Quickstart scenarios in `quickstart.md`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regression check, end-to-end validation, and documentation.

- [x] T010 [P] Run Quickstart Scenario 1 (manual) (near-duplicate suppressed) per `quickstart.md` — confirm subagent receives smaller batch and changelog has `### Semantic Duplicates` subsection
- [x] T011 [P] Run Quickstart Scenario 2 (new item passes through) per `quickstart.md` — confirm no false suppression and no `### Semantic Duplicates` in changelog
- [x] T012 [P] Run Quickstart Scenario 3 (default threshold notice) per `quickstart.md` — temporarily remove `domain/config/similarity.md` and confirm the "No similarity config found" notice appears
- [x] T013 Run Quickstart Scenarios 4 and 5 per `quickstart.md` — verify threshold switching changes suppression behaviour and short items are not compared
- [x] T014 Run Quickstart Scenario 6 per `quickstart.md` — verify clean changelog when no semantic duplicates
- [x] T015 Regression: run `/refine` with a raw item that is a byte-for-byte exact duplicate — confirm it is still caught by Step 6.5a (not 6.5c) and the changelog records `filter_reason: "duplicate"` not `"semantic_duplicate"`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user story phases**
- **US1 (Phase 3)**: Depends on Foundational (needs `similarity_config` from T002)
- **US2 (Phase 4)**: Depends on Foundational (T002 + T003 must exist); T006 depends on T004 (US1) since it verifies the 6.5c table references `similarity_config.level`; T007 is independent [P]
- **US3 (Phase 5)**: Depends on US1 (T004 must exist to populate `pre_filter_results` with semantic-duplicate entries); Steps 11/12 edits are otherwise independent
- **Polish (Phase 6)**: Depends on all story phases complete

### User Story Dependencies

- **US1 (P1)**: Requires Foundational complete. Core of the feature — blocks US2 verification (T006) and US3 changelog content (T008/T009).
- **US2 (P2)**: T006 depends on US1 (T004). T007 is parallel to US1.
- **US3 (P3)**: T008/T009 can be written independently but cannot be meaningfully tested until US1 (T004) populates `pre_filter_results`.

### Within Each Phase

- Phase 2: T002 and T003 are on different files → run in parallel
- Phase 3: T004 before T005 (verify after insert)
- Phase 4: T006 after T004; T007 parallel to T006
- Phase 5: T008 before T009 (both in same file, sequential)
- Phase 6: T010–T014 are all read/run operations → parallel; T015 sequential after T010

### Parallel Opportunities

- T002 and T003 (Foundational — different files)
- T007 (US2 config verify) parallel to T006 (US2 command verify)
- T010, T011, T012 (Polish quickstart runs) parallel to each other

---

## Parallel Example: Foundational Phase

```
# These two tasks touch different files — run together:
Task T002: Edit .claude/commands/refine.md Step 6 (similarity_config loading)
Task T003: Create domain/config/similarity.md template
```

## Parallel Example: Polish Phase

```
# Independent verification runs — all parallel:
Task T010: Quickstart Scenario 1 (near-duplicate suppressed)
Task T011: Quickstart Scenario 2 (new item passes through)
Task T012: Quickstart Scenario 3 (default threshold notice)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002, T003 in parallel)
3. Complete Phase 3: User Story 1 (T004, T005)
4. **STOP and VALIDATE**: Run Quickstart Scenarios 1 and 2
5. Near-duplicate suppression is live — already improves autonomy rate

### Incremental Delivery

1. Setup + Foundational → `similarity_config` in every session
2. Add US1 → near-duplicates suppressed → validate → meaningful autonomy improvement
3. Add US2 → threshold configurable → validate → domain owners can tune
4. Add US3 → changelog auditable → validate → full feature complete
5. Polish → regression verified

---

## Notes

- All delivery is edits to `.claude/commands/refine.md` (one file) plus one new config template. No build, no binary, no migrations.
- The `contracts/refine-step-6.5c.md` artifact contains the exact instruction text to insert — tasks reference it by section name to avoid duplicating content here.
- Tasks T004 and T008/T009 are the only tasks that insert new instruction text into `refine.md`. All other tasks are verification or parallel-file work.
- No tests were requested in the spec. Verification is via the six manual scenarios in `quickstart.md`.
