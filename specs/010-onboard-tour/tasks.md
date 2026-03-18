# Tasks: Domain README — Consolidate Command

**Input**: Design documents from `/specs/010-onboard-tour/`
**Prerequisites**: plan.md ✓ spec.md ✓ research.md ✓ data-model.md ✓ contracts/ ✓

**Tests**: Not explicitly requested. Manual verification using quickstart.md scenarios.

**Organization**: The sole deliverable is `.claude/commands/consolidate.md` — a single Markdown command file. Tasks are organized by user story to enable incremental composition of the command.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different concerns, no dependencies on incomplete tasks)
- **[Story]**: User story this task delivers ([US1], [US2], [US3])

## Path Conventions

All paths relative to repository root:
- Command file: `.claude/commands/consolidate.md`
- Output file: `domain/README.md`
- Domain brain updates: `domain/distilled/interfaces.md`, `domain/distilled/backlog.md`

---

## Phase 1: Setup

**Purpose**: Establish conventions and scaffolding before writing command content

- [x] T001 Review existing command files (`.claude/commands/refine.md`, `.claude/commands/consistency-check.md`) to confirm header format, domain-discovery boilerplate, and step-numbering conventions to reuse in `.claude/commands/consolidate.md`
- [x] T002 Create `.claude/commands/consolidate.md` with the command header block: `description`, `handoffs` frontmatter (handoff to `/refine` after updating knowledge), and the command title section

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure shared by all user stories — domain discovery and identity validation

**⚠️ CRITICAL**: All user story phases depend on these two steps being correctly implemented

- [x] T003 Implement Step 1 (Domain Root Discovery) in `.claude/commands/consolidate.md`: three-level discovery (`--domain` flag → `.domain-brain-root` file → `domain/` directory), with error output if all three fail
- [x] T004 Implement Step 2 (Identity Validation) in `.claude/commands/consolidate.md`: read `config/identity.md`; if absent, output "Domain identity not found. Run /frame first." and stop; if present, parse `domain` name, `**One-line**:`, `**Pitch**:`, and `steward` fields for use in the README

**Checkpoint**: Domain discovery and identity loading work correctly — command can locate the domain root and validates the identity precondition

---

## Phase 3: User Story 1 — Steward Generates Domain README (Priority: P1) 🎯 MVP

**Goal**: Running `/consolidate` creates or overwrites `domain/README.md` with four complete sections and a changelog entry

**Independent Test**: Run `/consolidate` in a populated domain brain → verify `domain/README.md` is created with Domain Summary, Exposed Interfaces, Intended Usage, and Top Priorities sections (quickstart.md Scenario A)

### Implementation for User Story 1

- [x] T005 [P] [US1] Implement Step 3 (Interfaces Loading) in `.claude/commands/consolidate.md`: read `distilled/interfaces.md`; if absent, set interfaces list to "No interfaces defined yet."; if present, extract all `## ` heading titles as the interface list
- [x] T006 [P] [US1] Implement Step 4 (Backlog Loading and Priority Selection) in `.claude/commands/consolidate.md`: read `distilled/backlog.md`; if absent, set priorities list to "No open items."; if present, collect all entries where `**Status**:` is `open` or `in-progress`, sort high → in-progress → medium → low, cap at 5 items, extract title and first sentence of body (truncated at 120 chars) per item
- [x] T007 [US1] Implement Step 5 (README Composition) in `.claude/commands/consolidate.md` (depends on T004, T005, T006): build the full `domain/README.md` content in memory with the five sections — Domain Summary (from identity), Exposed Interfaces (from T005), Intended Usage (static prose describing /frame → /capture or /seed → /refine → /query), Top Priorities (from T006), and footer line "Generated: YYYY-MM-DD by /consolidate"
- [x] T008 [US1] Implement Step 6 (README Write) in `.claude/commands/consolidate.md`: write the composed content to `domain/README.md` using the Write tool (creates if absent, overwrites if present); record whether the file existed before the write (`created` vs `updated`)
- [x] T009 [US1] Implement Step 7 (Changelog Append) in `.claude/commands/consolidate.md`: append a Consolidate Session entry to `distilled/changelog.md` (create changelog if absent) with the run date, action (`created`/`updated`), interface count, and priorities count
- [x] T010 [US1] Implement Step 8 (Terminal Confirmation Output) in `.claude/commands/consolidate.md`: output the success summary block showing domain name, interface count, priorities count, and README path; matches the contract in `contracts/consolidate-command.md`

**Checkpoint**: User Story 1 fully functional — run `/consolidate` and verify `domain/README.md` is created with all four sections and a changelog entry appended (quickstart.md Scenario A)

---

## Phase 4: User Story 2 — New Team Member Reads the README (Priority: P2)

**Goal**: The generated README is human-readable in any standard Markdown renderer without AI tooling

**Independent Test**: Open the generated `domain/README.md` in a GitHub/GitLab Markdown preview → all five sections render correctly with no raw YAML, no broken tables, and interface/priority items clearly listed (quickstart.md Scenario A + B)

### Implementation for User Story 2

