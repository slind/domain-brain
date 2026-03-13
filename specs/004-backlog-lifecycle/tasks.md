# Tasks: Backlog Lifecycle Support

**Input**: Design documents from `/specs/004-backlog-lifecycle/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: No test tasks — this feature is implemented as Claude command files with no compiled code. Verification is by manual acceptance scenario invocation per the quickstart.md.

**Organization**: Tasks grouped by user story for independent implementation and verification.

---

## Phase 1: Setup

**Purpose**: Create the command file skeleton and default configuration file that all user story phases build on.

- [x] T001 Create `.claude/commands/triage.md` with YAML frontmatter stub (`description`, `handoffs` pointing to `/query` and `/speckit.specify`), Step headers as comment placeholders, and key-rules section — no logic yet
- [x] T002 [P] Create `domain/config/priorities.md` with the default template content (three sections: Elevate to High, Keep at Medium, Defer to Low) and human-edit instructions

**Checkpoint**: `triage.md` and `priorities.md` exist as scaffolded files; no functional logic yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema migration — backfill all 12 existing backlog entries with `**Status**: open` and `**Priority**: medium` fields. All user stories require these fields to be present.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete. Every `/triage` intent depends on Status and Priority fields existing in `backlog.md`.

- [x] T003 In `domain/distilled/backlog.md`, insert `**Status**: open` and `**Priority**: medium` after every `**Type**: task` line for all 12 existing entries — mechanical Edit operations, one per entry (or a single Write of the full backfilled file)

**Checkpoint**: `backlog.md` has all 12 entries with Status and Priority fields. Verify by grepping for `**Status**` — should find exactly 12 matches.

---

## Phase 3: User Story 1 — View and Prioritise the Backlog (Priority: P1) 🎯 MVP

**Goal**: `/triage` loads `backlog.md`, displays items grouped as in-progress → high → medium → low with sequential item numbers, and supports direct priority assignment ("set N to high/medium/low") with immediate write and no confirmation.

**Independent Test**: Invoke `/triage` with a populated backlog containing mixed-priority entries. Verify grouped display with correct ordering. Say "set 3 to high" — verify item 3's `**Priority**` field is updated in `backlog.md` immediately. Say "show done" — verify Done section is listed. Invoke `/triage` with empty backlog — verify friendly empty message.

- [x] T004 [US1] In `.claude/commands/triage.md`, implement Step 1 (locate domain root — same pattern as `/query` and `/refine`): read `.domain-brain-root` or use `domain/` fallback; stop with error if not found
- [x] T005 [US1] In `.claude/commands/triage.md`, implement Step 2 (load backlog): read `distilled/backlog.md`; separate entries into `open_items`, `in_progress_items`, and `done_items` by reading `**Status**` field on each entry; stop with friendly message if file missing or all sections empty
- [x] T006 [US1] In `.claude/commands/triage.md`, implement Step 3 (display): render the numbered list in priority-grouped format (▶ In Progress → High → Medium → Low) per the display format in `contracts/triage-command.md`; include item count header; print hint bar at bottom
- [x] T007 [US1] In `.claude/commands/triage.md`, implement the `direct priority` intent branch: parse "set N to high/medium/low" → identify entry N in `backlog.md` by position → use Edit tool to update the `**Priority**` field → confirm change and re-display updated item
- [x] T008 [US1] In `.claude/commands/triage.md`, implement "show done" and "show backlog" / "status" display-only intents; implement the empty-backlog and all-done edge case messages
- [x] T009 [US1] In `.claude/commands/triage.md`, implement the main conversational loop (Steps 4–6): after display, prompt "What would you like to do?", interpret intent via the dispatch table, execute, confirm, re-prompt until user exits or gives no further input

**Checkpoint**: `/triage` produces the grouped display and direct priority changes work. Verify against quickstart.md Workflow 1 acceptance scenarios.

---

## Phase 4: User Story 2 — AI-Assisted Reprioritisation (Priority: P2)

**Goal**: Hint-driven ("elevate X") and guidelines-driven ("apply guidelines" / "reprioritise everything") re-ranking via a subagent that returns a proposal table. User confirms before any write. Items previously set by direct assignment are flagged ⚠.

**Independent Test**: From `/triage`, say "elevate anything related to enterprise integration". Verify a proposal table appears listing relevant items with current → proposed priority. Say "no" — verify no changes in `backlog.md`. Repeat and say "yes" — verify only changed items are updated. Say "apply guidelines" — verify full re-ranking proposal appears.

- [x] T010 [US2] In `.claude/commands/triage.md`, implement the hint-driven intent branch: detect "elevate X" / "prioritise related to Y" / "focus on Z" patterns → invoke a general-purpose subagent with all open entries + user hint → parse `PRIORITY_PROPOSAL` JSON array from subagent output
- [x] T011 [US2] In `.claude/commands/triage.md`, implement proposal display: render the proposal table (# / Title / Current → Proposed / Note with ⚠ for was_manual items) → prompt "Apply these changes? (yes / no / select N,M to apply only some)" → on yes: batch-edit all proposed `**Priority**` fields; on no: no writes; on "select N,M": apply only listed item numbers
- [x] T012 [US2] In `.claude/commands/triage.md`, implement the guidelines-driven intent branch ("reprioritise everything" / "apply guidelines"): read `config/priorities.md` if it exists → invoke subagent with all open entries + full guidelines content → same proposal/confirm flow as T011; if no guidelines file, inform user and suggest running "update guidelines" first
- [x] T013 [US2] In the subagent prompt embedded in `triage.md`: write clear instructions for the priority subagent including the `PRIORITY_PROPOSAL` output format spec, the `was_manual` flag rule (true when the entry's priority was last set by a direct user command, not by refine), and the no-op-entry rule (only include items whose proposed priority differs from current)

**Checkpoint**: Hint-driven and guidelines-driven re-ranking produce proposal tables, confirm gate works, writes are correct. No changes made on "no". Verify against quickstart.md Workflow 2.

---

## Phase 5: User Story 3 — Start Work on an Item (Priority: P2)

**Goal**: "start N" marks item N `in-progress`, shows the item description, and offers a single-confirm handoff to `/speckit.specify` with the item body pre-populated as the feature description argument.

**Independent Test**: From `/triage` with open items, say "start 2". Verify item 2's `**Status**` changes to `in-progress` in `backlog.md`. Verify the system shows the item title and body and asks "Ready to start speccing?". Say "yes" — verify `/speckit.specify` is invoked with the item body as argument. Say "not yet" — verify item stays `in-progress` but no spec workflow fires. Try "start N" on an already in-progress item — verify the "already in progress" message and re-prompt.

- [x] T014 [US3] In `.claude/commands/triage.md`, implement the `start` intent branch: parse "start N" / "work on N" / "pick N" → read entry N's title and body text from `backlog.md` → update `**Status**` from `open` to `in-progress` via Edit tool
- [x] T015 [US3] In `.claude/commands/triage.md`, implement the speckit handoff display and confirmation: show item title + body preview → prompt "Ready to start speccing? (yes / not yet)" → on "yes": invoke `/speckit.specify "<body text>"` using the speckit handoff pattern (per `contracts/triage-command.md` Speckit Handoff Contract); on "not yet": confirm item is in-progress, return to session
- [x] T016 [US3] In `.claude/commands/triage.md`, handle the "already in-progress" edge case: if entry N has `**Status**: in-progress`, output "Item N is already in progress: <title>. Start speccing it anyway? (yes / no)" → same handoff flow if yes

**Checkpoint**: Start intent marks in-progress, shows item, fires speckit on confirm. Verify against quickstart.md Workflow 3.

---

## Phase 6: User Story 4 — Close or Drop a Completed Item (Priority: P3)

**Goal**: "close N" requires a rationale, marks item done, moves it to `## Done` section, appends changelog. "drop N" triggers a governed decision with 3 options.

