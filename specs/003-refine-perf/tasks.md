# Tasks: Refine Pipeline Performance Improvements

**Input**: Design documents from `/specs/003-refine-perf/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Not requested. No test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.
All source changes are instruction-text edits to three command files:
`.claude/commands/refine.md` (US1, US2), `.claude/commands/capture.md` (US3), `.claude/commands/seed.md` (US3).

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Confirm the baseline state of all three command files before making changes.

- [x] T001 Read `.claude/commands/refine.md`, `.claude/commands/capture.md`, and `.claude/commands/seed.md` in full and confirm each file's step structure matches the contracts in `specs/003-refine-perf/contracts/` before any edits begin

---

## Phase 2: User Story 1 — Fast Batch Processing via Host Pre-Filtering (Priority: P1) 🎯 MVP

**Goal**: The host eliminates exact duplicates and high-confidence out-of-scope items from the
raw batch before invoking any subagent, reducing every subagent batch size.

**Independent Test**: Create one raw item whose body is an exact copy of an existing distilled
entry and one raw item whose content matches an Out-of-scope term. Run `/refine`. Verify both
items appear in the `### Pre-filtered (host)` changelog subsection and were never passed to the
subagent. See quickstart.md §"Verify P1".

### Implementation for User Story 1

- [x] T002 [US1] Add Step 6.5 exact-duplicate detection block to `.claude/commands/refine.md` immediately after the Step 6 heading — for each raw item, compare whitespace-normalised body against all loaded distilled file content; items with an exact body match are set to status `refined`, recorded as `PreFilterResult { filter_reason: "duplicate", matched_file }`, and removed from the batch (per `contracts/refine-flow.md` Step 6.5)
- [x] T003 [US1] Add out-of-scope pre-filter check to Step 6.5 in `.claude/commands/refine.md` — for each remaining item, evaluate title+body against the Out-of-scope list from identity.md using high-confidence semantic judgment (same bar as the existing `out_of_scope` autonomous action); matching items are set to status `refined`, recorded as `PreFilterResult { filter_reason: "out_of_scope", matched_term }`, and removed from the batch; if the batch is empty after both checks, skip Steps 7–10 and go to Step 11 with an explanatory note
- [x] T004 [US1] Update Step 12 (changelog) in `.claude/commands/refine.md` — add a `### Pre-filtered (host)` subsection before `### Autonomous actions` that lists each PreFilterResult as `- [duplicate]: <item_id> → exact match in <distilled_file>` or `- [out_of_scope]: <item_id> → matched term "<term>"`; omit the subsection if no items were pre-filtered
- [x] T005 [US1] Update Step 13 (session summary) in `.claude/commands/refine.md` — add `✓ Pre-filtered <n> duplicates (host)` and `✓ Pre-filtered <n> out-of-scope (host)` lines under the Autonomous section of the summary template

**Checkpoint**: Run `/refine` with a batch containing a duplicate and an out-of-scope item. Confirm both are filtered before subagent invocation and logged in the changelog.

---

## Phase 3: User Story 2 — Specialist Subagents Per Item-Type Cluster (Priority: P2)

**Goal**: After pre-filtering, the host routes items to type-cluster-specific subagents (requirements,
interfaces, decisions, generalist), each receiving only the relevant distilled context. Plans from
all specialists are merged before execution.

**Independent Test**: Populate the raw queue with one item each of type `requirement`, `interface`,
`decision`, and `task`. Run `/refine`. Verify each item lands in its correct distilled file and
the session completes without errors. See quickstart.md §"Verify P2".

**Dependency**: Requires US1 (Phase 2) complete — Step 7 consumes the reduced batch produced by Step 6.5.

### Implementation for User Story 2

- [x] T006 [US2] Modify Step 7 in `.claude/commands/refine.md` — replace the current "pass full batch to single Agent call" instruction with a two-part grouping instruction: (1) assign each item to a TypeClusterBatch using the type routing table from `specs/003-refine-perf/data-model.md` (requirement→requirements, interface→interfaces, decision→decisions, all others→generalist); (2) determine context files per cluster: requirements cluster loads requirements.md + decisions.md + identity.md; interfaces cluster loads interfaces.md + decisions.md + identity.md; decisions cluster loads decisions.md + identity.md; generalist cluster loads all distilled files + identity.md
- [x] T007 [US2] Add specialist invocation instructions to Step 7 in `.claude/commands/refine.md` — for each non-empty TypeClusterBatch, invoke the refine subagent (Agent tool, subagent_type=general) with that cluster's items and its designated context files only; state that multiple clusters may be invoked concurrently; preserve the existing SUBAGENT INSTRUCTIONS — REFINE AGENT block unchanged (all specialists use the same instructions and output format)
- [x] T008 [US2] Update Step 8 in `.claude/commands/refine.md` — change "Parse the AUTONOMOUS_ACTIONS and GOVERNED_DECISIONS lists returned by the subagent" to "Collect the REFINE_PLAN from each specialist invocation. Concatenate all AUTONOMOUS_ACTIONS lists into one merged list and all GOVERNED_DECISIONS lists into one merged list. Proceed with the merged lists as the single plan for Steps 9 and 10."

**Checkpoint**: Run `/refine` with items of types `requirement`, `interface`, `decision`, and `task`. Verify correct distilled-file routing and no cross-contamination between clusters.

---

## Phase 4: User Story 3 — Improved Type Inference at Capture and Seed Time (Priority: P3)

