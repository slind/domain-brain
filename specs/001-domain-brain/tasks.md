---
description: "Task list for Software Domain Brain"
---

# Tasks: Software Domain Brain

**Input**: Design documents from `/specs/001-domain-brain/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Project type**: Claude AI assistant extension — deliverables are command files (`.claude/commands/*.md`)
and a template domain directory (`domain/`). No compilation or build step.

**Tests**: Manual acceptance testing only — run each command via Claude CLI and verify against
the acceptance scenarios defined in spec.md. No automated test framework required.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- File paths are relative to repository root

---

## Phase 1: Setup

**Purpose**: Create the domain template directory structure that teams copy when initializing a domain brain.

- [X] T001 Create domain/ template directory structure: domain/raw/.gitkeep, domain/distilled/.gitkeep, domain/index/.gitkeep, domain/config/ directory per plan.md Project Structure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Populate the template with default content required by all three commands.

**⚠️ CRITICAL**: All three command phases (US1–US3) depend on the type registry (T002) and
distilled file headers (T003) being present.

- [X] T002 Create domain/config/types.yaml with all 9 default types per data-model.md: responsibility, interface, codebase, requirement, stakeholder, decision, task, mom, other — each with name, description, routes_to, and example fields
- [X] T003 [P] Create domain/distilled/ placeholder files (domain.md, codebases.md, interfaces.md, requirements.md, stakeholders.md, decisions.md, backlog.md, changelog.md) each with a level-1 heading and one-line purpose comment
- [X] T004 [P] Create domain/README.md documenting the initialization steps: copy directory, rename, create .domain-brain-root, run first /capture

**Checkpoint**: Template ready — US1, US2, US3 command phases can now proceed in parallel.

---

## Phase 3: User Story 1 - Capture a Knowledge Item (Priority: P1) 🎯 MVP

**Goal**: Deliver the /capture command so domain experts can intake raw knowledge items in
under 30 seconds with no hand-authored structure.

**Independent Test**: Invoke `/capture Payments owns checkout error handling` and verify
a file appears at `raw/<id>.md` with valid YAML frontmatter containing auto-populated id,
source, domain, captured_at, captured_by, and status: raw.

### Implementation for User Story 1

- [X] T005 [US1] Write .claude/commands/capture.md: YAML frontmatter (description, handoff to /refine), execution prompt covering domain root discovery (--domain arg → .domain-brain-root file → domain/ convention), types.yaml hot-load, type inference from description using type examples, ambiguity confirmation only when confidence is low (FR-006), envelope auto-population (id as <domain>-<YYYYMMDD>-<4hex>, source.tool, source.location, captured_at, captured_by, status: raw), raw item creation at raw/<id>.md with YAML frontmatter + body, missing field validation with error output (FR-004)
- [ ] T006 [US1] Validate /capture against all 3 acceptance scenarios: (1) explicit title+type creates correct raw item, (2) unstructured text infers type and skips confirmation when confident, (3) missing domain field triggers validation error not file creation

**Checkpoint**: User Story 1 complete — /capture independently functional.

---

## Phase 4: User Story 2 - Refine Raw Items Into Distilled Knowledge (Priority: P2)

**Goal**: Deliver the /refine command so domain experts can process their raw queue with
autonomous handling for routine items and a governed decision loop for normative changes.

**Independent Test**: Place 3 raw items in queue — one duplicate, one conflict, one clear routing.
Run `/refine`. Verify: duplicate merged silently, conflict triggers exactly one governed decision,
clear item routed autonomously. Changelog entry appended at session end.

### Implementation for User Story 2

- [X] T007 [US2] Write .claude/commands/refine.md orchestration prompt: YAML frontmatter (description, handoff to /query), queue loading (Glob raw/*.md with status: raw), session announce (count + titles), subagent invocation via Agent tool with batch + distilled context, governed decision loop (one at a time per FR-010, always include "flag as unresolved" per FR-011, accept natural language responses per FR-012), pause/resume on "stop"/"skip" signals (FR-013), host-side distilled file writes (never subagent-direct), changelog append to distilled/changelog.md (FR-014), session summary output
- [X] T008 [P] [US2] Embed refine subagent instructions block within refine.md: autonomous action rules (dedup when content overlap high, summarise+route when type clear, aggregate partial info, classify 'other' when confident, split multi-type items — all silently per FR-008), governed decision output schema (structured JSON-like block with trigger type, options, context), unresolved conflict → open ADR creation (FR-015)
- [ ] T009 [US2] Validate /refine against all 7 acceptance scenarios: duplicate merge, conflict decision, natural language response interpretation, session pause, changelog completeness, partial-overlap merge, multi-type split

**Checkpoint**: User Stories 1 + 2 independently functional.

---

## Phase 5: User Story 3 - Query Domain Knowledge (Priority: P3)

**Goal**: Deliver the /query command so domain experts can ask natural language questions
and receive cited, grounded answers scoped to relevant knowledge files.

**Independent Test**: With a populated distilled base (from US2), run `/query Who owns the
onboarding flow?` and verify: query classified as stakeholder-query, retrieval scoped to
domain.md + stakeholders.md only, answer includes source citations (file + entry title).

### Implementation for User Story 3

- [X] T010 [US3] Write .claude/commands/query.md: YAML frontmatter (description, handoff to /capture for missing knowledge), query classification logic (topic scope → candidate files per FR-017, reasoning mode → one of 5 modes per FR-017 table in contracts/query.md), retrieval strategy selection (small ≤50 entries: Read candidate files; medium 51–500: Grep + Read top-N; per FR-023), chunk cap enforcement with user notification (FR-020), context assembly with source labels [file → entry title] (FR-019), cited answer output, missing knowledge handling (name specific gap + offer /capture per FR-021), open ADR surfacing with ⚠ marker for intersecting topic queries (FR-016)
- [ ] T011 [US3] Validate /query against all 4 acceptance scenarios: stakeholder query returns scoped cited answer, open-ADR query surfaces decisions with attribution, missing knowledge names specific gap and offers capture, chunk cap triggers notification not silent truncation

**Checkpoint**: User Stories 1, 2, and 3 independently functional.

---

## Phase 6: User Story 4 - Process Large Linked Documents (Priority: P4)

**Goal**: Extend /capture with large document chunking and /query with second-stage chunk
retrieval so reference documents become discoverable at chunk granularity.

**Independent Test**: Capture an item linking to a document >~10 pages. Verify chunks appear
at index/<doc-id>/chunks/. Then issue `/query --mode design-proposal <question about the doc>`.
Verify answer cites a specific chunk, not just the summary.

### Implementation for User Story 4

- [X] T012 [US4] Extend .claude/commands/capture.md with large document pipeline: detect document links/paths in capture body, check document size (>~5000 tokens = large), if large: read with pagination (Read tool page ranges for PDF), split at logical boundaries (Markdown H2/H3 headings, paragraph breaks), write chunks to index/<doc-id>/chunks/chunk-NNNN.md with YAML frontmatter (doc-id, chunk-id, source-location), write index/<doc-id>/summary.md (≤500 words), update distilled entry with chunk-ids list (FR-007)
- [X] T013 [P] [US4] Extend .claude/commands/query.md with second-stage retrieval: after initial distilled retrieval, check if reasoning mode is design-proposal; if yes and distilled summary insufficient: Grep index/*/chunks/ for query keywords, load top-N matched chunks into context (FR-022); if mode is diagram or gap-analysis: suppress second-stage retrieval, use summary only
- [ ] T014 [US4] Validate large document pipeline against all 3 acceptance scenarios: chunked document produces summary + chunk-ids in distilled entry, precision query triggers second-stage chunk retrieval, overview query uses summary only