**Independent Test**: From `/triage`, say "close 2". Verify system asks for rationale. Provide it — verify item 2 is `**Status**: done`, moved to `## Done` section, and `distilled/changelog.md` has a new Triage Session entry with the rationale. Try "drop 3" — verify 3-option governed decision appears. Choose option B (de-prioritise) — verify item stays open with `**Priority**: low` and changelog records the drop decision.

- [x] T017 [US4] In `.claude/commands/triage.md`, implement the `close` intent branch: parse "close N" / "done with N" → ask for one-line rationale → on rationale received (or empty after second prompt defaults to "no rationale provided"): update `**Status**` to `done` via Edit tool
- [x] T018 [US4] In `.claude/commands/triage.md`, implement Done section management: check if `## Done` heading exists in `backlog.md`; if not, append it; move the closed entry's full Markdown block (from its `## Title` heading to the next `---`) to below `## Done` using Edit operations (remove from open section, append to Done section)
- [x] T019 [US4] In `.claude/commands/triage.md`, implement changelog append for close: read `distilled/changelog.md` → append a `## YYYY-MM-DD — Triage Session` entry with `### Closed` subsection per the format in `data-model.md` Entity 4; handle multiple closes in one session by accumulating and writing once at session end
- [x] T020 [US4] In `.claude/commands/triage.md`, implement the `drop` governed decision: parse "drop N" / "remove N" / "cancel N" → present 3-option decision (A: mark done with "dropped" rationale; B: de-prioritise to low, keep open; Z: flag as unresolved) → on A: same close flow; on B: Edit `**Priority**` to `low`; on Z: append open ADR to `decisions.md` → in all cases: append `### Dropped` entry to changelog

