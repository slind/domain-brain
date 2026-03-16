# Tasks: Additional Specialist Subagents in /refine

**Input**: Design documents from `/specs/006-specialist-subagents/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅

**Organization**: Tasks are grouped by user story. All tasks modify a single file: `.claude/commands/refine.md` — therefore no parallel opportunities exist within the implementation phases (sequential edits to the same file).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies) — not applicable here
- **[Story]**: User story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Read and confirm the current state of the routing table before making changes.

- [x] T001 Read `.claude/commands/refine.md` Step 7 (lines ~186–226) to confirm the exact text of the current routing table and the generalist row that will be split

**Checkpoint**: Current routing table confirmed — implementation can begin

---

## Phase 2: User Story 1 — Codebase Specialist (Priority: P1) 🎯 MVP

**Goal**: `codebase` items are routed to a dedicated specialist that loads only `codebases.md` + `identity.md`, not the full distilled context.

**Independent Test**: Run `/refine` with a batch containing only `codebase` items. Verify the session output shows the codebase specialist was invoked (not the generalist), and confirm no full-distilled-files load occurred.

- [x] T002 [US1] In `.claude/commands/refine.md` Step 7 routing table: add a new row `| \`codebase\` | codebase | codebases.md (if present), identity.md |` above the generalist row, and remove `codebase` from the generalist row's item type list
- [x] T003 [US1] Verify the generalist row in `.claude/commands/refine.md` now lists only `\`stakeholder\`, \`task\`, \`mom\`, \`other\`, unrecognised` — confirm `codebase` and `responsibility` are absent from it

**Checkpoint**: US1 complete — codebase items no longer fall to the generalist

---

## Phase 3: User Story 2 — Responsibility Specialist (Priority: P2)

**Goal**: `responsibility` items are routed to a dedicated specialist that loads only `responsibilities.md` + `identity.md`, not the full distilled context.

**Independent Test**: Run `/refine` with a batch containing only `responsibility` items. Verify the responsibility specialist is invoked, `responsibilities.md` and `identity.md` are the only context files loaded, and the generalist is not invoked.

- [x] T004 [US2] In `.claude/commands/refine.md` Step 7 routing table: add a new row `| \`responsibility\` | responsibility | responsibilities.md (if present), identity.md |` between the `codebase` row and the generalist row

**Checkpoint**: US2 complete — responsibility items no longer fall to the generalist

---

## Phase 4: User Story 3 — Mixed Batch Validation (Priority: P3)

**Goal**: Confirm the five-specialist + generalist routing works correctly for a mixed batch and produces a coherent merged output.

**Independent Test**: Run `/refine` with a batch spanning `requirement`, `interface`, `decision`, `codebase`, `responsibility`, and one `other` item. Verify six invocations occur (five specialists + one generalist), results merge into a single session output, and format is consistent with Feature 003 sessions.

- [x] T005 [US3] Re-read the complete Step 7 section of `.claude/commands/refine.md` and confirm: (a) all five specialist rows are present and correct, (b) the generalist row lists only `stakeholder`, `task`, `mom`, `other`, and unrecognised types, (c) the "Multiple clusters may be invoked concurrently" statement still applies, and (d) the merge step is unmodified
- [x] T006 [US3] If any inline comments in Step 7 reference "at least requirements, interfaces, decisions" as the full specialist list, update them to reflect the expanded five-specialist roster

**Checkpoint**: All three user stories complete — routing table is fully updated and validated

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Ensure documentation accurately reflects the new state.

- [x] T007 Check whether `domain/distilled/decisions.md` contains ADR-015 (the type-routing rules ADR referenced in the spec and backlog item). If ADR-015 exists and its "Status" or "Consequences" section references the Feature 003 three-specialist list as exhaustive, append a note that Feature 006 extends the roster to five specialists
- [x] T008 Verify `CLAUDE.md` Recent Changes section is up to date (the `update-agent-context.sh` script ran during `/speckit.plan` — confirm the entry reflects this feature accurately)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (US1)**: Depends on Phase 1 (T001 must confirm current state before editing)
- **Phase 3 (US2)**: Depends on Phase 2 (T003 must confirm codebase row is correct before adding responsibility row)
- **Phase 4 (US3)**: Depends on Phases 2 and 3 (both rows must be in place before validation)
- **Phase 5 (Polish)**: Depends on Phase 4

### User Story Dependencies

- **US1 (P1)**: Depends only on Setup — no dependency on US2 or US3
- **US2 (P2)**: Depends on US1 being applied (same file, sequential edit)
- **US3 (P3)**: Depends on both US1 and US2 being applied

### Parallel Opportunities

None — all implementation tasks touch the same file (`.claude/commands/refine.md`) and must be applied sequentially to avoid edit conflicts.

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: US1 (T002–T003)
3. **STOP and VALIDATE**: Run `/refine` with `codebase` items only — confirm specialist routing
4. If validated, proceed to US2

### Full Delivery (All Stories)

1. T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008
2. Each task is a targeted read or edit — total estimated changes: ~3 lines modified in `refine.md`

---

## Notes

- The entire implementation is ≤5 lines changed in `.claude/commands/refine.md`
- No new files are created; no other command files are touched
- The specialist instruction block (`SUBAGENT INSTRUCTIONS — REFINE AGENT`) is reused verbatim — no edits needed
- Validation (US3) is a read-and-confirm task, not a live `/refine` run — live testing is optional but recommended
