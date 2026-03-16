# Tasks: Distilled Entry Consistency-Check Mechanism (FR-024)

**Input**: Design documents from `/specs/008-consistency-check/`
**Branch**: `008-consistency-check`
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Contract**: [contracts/consistency-check-command.md](contracts/consistency-check-command.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Exact file paths in every description

---

## Phase 1: Setup — Resolve Blocking Prerequisite

**Purpose**: Unblock implementation by closing the open ADR. FR-007 and SC-005 explicitly gate all implementation work on this.

- [ ] T001 Resolve ADR-016 in `domain/distilled/decisions.md` — update status from OPEN to RESOLVED, record Option B (standalone `/consistency-check` command), add Decision and Rationale fields per the standard ADR format

---

## Phase 2: Foundational — Opt-In Backfill

**Purpose**: Add `**Describes**: <path>` lines to existing distilled entries that document command behavior. Without these, the consistency-check command has no candidates to scan and cannot be validated.

**⚠️ CRITICAL**: Complete T001 first (ADR-016 must be resolved before backfilling is authorised). T002–T004 can run in parallel after T001.

- [ ] T002 [P] Add `**Describes**` opt-in lines to `/refine Interface Contract` in `domain/distilled/interfaces.md` — value: `.claude/commands/refine.md`
- [ ] T003 [P] Add `**Describes**` opt-in lines to `/capture Interface Contract`, `/query Interface Contract`, `/frame Interface Contract`, `/seed Interface Contract` in `domain/distilled/interfaces.md` — values: `.claude/commands/capture.md`, `.claude/commands/query.md`, `.claude/commands/frame.md`, `.claude/commands/seed.md`
- [ ] T004 [P] Add `**Describes**` opt-in line to `Refine Pipeline — Type Clusters and Subagents` entry in `domain/distilled/codebases.md` — value: `.claude/commands/refine.md`

**Checkpoint**: Foundation complete — running `grep -r "**Describes**" domain/distilled/` returns ≥5 entries. Command can now be validated end-to-end.

---

## Phase 3: User Story 1 — Detect Stale Entries (Priority: P1) 🎯 MVP

**Goal**: A steward can invoke `/consistency-check` and receive a ranked list of distilled entries whose source command files have changed since the entry was captured.

**Independent Test**: Invoke `/consistency-check`; confirm `/refine Interface Contract` appears as a staleness candidate (captured 2026-03-06, `refine.md` last committed 2026-03-16 — a known-stale entry confirmed in research.md).

### Implementation

- [ ] T005 [US1] Create `.claude/commands/consistency-check.md` with Step 1: domain root discovery (same three-step logic as all other commands: `--domain` arg → `.domain-brain-root` file → `domain/` directory)
- [ ] T006 [US1] Implement Step 2 in `.claude/commands/consistency-check.md`: Grep all `domain/distilled/*.md` files for `**Describes**:` lines; parse file path and owning entry title; build in-memory candidate list
- [ ] T007 [US1] Implement Step 3 in `.claude/commands/consistency-check.md`: for each candidate, run `git log --format="%ai" -1 -- <describes_path> | cut -d' ' -f1` to get the file's last commit date; compare against entry's `**Captured**` date; classify as stale / current / source-deleted per the data-model.md staleness condition
- [ ] T008 [US1] Implement Step 4 in `.claude/commands/consistency-check.md`: output the candidate report in the format specified in `contracts/consistency-check-command.md` — list sorted oldest-first by captured date, showing entry title, distilled file, `**Describes**` path, captured date, file last-changed date, and days delta; output "No stale entries found" message when candidate list is empty

**Checkpoint**: US1 independently testable — invoke command, observe `/refine Interface Contract` listed as stale with correct dates.

---

## Phase 4: User Story 2 — Act on Staleness Report (Priority: P2)

**Goal**: For each surfaced candidate, the steward can dismiss it, trigger re-capture, or archive it — with all resolutions recorded in the changelog.

**Independent Test**: Working through a review session for the `/refine Interface Contract` candidate: dismiss → confirm flag cleared and changelog entry written. Then re-run: confirm entry no longer appears (or appears with updated captured date if re-captured).

### Implementation

- [ ] T009 [US2] Implement Step 5a in `.claude/commands/consistency-check.md`: per-candidate resolution loop — present dismiss / re-capture / archive options one at a time per the output format in `contracts/consistency-check-command.md`; accept natural language responses (e.g., "dismiss", "update it", "archive"); handle "skip all" to close session without resolution
- [ ] T010 [US2] Implement Step 5b: dismiss action — clear the staleness candidate from the session list (no file changes); record resolution as `reviewed` in in-memory session log
- [ ] T011 [US2] Implement Step 5c: re-capture handoff — for `re-captured` outcome, display the entry's current content and prompt the steward to provide updated text; apply the edit to the distilled file using the Edit tool; update `**Captured**` date to today
- [ ] T012 [US2] Implement Step 5d: archive governed action — require one-line rationale; remove the entry block from the distilled file; record as `archived` in session log
- [ ] T013 [US2] Implement source-deleted handling — when `git log` returns empty for `describes_path` AND file does not exist in working tree: surface as "source deleted" with separate prompt (keep entry / archive entry); never classify as stale candidate
- [ ] T014 [US2] Implement Step 6: append session changelog entry to `domain/distilled/changelog.md` in the format specified in `data-model.md` — include candidates-found count, all resolutions with rationale, and source-deleted items; write "No stale entries found" entry if candidate list was empty

**Checkpoint**: US2 independently testable — full review loop: dismiss one candidate, re-capture another; verify changelog entry written with correct content; re-run command to confirm previously-reviewed entries no longer appear.

---

## Phase 5: Polish & Documentation

**Purpose**: Update distilled knowledge base to reflect the new command and convention.

- [ ] T015 [P] Add `/consistency-check` Interface Contract to `domain/distilled/interfaces.md` — use `contracts/consistency-check-command.md` as source; include invocation syntax, session flow, detection logic, all output formats, governed archive action, and files written/read sections
- [ ] T016 [P] Add `Describes-Link Convention` entity to `domain/distilled/codebases.md` — document the opt-in `**Describes**: <path>` field: what it signals, format rules (repo-relative path), single-file-per-entry constraint, how the command discovers it, and the "source deleted" edge case

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on T001 (ADR-016 resolved) — T002/T003/T004 parallel after T001
- **Phase 3 (US1)**: Depends on Phase 2 complete — T005 → T006 → T007 → T008 sequential
- **Phase 4 (US2)**: Depends on Phase 3 complete (T005–T008 must exist to extend) — T009–T014 sequential within command file
- **Phase 5 (Polish)**: Depends on Phase 4 complete — T015 and T016 parallel

### User Story Dependencies

- **US1 (P1)**: Blocked only by Phase 2. Independently testable.
- **US2 (P2)**: Extends the command file created in US1. Sequentially after US1.

### Within Each Phase

- T006 depends on T005 (file must exist before adding steps)
- T007 depends on T006 (candidate list must be built before comparison)
- T008 depends on T007 (candidates must be classified before displaying)
- T009–T014 each add a new step/handler to the command file built in T005–T008

---

## Parallel Execution Examples

### Phase 2 Parallel (after T001)

```
Task: T002 — Add **Describes** to /refine Interface Contract
Task: T003 — Add **Describes** to other 4 interface contracts
Task: T004 — Add **Describes** to Refine Pipeline entry
```

### Phase 5 Parallel

```
Task: T015 — /consistency-check Interface Contract → interfaces.md
Task: T016 — Describes-Link Convention entity → codebases.md
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. T001 — Resolve ADR-016
2. T002–T004 — Backfill `**Describes**` lines (parallel)
3. T005–T008 — Build detection + report output
4. **STOP**: Invoke `/consistency-check`; confirm `/refine Interface Contract` is surfaced with correct staleness dates

### Full Delivery

1. MVP above
2. T009–T014 — Resolution loop + changelog
3. T015–T016 — Documentation polish

---

## Notes

- All implementation is in a single command file: `.claude/commands/consistency-check.md`
- No code to compile, no dependencies to install
- Each `T00N [US1]` task adds a numbered step to the command file — steps are sequential within the file
- Validate at each checkpoint by invoking the command interactively
- The `/refine Interface Contract` entry is the canonical test case for staleness (known-stale from research)