**Checkpoint**: Close moves item to Done section and logs. Drop triggers governed decision and logs. Verify against quickstart.md Workflow 4.

---

## Phase 7: User Story 5 — Maintain Priority Guidelines (Priority: P3)

**Goal**: "update guidelines" creates/edits `config/priorities.md` in one guided exchange. "apply guidelines" triggers full re-ranking proposal. `/refine` reads the guidelines file when processing new task items and assigns priority instead of always defaulting to `medium`.

**Independent Test (guidelines command)**: From `/triage`, say "update guidelines". Verify system shows template or current content and accepts new rules in one exchange, then writes `config/priorities.md`. Say "apply guidelines" — verify full re-ranking proposal appears. **Independent Test (/refine integration)**: With a `config/priorities.md` containing "scale-related items → high", capture and refine a new task about "scaling the hosted index". Verify the resulting backlog entry has `**Priority**: high`.

- [x] T021 [US5] In `.claude/commands/triage.md`, implement the `update guidelines` intent: if `config/priorities.md` exists, read and display it; if not, show starter template → collect user's rules in one exchange response → write/overwrite `config/priorities.md` using Write tool → confirm and offer "apply guidelines" as next step
- [x] T022 [US5] In `.claude/commands/refine.md`, update the SUBAGENT INSTRUCTIONS — REFINE AGENT section: (a) add `**Status**: open` and `**Priority**: <value>` to the task-typed entry format example; (b) add priority-assignment instruction for `route_and_summarise` task actions (read guidelines if passed, evaluate item against them, assign best-matching priority, default `medium` if no guidelines)
- [x] T023 [US5] In `.claude/commands/refine.md`, update Step 6 (Load distilled context): after loading distilled files, attempt to read `<domain-root>/config/priorities.md`; if it exists, pass its content to the generalist subagent as `priority_guidelines` context; if not, pass `priority_guidelines: null`

**Checkpoint**: Guidelines create/edit works in one exchange. `/refine` assigns non-default priorities when guidelines exist. Verify against quickstart.md Workflow 5 and spec US5 acceptance scenarios.

---

## Phase 8: User Story 6 — Query Backlog via Natural Language (Priority: P3)

**Goal**: `/query` classifies backlog-state questions as `task-management` mode and returns items grouped by priority, loading only `backlog.md`.

**Independent Test**: Invoke `/query "what should we work on next?"`. Verify classification header shows `task-management`, candidates shows `backlog.md` only, and response groups items by priority. Invoke `/query "what's in progress?"` — verify only in-progress items are listed. Invoke `/query "what's done?"` — verify only Done section entries are returned.

- [x] T024 [US6] In `.claude/commands/query.md`, add `task-management` row to the Step 3a mode classification table with trigger patterns: "what's on the backlog", "open tasks", "what's open", "in progress", "what should I work on", "what should we work on", "what's done", "backlog status", "what are we working on", "what's next"
- [x] T025 [US6] In `.claude/commands/query.md`, add `task-management` row to the Step 3b candidate files table: `backlog.md` only; add clarification that second-stage chunk retrieval does NOT apply to `task-management` mode (same rule as `gap-analysis`)
- [x] T026 [US6] In `.claude/commands/query.md`, add `task-management` response format guidance to Step 9 (Compose and output the answer): in-progress items first, then High/Medium/Low priority groups; if question is specifically about in-progress work, show only that section; if specifically about done work, show only Done section

**Checkpoint**: `/query "what's on the backlog?"` returns prioritised view sourced from `backlog.md` only. Verify against quickstart.md Workflow 6 and spec US6 acceptance scenarios.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end validation, edge cases, and consistency review.

