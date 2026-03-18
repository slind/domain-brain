# Tasks: Explicit Subagents — Move to Separate Files

**Input**: Design documents from `/specs/001-explicit-subagents/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks grouped by user story. US1 → US2 → US3 are sequential (each builds on the previous file state).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

All paths are relative to repo root `.` — no `src/` or `backend/` structure. Changed files:
- `.claude/agents/refine-subagent.md` (new)
- `.claude/commands/refine.md` (modified)

---

## Phase 1: Setup

**Purpose**: Create the agents directory that will hold all subagent instruction files.

- [x] T001 Create `.claude/agents/` directory (run: `mkdir -p .claude/agents`)

**Checkpoint**: `.claude/agents/` directory exists — subagent file can now be written.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No additional foundational infrastructure required beyond Phase 1. `.claude/agents/` is the only prerequisite for all user story phases.

**⚠️ CRITICAL**: T001 must be complete before any user story task begins.

---

## Phase 3: User Story 1 — Create Subagent File With Content (Priority: P1) 🎯 MVP

**Goal**: Create `.claude/agents/refine-subagent.md` containing the verbatim subagent instruction text. After this phase a maintainer can read and edit subagent instructions without opening `refine.md`.

**Independent Test**: Open `.claude/agents/refine-subagent.md` and confirm it contains the full "You are a refine subagent…" instruction block. Open `.claude/commands/refine.md` and confirm it is unmodified (still contains the inline block — this file is not changed until Phase 5).

### Implementation for User Story 1

- [x] T002 [US1] Read `.claude/commands/refine.md` to locate the `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block — identify start line ("### SUBAGENT INSTRUCTIONS") and end line (last line of the block before the next `---` separator)
- [x] T003 [US1] Create `.claude/agents/refine-subagent.md` with the verbatim body of the extracted block (everything from "You are a refine subagent…" to the end of the block, preserving all Markdown and code fences exactly — no rewording, no additions per data-model.md invariant)

**Checkpoint**: `.claude/agents/refine-subagent.md` exists and contains the complete subagent instruction text. US1 independently testable.

---

## Phase 4: User Story 2 — Add Discoverable Prose Header (Priority: P2)

**Goal**: Prepend the required opening header to `.claude/agents/refine-subagent.md` so the file is self-describing. After this phase a maintainer can list `.claude/agents/` and read any file to immediately understand its role.

**Independent Test**: Read `.claude/agents/refine-subagent.md` — confirm the first lines are the prose header identifying the invoking command, item types, and output contract (no YAML frontmatter). List `.claude/agents/` — confirm `refine-subagent.md` is visible.

### Implementation for User Story 2

- [x] T004 [US2] Prepend the plain Markdown prose header to `.claude/agents/refine-subagent.md` (edit file to insert at line 1, before the instruction body):
  ```markdown
  # Refine Subagent

  **Invoked by**: `/refine` (Step 7 — specialist subagent invocation)
  **Processes**: All item types — requirements, interfaces, decisions, codebase, responsibility, and generalist cluster items
  **Output contract**: REFINE_PLAN with AUTONOMOUS_ACTIONS and GOVERNED_DECISIONS sections (JSON-like structure)

  ---

  ```

**Checkpoint**: `.claude/agents/refine-subagent.md` has prose header at top, instruction body follows. SC-003 satisfied. US2 independently testable.

---

## Phase 5: User Story 3 — Update Host Command to Reference File (Priority: P3)

**Goal**: Update `.claude/commands/refine.md` so it loads the subagent file at session start, passes the loaded text to the Agent tool invocation, and no longer embeds the inline instruction block. After this phase `/refine` uses the external file exclusively.

**Independent Test**: Grep `refine.md` for `SUBAGENT INSTRUCTIONS` — no matches (SC-001). Run `/refine` against a small batch — output identical to pre-change baseline (SC-002). Edit a word in `.claude/agents/refine-subagent.md` — re-run `/refine` — changed text appears in agent behaviour (SC-004).

### Implementation for User Story 3