- [x] T011 [US2] Validate Exposed Interfaces formatting in `.claude/commands/consolidate.md` Step 5: ensure each interface title is rendered as a bulleted list item (`- Interface Title`) so it reads as a clean list in any Markdown renderer, not as a raw heading
- [x] T012 [US2] Validate Top Priorities formatting in `.claude/commands/consolidate.md` Step 5: ensure each priority item is rendered as a numbered list with title in bold and description on the next line — e.g., `1. **Title** — one-line description` — readable without AI context
- [x] T013 [US2] Write the Intended Usage static prose in `.claude/commands/consolidate.md` Step 5: paragraph describing what Domain Brain is and one-line descriptions of `/frame`, `/capture`/`/seed`, `/refine`, and `/query`; prose must be accurate and readable as standalone text without requiring domain knowledge

**Checkpoint**: Open `domain/README.md` in a Markdown renderer (without AI) → a newcomer can identify the domain purpose, at least one interface, and the top priority from the README alone (quickstart.md Scenario A)

---

## Phase 5: User Story 3 — README Stays Current After Domain Changes (Priority: P3)

**Goal**: Re-running `/consolidate` after any domain change produces an accurate, non-duplicated README

**Independent Test**: Run `/consolidate` twice in succession → README content is identical to a single run, with no duplicated sections; then close a backlog item and re-run → the closed item does not appear in Top Priorities (quickstart.md Scenarios B and E)

### Implementation for User Story 3

- [x] T014 [US3] Verify the Write tool in Step 6 uses full overwrite (not append): confirm that running `/consolidate` twice produces the exact same `domain/README.md` content without any accumulated duplication (quickstart.md Scenario B)
- [x] T015 [US3] Verify edge case handling for missing optional files in `.claude/commands/consolidate.md`: run `/consolidate` in a domain where `distilled/interfaces.md` does not exist and confirm the README is still created without error (quickstart.md Scenario D)
- [x] T016 [US3] Verify changelog does not duplicate session entries: confirm each run appends exactly one new entry to `distilled/changelog.md` regardless of how many times the command is run (quickstart.md Scenario E)

**Checkpoint**: All three user stories independently functional — run the full quickstart.md acceptance checklist

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Domain brain self-maintenance — record the new command in the domain brain's own knowledge base

- [x] T017 [P] Add `/consolidate` interface contract entry to `domain/distilled/interfaces.md`: distilled entry describing the command's invocation, inputs, outputs, and edge cases — consistent with the existing interface contract format in that file
- [x] T018 [P] Update `domain/distilled/backlog.md`: mark "Onboarding and Introduction for New Users" as done with rationale "implemented as domain/README.md generated by /consolidate command (feature 010)"
- [x] T019 Run the full quickstart.md acceptance checklist and check all 11 items; document any deviations found
- [x] T020 Update `domain/distilled/changelog.md` with a triage session entry recording the close of the backlog item (T018)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational — core command implementation
- **User Story 2 (Phase 4)**: Depends on US1 (T007 composition step) — formatting refinements
- **User Story 3 (Phase 5)**: Depends on US1 (T008 write step) — overwrite/idempotency verification
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: Only depends on Foundational — implement first
- **US2 (P2)**: Depends on US1 T007 (composition) being complete — refines output formatting
- **US3 (P3)**: Depends on US1 T008 (write) being complete — verifies overwrite behaviour
- **US2 and US3** can proceed in parallel once US1 is complete

### Within Phases

- T005 and T006 (Phase 3) can run in parallel — independent concerns (interfaces vs. backlog)
- T011, T012, T013 (Phase 4) can run in parallel — each concerns a different README section
- T017 and T018 (Phase 6) can run in parallel — different files

---

## Parallel Example: User Story 1

```
# Phase 3 parallel tasks (once Foundational is done):
T005: Interfaces loading logic
T006: Backlog loading + priority selection

# Then sequentially:
T007: README composition (depends on T005, T006)
T008: README write
T009: Changelog append
T010: Terminal output
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T004) — CRITICAL
3. Complete Phase 3: User Story 1 (T005–T010)
4. **STOP and VALIDATE**: Run quickstart.md Scenario A — verify README is created with all four sections
5. Demo: open `domain/README.md` in GitHub/GitLab preview

### Incremental Delivery

1. Phase 1 + Phase 2 → Command file exists and validates identity ✓
2. Phase 3 (US1) → Full README generation works end-to-end ✓ (MVP)
3. Phase 4 (US2) → Formatting refined for Markdown readability ✓
4. Phase 5 (US3) → Overwrite/idempotency verified ✓
5. Phase 6 → Domain brain self-updated ✓

### Total Tasks

| Phase | Tasks | Parallelizable |
|---|---|---|
| Setup | T001–T002 | 0 |
| Foundational | T003–T004 | 0 |
| US1 (P1) | T005–T010 | T005, T006 |
| US2 (P2) | T011–T013 | T011, T012, T013 |
| US3 (P3) | T014–T016 | 0 |
| Polish | T017–T020 | T017, T018 |
| **Total** | **20 tasks** | **7 parallelizable** |

---

## Notes

- All tasks write to a single file: `.claude/commands/consolidate.md` — avoid concurrent edits
- Phases 4 and 5 are verification passes, not new code — they may surface needed tweaks to the composition logic in T007
- The Intended Usage prose (T013) is the only creative writing task — draft it once and reuse across re-runs
- Commit after each phase checkpoint for clean rollback points
- Stop at Phase 3 checkpoint to validate MVP before proceeding to Phases 4–5