- [x] T027 [P] Verify all 7 acceptance scenarios from `plan.md` Verification section end-to-end: (1) /triage shows 12 items grouped by priority, (2) set 2 to high, (3) elevate scaling items — confirm, (4) update guidelines, (5) start 4 → speckit fires, (6) /query "what should we work on" → task-management mode, (7) /refine with priorities.md → new entry has Priority set
- [x] T028 [P] Walk through all 6 workflows in `quickstart.md` sequentially to confirm the guide is accurate and complete; update quickstart if any step description is imprecise
- [x] T029 Verify edge cases from spec: empty backlog message, all-items-done message, hint matches no items response, guidelines file missing fallback, already-in-progress start, no-rationale-on-close fallback, manual-priority conflict flag in proposal table
- [x] T030 [P] Confirm `distilled/changelog.md` format is consistent between `/refine` session entries and `/triage` session entries (same date format, same heading convention, compatible section structure)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately; T001 and T002 are parallel
- **Phase 2 (Foundational)**: Depends on Phase 1 completion — BLOCKS all user stories
- **Phases 3–8 (User Stories)**: All depend on Phase 2 completion
  - Phase 3 (US1) must complete before Phases 4, 5, 6 (they extend triage.md built in Phase 3)
  - Phase 4 (US2) and Phase 5 (US3) can run in parallel after Phase 3 (different triage intents, no shared file conflicts within a session)
  - Phase 7 (US5, /refine extension) and Phase 8 (US6, /query extension) can run in parallel after Phase 3 — they touch different command files
  - Phase 6 (US4) can run in parallel with Phases 7 and 8 after Phase 3
- **Phase 9 (Polish)**: Depends on all desired user stories complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 only — no story dependencies
- **US2 (P2)**: Depends on US1 (extends the triage session loop built in US1)
- **US3 (P2)**: Depends on US1 (uses the same triage session loop)
- **US4 (P3)**: Depends on US1 (close/drop are triage intents)
- **US5 (P3)**: Depends on US1 (guidelines command is a triage intent); also touches `/refine` independently
- **US6 (P3)**: Depends on Phase 2 (backlog.md must have Status/Priority for meaningful response); does not depend on US1

### Within Each User Story

- Load/display logic before intent dispatch
- Individual intents within the same command can be implemented in any order
- Subagent prompt (T013) must be complete before hint-driven intent (T010) can be tested

### Parallel Opportunities

- T001 and T002 (Phase 1): parallel — different files
- T004–T009 (US1): mostly sequential — each step builds on the previous
- T010–T013 (US2) and T014–T016 (US3): can run in parallel after US1 — different intent branches in triage.md
- T022–T023 (US5 refine) and T024–T026 (US6 query): parallel — completely different command files
- T027–T030 (Polish): T027, T028, T030 can run in parallel

---

## Parallel Example: Phases 4, 5, 6 (after US1 complete)

```
After T009 (US1 complete):

  Parallel stream A: T010 → T011 → T012 → T013  (US2: hint-driven reprioritisation)
  Parallel stream B: T014 → T015 → T016          (US3: start work + speckit handoff)
  Parallel stream C: T017 → T018 → T019 → T020   (US4: close/drop + changelog)

After all US2/US3/US4 complete:

  Parallel stream D: T021               (US5: guidelines command in triage.md)
  Parallel stream E: T022 → T023        (US5: /refine extension)
  Parallel stream F: T024 → T025 → T026 (US6: /query extension)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational — backfill (T003)
3. Complete Phase 3: US1 — view and direct priority (T004–T009)
4. **STOP and VALIDATE**: `/triage` shows grouped backlog; "set N to high" works
5. Already useful: the backlog is navigable and prioritisable

### Incremental Delivery

1. Phase 1 + Phase 2 → backlog schema migrated
2. Phase 3 (US1) → backlog visible and directly prioritisable (MVP)
3. Phase 4 (US2) → AI-assisted re-ranking available
4. Phase 5 (US3) → start-work speckit handoff available
5. Phase 6 (US4) → close/drop with audit trail
6. Phases 7+8 (US5+US6) → guidelines automation + query integration
7. Phase 9 → polish and validation

### Total Task Count

- **Phase 1**: 2 tasks
- **Phase 2**: 1 task
- **Phase 3 (US1)**: 6 tasks
- **Phase 4 (US2)**: 4 tasks
- **Phase 5 (US3)**: 3 tasks
- **Phase 6 (US4)**: 4 tasks
- **Phase 7 (US5)**: 3 tasks
- **Phase 8 (US6)**: 3 tasks
- **Phase 9 (Polish)**: 4 tasks
- **Total**: 30 tasks

---

## Notes

- [P] tasks = different files or non-conflicting edits, no dependencies between them
- [Story] label maps task to specific user story for traceability
- All file writes in command implementations use built-in tools (Read, Write, Edit, Glob, Grep, Agent) — no external dependencies
- Verification is manual acceptance scenario testing — invoke the command, observe output, inspect the file state in `backlog.md` and `changelog.md`
- All `/triage` intent branches live in a single `.claude/commands/triage.md` file; implement step-by-step in execution order per the session flow in `contracts/triage-command.md`