- [x] T005 [US3] Edit `.claude/commands/refine.md` — in Step 3 (Load distilled context), after the existing `config/similarity.md` loading paragraph, insert the following paragraph:
  ```
  Additionally, read `.claude/agents/refine-subagent.md` and store its contents as
  `subagent_instructions`. If the file is absent or unreadable, output:
    Error: Subagent instruction file not found: .claude/agents/refine-subagent.md
    Ensure the file exists before running /refine.
  Then stop.
  ```
- [x] T006 [US3] Edit `.claude/commands/refine.md` — in Step 7 specialist invocation bullet list, replace:
  `- The full SUBAGENT INSTRUCTIONS — REFINE AGENT block below`
  with:
  `- The subagent instruction text loaded from `.claude/agents/refine-subagent.md` in Step 3 (variable: subagent_instructions)`
- [x] T007 [US3] Edit `.claude/commands/refine.md` — delete the entire `### SUBAGENT INSTRUCTIONS — REFINE AGENT` section and all content under it through the end of the file (the section begins with `### SUBAGENT INSTRUCTIONS — REFINE AGENT` and runs to the end of `refine.md`)

**Checkpoint**: `refine.md` contains no inline subagent block. `.claude/agents/refine-subagent.md` is the single source of truth. All four success criteria met. US3 independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verify all success criteria and update knowledge artefacts.

- [x] T008 [P] Verify SC-001 — grep `.claude/commands/refine.md` for `SUBAGENT INSTRUCTIONS` and confirm zero matches
- [x] T009 [P] Verify SC-003 — list `.claude/agents/` and confirm `refine-subagent.md` is present
- [x] T010 Update `domain/distilled/backlog.md` — mark "Move subagents to separate files for maintainability" as done with rationale "Implemented in feature 001-explicit-subagents"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: No tasks — Phase 1 is sufficient
- **User Story 1 (Phase 3)**: Depends on T001 (directory exists)
- **User Story 2 (Phase 4)**: Depends on T003 (file exists to prepend header to)
- **User Story 3 (Phase 5)**: Depends on T004 (file fully formed before wiring up host)
- **Polish (Phase 6)**: T008, T009 depend on T007; T010 is independent

### User Story Dependencies

- **US1 (P1)**: Unblocked after T001
- **US2 (P2)**: Depends on US1 complete (T003)
- **US3 (P3)**: Depends on US2 complete (T004) — wire up only once file is fully formed

### Within Each User Story

- T002 must precede T003 (read before write)
- T005, T006 can run in parallel (edit different paragraphs of `refine.md`)
- T007 must follow T006 (don't remove block before updating the reference)

### Parallel Opportunities

- T005 and T006 (both edit `refine.md` but at different locations — take care with sequencing if using automated tools)
- T008 and T009 (independent verification checks)

---

## Parallel Example: User Story 3

```
# T005 and T006 can be prepared together (different edit targets):
Task: "Add subagent_instructions load to Step 3 in .claude/commands/refine.md"
Task: "Update Step 7 Agent tool invocation reference in .claude/commands/refine.md"

# THEN:
Task: "Delete ### SUBAGENT INSTRUCTIONS section from .claude/commands/refine.md" (T007)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 3: US1 (T002–T003)
3. **STOP and VALIDATE**: `.claude/agents/refine-subagent.md` exists with full content — maintainer can now edit subagents independently (even though `/refine` still uses inline block)
4. Continue to Phase 4 and 5 to fully wire up the feature

### Incremental Delivery

1. T001 → Foundation ready
2. T002–T003 → US1 done: subagent file exists
3. T004 → US2 done: file is discoverable and self-describing
4. T005–T007 → US3 done: host wired up, inline block removed
5. T008–T010 → Polish: verified and backlog updated

---

## Notes

- T007 (delete inline block) is the highest-risk task — verify T005 and T006 are applied first or the session will lose the instruction text
- The content of `.claude/agents/refine-subagent.md` MUST be byte-for-byte identical to the extracted block — no rewording (data-model.md invariant)
- Commit after T004 (before touching `refine.md`) as a safe restore point
- `/refine` behaviour must be indistinguishable from the baseline after T007 (SC-002)
