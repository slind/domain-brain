# Tasks: Domain Identity and Knowledge Seeding

**Input**: Design documents from `/specs/002-domain-identity-seed/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/frame.md, contracts/seed.md, quickstart.md

**Tests**: Not requested — manual acceptance testing per quickstart.md

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Exact file paths included in every task description

---

## Phase 1: Setup

**Purpose**: Establish the new config artefact that all four commands reference.

- [X] T001 Create `domain/config/identity.md` as a template placeholder — YAML frontmatter with empty `domain`, `created`, `steward` fields and a Markdown body with commented-out schema showing all required sections (One-line, Pitch, In scope, Out of scope)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No additional foundational work required — this feature adds Markdown command files only. Phase 1 (T001) is the sole prerequisite. All user story phases may begin after T001 completes.

**Checkpoint**: `domain/config/identity.md` placeholder exists — user story work can begin.

---

## Phase 3: User Story 1 — Frame the Domain Identity (Priority: P1) MVP

**Goal**: Deliver the `/frame` command that creates and updates `config/identity.md`. This is the prerequisite for every other story in this feature.

**Independent Test**: Run `/frame` on a domain with no `config/identity.md`. Verify the file is created with all required sections populated. Re-run `/frame` — verify current values are pre-filled and changes are applied. Verify that `/frame` on a domain with existing seeded raw items prints a stale-classification warning.

### Implementation for User Story 1

- [X] T002 [US1] Create `.claude/commands/frame.md` with command header, description, and Steps 1–3: locate the domain brain root (priority: `--domain` arg → `.domain-brain-root` file → `domain/` directory), parse arguments, and auto-derive `domain` name from directory and `steward` from `git config user.name`
- [X] T003 [US1] Add Steps 4–5 to `.claude/commands/frame.md`: Step 4 detects first-run vs. re-run (checks whether `config/identity.md` exists), presents a pre-filled template with current values on re-run or an empty template on first run, and collects user input for One-line (≤15 words), Pitch (3–5 sentences), In scope (≥1 item), Out of scope (≥1 item); Step 5 validates all four fields and prompts the user to correct any that fail
- [X] T004 [US1] Add Steps 6–7 and Key Rules to `.claude/commands/frame.md`: Step 6 writes `config/identity.md` using the schema from data-model.md (YAML frontmatter: domain, created on first run only, steward; Markdown body: One-line, Pitch, In scope list, Out of scope list); Step 7 scans `raw/*.md` for items with `source.tool: seed` and, if any exist, outputs the stale-classification warning before stopping; Key Rules section summarises field constraints and re-run behaviour

**Checkpoint**: `/frame` is fully functional — run the US1 independent test before proceeding.

---

## Phase 4: User Story 2 — Seed Knowledge from Existing Sources (Priority: P2)

**Goal**: Deliver the `/seed <source>` command that reads existing documents, segments them into atomic knowledge items, classifies each against the domain identity, and writes qualifying items to `raw/`.

**Independent Test**: Prepare a Markdown document with clearly in-scope sections, clearly out-of-scope sections, and ambiguous sections relative to a known `config/identity.md`. Run `/seed path/to/doc.md`. Verify: in-scope sections become standard raw items with `source.tool: seed`; out-of-scope sections are skipped; ambiguous sections produce raw items with `seed-note: Relevance uncertain`. Verify the session summary reports all three counts and that re-running on the same source resumes from the correct offset.

### Implementation for User Story 2

- [X] T005 [US2] Create `.claude/commands/seed.md` with command header, description, and Steps 1–3: Step 1 locates the domain brain root using the same priority order as `/frame`; Step 2 parses arguments (`<source>`, optional `--domain <path>`, optional `--limit N`); Step 3 loads `config/identity.md` — stops with a clear error directing the user to run `/frame` first if the file is absent
- [X] T006 [US2] Add Steps 4–6 to `.claude/commands/seed.md`: Step 4 detects the source type (single `.md` file, single `.pdf` file, URL, or directory) and enumerates files (for directories: Glob all `.md` and `.pdf` files; skip and log any other formats with an export instruction); Step 5 calculates the resume offset by counting existing `raw/*.md` items whose `source.location` matches the current source; Step 6 segments each source at logical boundaries (Markdown: split at `##` headings, fall back to `###` or paragraph breaks for long sections; PDF: split at detected headings or page boundaries; URL: fetch with WebFetch, split by heading structure), merging or discarding segments that do not contain at least one complete standalone knowledge claim
- [X] T007 [US2] Add Steps 7–9 and Key Rules to `.claude/commands/seed.md`: Step 7 classifies each segment against the identity using semantic judgment (in-scope → raw item, out-of-scope → skip with log, ambiguous → raw item with `seed-note: Relevance uncertain`); Step 8 writes each qualifying raw item to `raw/<id>.md` using the seeded raw item schema from data-model.md (`source.tool: seed`, `source.location`, title from nearest heading or inferred ≤10-word title, `seed-note` when uncertain), enforces the 100-item cap (or `--limit N`), and stops with a cap-reached message and remaining-segment count when the cap is hit; Step 9 outputs the session summary (created / skipped / flagged / unreadable counts, cap message if applicable); Key Rules section covers cap behaviour, URL failure handling (log and continue), empty out-of-scope list (all segments treated as ambiguous, warn user), and unsupported format handling

**Checkpoint**: `/seed` is fully functional — run the US2 independent test before proceeding.

---

## Phase 5: User Story 3 — Refine Seeded Items with Scope Awareness (Priority: P3)

**Goal**: Enhance `/refine` so that seeded items are processed with domain identity context: clearly out-of-scope items are archived autonomously; items flagged as uncertain are surfaced as governed decisions with a "not relevant — archive" option.

**Independent Test**: After seeding a mixed document, run `/refine`. Verify: items matching the "Out of scope" list are archived with a changelog entry and no decision prompt; items with `seed-note: Relevance uncertain` produce governed decisions that include the archive option; in-scope items without a seed-note are processed identically to manually captured items.

### Implementation for User Story 3

- [X] T008 [US3] Edit `.claude/commands/refine.md` Step 6 (Load distilled context) to also read `config/identity.md` if it exists — pass the identity content to the subagent alongside the distilled files so the subagent can reason about domain scope
- [X] T009 [US3] Edit the SUBAGENT INSTRUCTIONS section of `.claude/commands/refine.md` to add `out_of_scope` to the autonomous action types table: when a raw item's content clearly aligns with a term on the "Out of scope" list in `config/identity.md` with high confidence, classify as `out_of_scope`, archive the item, and record the matched out-of-scope term and archive outcome in the session changelog — no governed decision is presented
- [X] T010 [US3] Edit the SUBAGENT INSTRUCTIONS section of `.claude/commands/refine.md` to add `seed_relevance_uncertain` to the governed decision trigger types table: triggered when a raw item has `seed-note: Relevance uncertain` in frontmatter; the decision MUST include both standard type-routing options AND a "not relevant — archive" option labelled "Archive — out of scope for this domain"; outcome recorded in changelog

**Checkpoint**: `/refine` correctly handles seeded items — run the US3 independent test before proceeding.

---

## Phase 6: User Story 4 — Query with Domain Context (Priority: P4)

**Goal**: Enhance `/query` to read `config/identity.md` as the first context element and prefix every response with a one-line domain framing statement when the identity exists.

**Independent Test**: With a complete `config/identity.md`, run any `/query`. Verify the response begins with a domain framing line derived from the identity's One-line field. Delete `config/identity.md` and run the same query — verify it proceeds without error and without a framing line.

### Implementation for User Story 4

- [X] T011 [P] [US4] Edit `.claude/commands/query.md` to add Step 2.5 immediately after argument parsing: attempt to read `config/identity.md`; if it exists, store its One-line field as `domain_framing`; if it does not exist, set `domain_framing` to null and continue silently — no error, no warning
- [X] T012 [US4] Edit `.claude/commands/query.md` Step 9 (Compose and output the answer) Header section to prepend `Domain: <domain> — <one-line>` before the `Query mode:` line when `domain_framing` is non-null; leave the header unchanged when `domain_framing` is null

**Checkpoint**: `/query` framing works — run the US4 independent test before proceeding.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation update and end-to-end validation across all user stories.

- [X] T013 [P] Update `domain/README.md` to add `/frame` as the first step in the domain brain initialisation instructions, positioned before any `/capture` or `/seed` invocations, with a brief explanation that the identity is required before seeding
- [ ] T014 End-to-end validation — work through all four acceptance scenarios in `specs/002-domain-identity-seed/quickstart.md` and verify every item in the verification checklist passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: N/A — skipped; T001 in Phase 1 is the only prerequisite
- **US1 (Phase 3)**: Depends on T001
- **US2 (Phase 4)**: Depends on Phase 3 completion (the `/seed` command itself requires `/frame` to have been run by the user before use; the implementation of `/seed` can reference the schema established in US1)
- **US3 (Phase 5)**: Depends on Phase 3 (identity schema must be defined before refine can reference it); can proceed independently of Phase 4
- **US4 (Phase 6)**: Depends on Phase 3 only (reads identity.md); can proceed in parallel with Phases 4 and 5
- **Polish (Phase 7)**: Depends on all story phases complete

### User Story Dependencies

- **US1 (P1)**: Can start after T001 — no story dependencies
- **US2 (P2)**: Should start after US1 is complete (the seeded raw item schema references the identity schema defined in US1)
- **US3 (P3)**: Can start after US1 is complete — independent of US2 implementation
- **US4 (P4)**: Can start after US1 is complete — independent of US2 and US3

### Within Each User Story

- US1: T002 → T003 → T004 (sequential — each task extends the same file)
- US2: T005 → T006 → T007 (sequential — each task extends the same file)
- US3: T008 → T009 → T010 (sequential — each edit builds on the previous)
- US4: T011 → T012 (T012 references the variable set in T011)
- Polish: T013 [P] and T014 can run in parallel; T014 should follow T013

### Parallel Opportunities

- After US1 completes: US3 and US4 can be worked in parallel (different files)
- T011 [P] within US4 has no dependency on T008–T010 in US3 — US3 and US4 can proceed concurrently
- T013 [P] in Polish has no dependency on T014

---

## Parallel Example: US3 and US4 (after US1 complete)

```
# These two stories touch different files and can proceed concurrently:

Story 3 track: T008 → T009 → T010  (edits to .claude/commands/refine.md)
Story 4 track: T011 → T012          (edits to .claude/commands/query.md)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001)
2. Complete Phase 3 — US1 (T002–T004)
3. **STOP and VALIDATE**: Run the US1 independent test
4. A team can now frame their domain identity — this alone is a useful deliverable

### Incremental Delivery

1. T001 → US1 complete → validate → domain framing is live
2. Add US2 (T005–T007) → validate → seeding from existing docs is live
3. Add US3 (T008–T010) → validate → scope-aware refinement is live
4. Add US4 (T011–T012) → validate → query framing is live
5. Polish (T013–T014) → end-to-end validated

### Parallel Team Strategy (if two people)

- Person A: US1 → US2 (sequential — US2 builds on US1 schema)
- Person B: waits for US1 completion, then US3 and US4 in parallel (different files)

---

## Notes

- All deliverables are Markdown command files — no compilation, no build step
- "Implementation" means writing/editing the natural language instructions in `.claude/commands/*.md`
- Each command file section should be human-readable and follow the established style of existing commands (refine.md and query.md are good reference examples)
- The `domain/config/identity.md` template (T001) is the only file outside `.claude/commands/`
- Manual acceptance testing via Claude CLI is the validation mechanism for all stories
- Commit after each completed phase checkpoint