**Checkpoint**: User Stories 1–4 independently functional.

---

## Phase 7: User Story 5 - Track and Discover Open Decisions (Priority: P5)

**Goal**: Verify that open ADRs created during refinement are stored in the correct format
and surface correctly in query results, making ambiguity visible at query time.

**Independent Test**: Flag a conflict as unresolved during `/refine`. Run `/query what
decisions are pending?`. Verify open ADR appears with status, options, and rationale.

### Implementation for User Story 5

- [X] T015 [US5] Verify /refine open ADR creation: confirm refine.md generates open ADR entries in decisions.md matching data-model.md ADR schema (## [OPEN] header, Status: open, Captured, Context, Options list, Flagged by, Pending fields) when human selects "flag as unresolved"
- [X] T016 [US5] Verify /query open ADR discovery: confirm query.md surfaces open ADR entries with ⚠ status marker both for direct decision-recall queries and for topic-intersecting queries where an open ADR is contextually relevant — validate against both US5 acceptance scenarios

**Checkpoint**: All 5 User Stories independently functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Handoff chains, end-to-end validation, and agent context update.

- [X] T017 [P] Add handoff YAML frontmatter to all three command files: capture.md → handoff to /refine ("Ready to process your raw queue"), refine.md → handoff to /query ("Query your distilled knowledge"), query.md → handoff to /capture ("Capture the missing knowledge")
- [ ] T018 Run quickstart.md end-to-end validation: initialize domain/, capture 4 items (one responsibility, one interface, one decision, one other), run /refine (verify autonomous routing + changelog), run /query for each of 5 reasoning modes, confirm all success criteria SC-001–SC-008 are met

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1
- **US1–US3 (Phases 3–5)**: Each depends on Phase 2 — can proceed in parallel once T002–T004 complete
- **US4 (Phase 6)**: Depends on US1 (T005) and US3 (T010) — extends both command files
- **US5 (Phase 7)**: Depends on US2 (T007–T008) and US3 (T010) — verifies cross-command ADR flow
- **Polish (Phase 8)**: Depends on all user story phases

### User Story Dependencies

- **US1 (P1)**: No story dependencies — start after Foundational
- **US2 (P2)**: No story dependencies — start after Foundational
- **US3 (P3)**: No story dependencies — start after Foundational
- **US4 (P4)**: Depends on US1 complete (T005) and US3 complete (T010)
- **US5 (P5)**: Depends on US2 complete (T007–T008) and US3 complete (T010)

### Within Each User Story

- Implementation task first, validation task second
- US2: T008 can run in parallel with T007 (both write to refine.md but are independent sections)

### Parallel Opportunities

```
After T001 completes:
  Parallel: T002, T003, T004

After T002–T004 complete:
  Parallel: T005 (US1), T007 (US2), T010 (US3)
  Also parallel: T008 alongside T007

After T005 and T010 complete:
  Parallel: T012 (extend capture), T013 (extend query)
```

---

## Implementation Strategy

### MVP (User Story 1 only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T004)
3. Complete Phase 3: User Story 1 (T005–T006)
4. **STOP AND VALIDATE**: `/capture` works end-to-end
5. Demonstrate to team before continuing

### Incremental Delivery

1. Setup + Foundational → template ready
2. US1 → `/capture` works → commit + demo
3. US2 → `/refine` works → commit + demo
4. US3 → `/query` works → **full system usable** → commit + demo
5. US4 → large documents → commit + demo
6. US5 → open decisions visible → commit + demo
7. Polish → handoffs + end-to-end validation → final commit

---

## Notes

- All "files" to create are Markdown command prompts, not source code — write complete prompts
- Each command file must be self-contained: assume no shared state between invocations
- [P] tasks write to different files — safe to run in parallel
- Validation tasks (T006, T009, T011, T014, T016) require invoking Claude CLI — manual step
- US4 tasks (T012, T013) modify existing command files — read current content before editing
- T018 (end-to-end) is the acceptance gate for the full system — do not skip