**Goal**: `/capture` and `/seed` assign specific types using signal-table inference before falling back to
description comparison. `other` becomes a last resort rather than a first resort.

**Independent Test**: Capture items containing "MUST", an API description, and an architectural
rationale — each should be typed silently without prompting. Seed a Markdown document and verify
fewer than 20% of items are typed `other`. See quickstart.md §"Verify P3".

**Dependency**: None — fully independent of US1 and US2 (different files).

### Implementation for User Story 3

- [x] T009 [P] [US3] Rewrite Step 5 in `.claude/commands/capture.md` — restructure into three labelled phases: Phase 1 (Signal Scan): scan title+body for the eight high-confidence signal rows from `specs/003-refine-perf/data-model.md` §"Type Inference Signal Table"; if a signal fires, assign that type silently and proceed; Phase 2 (Description/Example Comparison): if no signal fires, compare body+title against each type's description and example in types.yaml — assign silently if a clear winner emerges, or present the existing ambiguity prompt only if two or more types remain equally plausible after comparison; Phase 3 (other Assignment): assign `other` silently only after both phases fail to resolve the type AND the user has responded "other" or equivalent — explicitly state that `other` MUST NOT be assigned as a first resort
- [x] T010 [P] [US3] Add Phase 1 signal scan inline to Step 7 type-assignment instruction in `.claude/commands/seed.md` — insert the eight-row signal table from `specs/003-refine-perf/data-model.md` §"Type Inference Signal Table" immediately before the existing type inference reference comment; add Phase 2 fallback instruction (compare against types.yaml descriptions; assign clear winner silently); add Phase 3 rule: assign `other` silently if neither phase resolves the type — explicitly state the seed command NEVER asks the user for type at any stage

**Checkpoint**: Run the P3a and P3b verification scenarios from quickstart.md. Confirm no "Type is ambiguous" prompt for items with clear signals, and confirm `other` rate drops from baseline after seeding the same source.

---

## Phase 5: Polish & Verification

**Purpose**: End-to-end validation of all three improvements and spec-level success criteria.

- [ ] T011 [P] Run the "Verify P1" scenario from `specs/003-refine-perf/quickstart.md` — create an exact-duplicate raw item and an out-of-scope raw item, run `/refine`, confirm both are pre-filtered by the host and appear in the changelog `### Pre-filtered (host)` subsection
- [ ] T012 [P] Run the "Verify P2" scenario from `specs/003-refine-perf/quickstart.md` — run `/refine` with a mixed-type batch and verify each item routes to its correct distilled file
- [ ] T013 [P] Run the "Verify P3a" scenario from `specs/003-refine-perf/quickstart.md` — run `/capture` with three items containing MUST-constraint, API-description, and rationale bodies; confirm all three are typed silently without the ambiguity prompt
- [ ] T014 [P] Run the "Verify SC-005" scenario from `specs/003-refine-perf/quickstart.md` — create a batch of specific-typed items with no `other` items; run `/refine`; confirm only type-specific context files are loaded (no generalist full-load)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **US1 (Phase 2)**: Depends on Phase 1 completion
- **US2 (Phase 3)**: Depends on US1 completion (both modify `refine.md`; Step 7 consumes Step 6.5 output)
- **US3 (Phase 4)**: Depends on Phase 1 only — fully independent of US1 and US2 (different files)
- **Polish (Phase 5)**: Depends on all story phases complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 1. No story dependencies.
- **US2 (P2)**: Can start after US1 is complete. Must be done sequentially with US1 (both edit `refine.md`).
- **US3 (P3)**: Can start after Phase 1 in parallel with US1/US2. Edits only `capture.md` and `seed.md`.

### Within Each User Story

- US1: T002 → T003 → T004 → T005 (all sequential; same file, same new step)
- US2: T006 → T007 → T008 (all sequential; build on each other in Step 7)
- US3: T009 ‖ T010 (parallel — different files)

### Parallel Opportunities

- US3 (Phase 4) can run entirely in parallel with US1+US2 (Phases 2–3)
- Within US3: T009 and T010 can run in parallel
- All Polish tasks (T011–T014) can run in parallel

---

## Parallel Execution Example: US3

```text
# US3 can start as soon as Phase 1 (T001) is complete,
# even while US1 and US2 are still in progress:

Parallel track A (US1+US2):  T002 → T003 → T004 → T005 → T006 → T007 → T008
Parallel track B (US3):      T009 ‖ T010
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: US1 — Host Pre-Filtering (T002–T005)
3. **STOP and VALIDATE**: Run T011 (P1 quickstart verification)
4. Every subsequent `/refine` session benefits immediately from smaller subagent batches

### Incremental Delivery

1. Phase 1 → US1 (T001–T005) → Validate → subagent batches shrink immediately
2. US2 (T006–T008) → Validate → governed-decision rate drops per SC-003
3. US3 (T009–T010) → Validate → `other`-type rate drops per SC-004
4. Polish (T011–T014) → Full SC-005 validation

### Parallel Delivery (two tracks)

```text
Track A: T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008
Track B:         ↳ (after T001) → T009 ‖ T010
Join: T011 → T012 → T013 → T014
```

---

## Notes

- All tasks are instruction-text edits to existing `.claude/commands/` files — no code to compile or build
- The signal table and type routing table are defined in `specs/003-refine-perf/data-model.md` — copy them verbatim into the command files rather than summarising
- [P] tasks operate on different files — safe to run concurrently
- Commit after each story phase completes (after T005, T008, T010)
- Verify each story checkpoint before advancing to the next phase
