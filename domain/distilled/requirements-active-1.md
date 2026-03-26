# Requirements — Active

<!-- Entries captured 2026-03-12 through 2026-03-16 (Features 003, 005, 006, 007, 008, 009 and cross-cutting FR-024 update). Split from requirements.md on 2026-03-17. -->

## Feature 003 — User Stories (US1–US3)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-a3f1, domain-20260312-b7c2, domain-20260312-d9e4]

### US1 — Fast Batch Processing via Host Pre-Filtering
A user invokes `/refine` with a raw queue containing 20 items. Before any subagent is invoked, the host eliminates exact duplicates (items whose content already exists verbatim in the distilled knowledge base) and items that clearly fall outside the domain scope (as defined in `config/identity.md`). The subagent receives only the items that genuinely require reasoning.

**Acceptance scenarios**:
1. Given a raw queue item whose content is identical to an existing distilled entry, When `/refine` runs, Then the host discards or archives the item before invoking any subagent, and the item does not appear in the subagent's input.
2. Given a raw queue item whose content matches a keyword or pattern explicitly listed in the domain's Out-of-scope list, When `/refine` runs, Then the host archives the item as out-of-scope before invoking any subagent.
3. Given a batch of 20 items where 8 are duplicates and 4 are out-of-scope, When `/refine` runs, Then the subagent receives at most 8 items, and all 12 filtered items are accounted for in the session output.

### US2 — Specialist Subagents Per Item-Type Cluster
A user invokes `/refine` with a mixed batch containing requirements, interface definitions, and ADR items. Instead of routing all items to one generalist subagent, the host routes each item to a specialist subagent matched to its type cluster. Each specialist uses a focused context window containing only the distilled files relevant to its type.

**Acceptance scenarios**:
1. Given a raw item classified as type `requirement`, When `/refine` runs, Then the item is routed to the requirements specialist subagent, not a generalist.
2. Given a raw item classified as type `interface`, When `/refine` runs, Then the item is routed to the interfaces specialist subagent with only interface-relevant distilled context loaded.
3. Given a batch with items of three different type clusters, When `/refine` runs, Then each item is processed by its corresponding specialist and the host merges the results into a single session output.
4. Given an item whose type cannot be determined, When `/refine` runs, Then the item falls back to the generalist subagent with full context.

### US3 — Improved Type Inference at Capture and Seed Time
A user invokes `/capture` or `/seed` to add new knowledge items. Instead of defaulting to type `other` when the type is ambiguous, the system applies higher-confidence inference rules to assign a specific type. This prevents `other`-typed items accumulating in the raw queue and triggering the full-load penalty during `/refine`.

**Acceptance scenarios**:
1. Given a captured item whose content clearly describes a system interface, When `/capture` runs, Then the item is assigned type `interface` rather than `other`.
2. Given a captured item whose content clearly describes a decision or rationale, When `/capture` runs, Then the item is assigned type `decision` rather than `other`.
3. Given a captured item that is genuinely ambiguous with no strong type signal, When `/capture` runs, Then the item is assigned type `other`.
4. Given a `/refine` session where no items are typed `other`, When the host loads context, Then the full-distilled-files load is not triggered and only type-specific files are loaded.

---

## Feature 003 — Edge Cases
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-2f5a]

- **Near-duplicate items**: Host pre-filtering handles only exact duplicates; semantically similar but non-identical items pass through to the subagent for reasoning.
- **Batch spans more types than specialist subagents exist**: Items whose type has no dedicated specialist fall back to the generalist subagent.
- **Out-of-scope list empty or missing in `config/identity.md`**: Host pre-filtering skips scope-based elimination and passes all items to the subagent.
- **Type inference confidence below threshold at capture time**: Item is stored as type `other` with a flag indicating low-confidence inference.
- **Host pre-filters all items in a batch (nothing left for subagent)**: The `/refine` session completes immediately with a summary of what was filtered and why; no subagent is invoked.

---

## Feature 003 — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-4e1d]

- **Delivery mechanism**: All changes are implemented as modifications to Claude command/skill files and their supporting prompt instructions — no standalone application.
- **Command surface**: Changes affect `/refine` (host pre-filtering, specialist routing), `/capture` (type inference), and `/seed` (type inference for bulk-imported items). No new commands are introduced.
- **Storage format**: Markdown with YAML frontmatter in version-controlled repository; no schema changes required.
- **Host AI**: Claude (claude-sonnet-4-6+); specialist subagents are additional Agent tool invocations orchestrated by the existing host.

---

## Feature 003 — Functional Requirements: Pre-Filtering (FR-001–FR-004)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-8c6b]

- **FR-001**: Before invoking any subagent, the `/refine` host MUST compare each raw item's content against all existing distilled entries and exclude exact duplicates from the subagent batch.
- **FR-002**: Before invoking any subagent, the `/refine` host MUST evaluate each raw item against the Out-of-scope list in the domain identity document and exclude items that clearly match Out-of-scope criteria.
- **FR-003**: Items excluded by pre-filtering MUST be accounted for in the session output (archived or discarded) with a reason recorded.
- **FR-004**: Pre-filtering MUST NOT exclude items that are ambiguous or only partially matching Out-of-scope criteria; those MUST pass through to the subagent.

---

## Feature 003 — Functional Requirements: Specialist Subagents (FR-005–FR-009)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-8c6b]

- **FR-005**: The `/refine` host MUST route each item to a subagent matched to the item's type cluster rather than always using a single generalist subagent.
- **FR-006**: Each specialist subagent MUST receive only the distilled context files relevant to its type cluster (as defined by the type-routing rules established in ADR-015).
- **FR-007**: At least the following type clusters MUST have dedicated specialists: `requirements`, `interfaces`, `decisions` (ADRs).
- **FR-008**: Items of type `other` or any type without a dedicated specialist MUST fall back to the generalist subagent.
- **FR-009**: The host MUST merge results from all specialist invocations into a single coherent session output before presenting results to the user.

---

## Feature 003 — Functional Requirements: Type Inference at Capture and Seed (FR-010–FR-014)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-8c6b]

- **FR-010**: At `/capture` time, the system MUST apply type inference logic to assign the most specific applicable type to each new item.
- **FR-011**: At `/seed` time, the same type inference logic MUST be applied to each item ingested from the source material, so that bulk-imported items arrive in the raw queue with specific types rather than defaulting to `other`.
- **FR-012**: Type inference MUST use content signals (keywords, structural patterns, referenced entities) to distinguish between `requirements`, `interfaces`, `decisions`, and other known types.
- **FR-013**: Type inference MUST assign type `other` only when no type-specific signal exceeds the confidence threshold.
- **FR-014**: Items assigned type `other` at capture or seed time MUST be flagged to indicate that inference was inconclusive, to aid future reclassification.

---

## Feature 003 — Success Criteria (SC-001–SC-005)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-3b9c]

- **SC-001**: At least 30% of raw items in a representative batch are eliminated by host pre-filtering (duplicate or out-of-scope) before any subagent is invoked, reducing subagent input size by at least 30% on average.
- **SC-002**: At least 70% of raw items are processed fully autonomously (no human intervention required) across a representative set of `/refine` sessions, meeting the existing SC-002 autonomy target more consistently than the baseline.
- **SC-003**: The governed-decision rate (items escalated to human review) drops by at least 20% for batches processed by specialist subagents compared to the generalist baseline on the same item types.
- **SC-004**: Fewer than 20% of newly captured or seeded items are assigned type `other` after the improved inference is in place, compared to the pre-improvement baseline.
- **SC-005**: No `/refine` session triggers a full-distilled-files load unless at least one item in the batch genuinely cannot be typed (i.e., is legitimately `other`).

---

## Feature 005 — User Stories (US1–US3): Semantic Duplicate Pre-Filtering
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a001, domain-20260313-a002, domain-20260313-a003]

### US1 — Near-Duplicates Filtered Before Subagent (P1)
A user runs `/refine` on a raw queue containing items that paraphrase or partially overlap with already-distilled knowledge. The host scores each incoming item against existing distilled entries; items at or above the similarity threshold are identified as semantic duplicates and excluded from the subagent batch automatically — the same way exact duplicates are handled today.

**Acceptance scenarios**:
1. Given a raw item that is a close paraphrase of an existing distilled entry, when `/refine` runs, then the host identifies it as a semantic duplicate, excludes it from the subagent batch, and records it as `[semantic-duplicate: <matched-entry-id>]` in the session output.
2. Given a raw item that mentions the same fact as a distilled entry using entirely different words, when `/refine` runs, then the host identifies the semantic overlap and excludes the item before any subagent is invoked.
3. Given a raw item that is genuinely new knowledge with no significant overlap to any distilled entry, when `/refine` runs, then the item passes through pre-filtering unchanged and reaches the subagent as normal.
4. Given a raw item that is an exact byte-for-byte duplicate of a distilled entry, when `/refine` runs, then the existing exact-duplicate pre-filter (Feature 003 FR-001) still catches it — no regression.

### US2 — Configurable Similarity Threshold (P2)
A domain owner wants to tune how aggressively near-duplicates are suppressed. The threshold is stored in the domain's `config/` directory and can be changed without modifying any command file.

**Acceptance scenarios**:
1. Given a similarity threshold configured in `config/`, when `/refine` runs, then the host uses that threshold for all pre-filter comparisons in the session.
2. Given no similarity threshold configured, when `/refine` runs, then the host applies a built-in default threshold and notes in session output that the default is in use.
3. Given a threshold value outside the valid range, when `/refine` runs, then the host rejects the config value, falls back to the default, and warns the user.

### US3 — Semantic Duplicate Outcomes Visible in Changelog (P3)
After a `/refine` session, a domain owner wants to understand what was suppressed and why. Semantic duplicate outcomes appear in the session changelog, clearly distinguished from other filter reasons, so users can audit the feature's behaviour and spot if the threshold needs adjustment.

**Acceptance scenarios**:
1. Given one or more semantic duplicates were suppressed in a `/refine` session, when the session completes, then each suppressed item is recorded in the session changelog entry with the matched distilled entry reference.
2. Given a `/refine` session where no semantic duplicates were found, when the session completes, then the changelog entry does not add a semantic-duplicate section (no empty noise).
3. Given a session that suppresses both exact duplicates and semantic duplicates, when the changelog is written, then the two categories appear separately and are clearly labelled.

---

## Feature 005 — Edge Cases: Semantic Duplicate Detection in /refine
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a004]

- **Multiple matches**: If a raw item is semantically similar to two or more distilled entries, the host records the closest match and suppresses the item once; both matched entries may be noted in session output.
- **Full-batch suppression**: If all items in a batch are identified as semantic duplicates, the session completes immediately with a full suppression summary; no subagent is invoked.
- **Empty or sparse knowledge base**: If the distilled knowledge base is empty or very sparse, similarity scoring finds no matches and all items pass through to the subagent as normal.
- **Micro-items**: If an item's content is too short to meaningfully compare, the host skips similarity scoring for that item and passes it through; a minimum-length threshold prevents false positives.
- **Comparison failure**: If the similarity comparison fails mid-batch, the failing item passes through to the subagent as a safe fallback; the failure is noted in session output but does not abort the session.

---

## Feature 005 — Functional Requirements (FR-001–FR-012): Semantic Pre-Filtering and Threshold Configuration
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a005, domain-20260313-a006]

### Semantic Pre-Filtering (FR-001–FR-006)
- **FR-001**: Before invoking any subagent, the `/refine` host MUST compare each raw item against all existing distilled entries for semantic similarity, extending (not replacing) the existing exact-duplicate check from Feature 003 FR-001.
- **FR-002**: The host MUST apply a configurable similarity threshold when classifying an item as a semantic duplicate; items scoring at or above the threshold MUST be excluded from the subagent batch.
- **FR-003**: Semantic duplicate items MUST be accounted for in the session output with: (a) the suppressed item's identifier, (b) the matched distilled entry reference, and (c) the basis for the match.
- **FR-004**: Items scoring below the similarity threshold MUST pass through to the subagent unchanged; the feature MUST NOT increase the false-negative rate for genuinely new knowledge.
- **FR-005**: The minimum content length for similarity comparison MUST be enforced; items below the minimum length MUST be passed through without similarity scoring.
- **FR-006**: Similarity comparison MUST be performed solely by the AI host's in-context reasoning; no external embedding APIs or external service calls are permitted. This preserves the no-external-service constraint established in Feature 003 Design Assumptions.

### Threshold Configuration (FR-007–FR-009)
- **FR-007**: A similarity threshold value MUST be readable from the domain's `config/` directory; the config key and file path MUST be documented in the feature's data model.
- **FR-008**: When no threshold is configured, the host MUST apply a documented default value and surface a visible notice in the session output.
- **FR-009**: An invalid or out-of-range threshold value MUST cause the host to fall back to the default and warn the user; it MUST NOT abort the session.

### Changelog Integration (FR-010–FR-012)
- **FR-010**: Every `/refine` session that suppresses one or more semantic duplicates MUST append a `### Semantic Duplicates` subsection to the session's changelog entry in `distilled/changelog.md`.
- **FR-011**: Sessions with zero semantic duplicates MUST NOT add a semantic-duplicate section to the changelog entry (no empty sections).
- **FR-012**: Semantic duplicate records in the changelog MUST be formatted consistently with existing exact-duplicate and out-of-scope records.

---

## Feature 005 — Technical Constraints, Key Entities, and Success Criteria
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a007, domain-20260313-a008]

### Technical Constraints
- **Delivery mechanism**: Enhancement to the existing `/refine` Claude command file — no new command surfaces introduced.
- **Command surface**: `/refine` (modified); no new skills or commands.
- **Storage format**: Similarity threshold stored as a config value in a Markdown or YAML file under `domain/config/`; changelog entries in existing `distilled/changelog.md` format.
- **Host AI**: Claude (claude-sonnet-4-6+); multi-host support deferred per Feature 001 constraints.
- **Scope boundary**: This feature modifies the host pre-filtering stage only. Subagent logic, governed-decision flow, and distilled-file write operations are unchanged.

### Key Entities
- **Raw item**: An unprocessed knowledge capture awaiting `/refine`; has an identifier and content body.
- **Distilled entry**: An existing processed knowledge item in any `distilled/` file; the corpus against which incoming raw items are compared.
- **Similarity score**: A measure of semantic overlap between a raw item and a distilled entry; compared against the threshold to determine suppression.
- **Similarity threshold**: A configurable value stored in `domain/config/` that sets the suppression boundary; items at or above this value are treated as semantic duplicates.

### Success Criteria
- **SC-001**: The proportion of raw items autonomously resolved (without a governed human decision) increases by at least 15 percentage points above the Feature 003 baseline, pushing the overall autonomy rate toward the 90%+ target.
- **SC-002**: Zero semantic duplicate items reach the subagent when the similarity threshold is correctly configured — confirmed by running a test batch where all near-duplicate items are known in advance.
- **SC-003**: A domain owner can adjust the similarity threshold and observe a measurable change in suppression behaviour on the next `/refine` run, without modifying any command file.
- **SC-004**: Every `/refine` session output provides a complete account of all suppressed items — exact duplicates, out-of-scope items, and semantic duplicates — so that no item silently disappears from the pipeline.

---

## Feature 006 — User Stories (US1–US3): Specialist Subagent Extension
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-3c4d, domain-20260313-5e6f, domain-20260313-7a8b]

### US1 — Codebase Items Routed to Focused Specialist (P1)
A user runs `/refine` with a batch that includes items of type `codebase` — descriptions of repositories, services, or tech stack entries. Instead of falling to the generalist subagent (which loads every distilled file), these items are routed to a dedicated codebase specialist that receives only `codebases.md` and `identity.md`.

**Acceptance scenarios**:
1. Given a raw item of type `codebase` in the active batch, When `/refine` runs, Then the item is routed to the codebase specialist, not the generalist.
2. Given the codebase specialist is invoked, When it processes items, Then it receives only `codebases.md` and `identity.md` — no other distilled files.
3. Given a batch containing only `codebase` items, When `/refine` completes, Then no full-distilled-files load is triggered and SC-005 is satisfied.

### US2 — Responsibility Items Routed to Focused Specialist (P2)
A user runs `/refine` with items of type `responsibility` — team ownership records, role definitions, or accountability mappings. These are routed to a responsibility specialist that loads only `responsibilities.md` and `identity.md`, rather than the full distilled context.

**Acceptance scenarios**:
1. Given a raw item of type `responsibility` in the active batch, When `/refine` runs, Then it is routed to the responsibility specialist, not the generalist.
2. Given the responsibility specialist is invoked, When it processes items, Then it receives only `responsibilities.md` and `identity.md`.
3. Given a batch where all items are either `codebase` or `responsibility`, When `/refine` completes, Then the generalist subagent is not invoked at all.

### US3 — Mixed Batch Correctly Partitioned Across All Specialists (P2)
A user runs `/refine` with a real-world mixed batch: some requirements, some interface definitions, some codebase entries, some responsibility records, and a few unrecognised items. The host correctly partitions the batch across five specialists (requirements, interfaces, decisions, codebase, responsibility) and the generalist, merges all results, and presents a single coherent session output.

**Acceptance scenarios**:
1. Given a mixed batch covering `requirement`, `interface`, `decision`, `codebase`, and `responsibility` types plus one `other` item, When `/refine` runs, Then exactly five specialist invocations and one generalist invocation occur.
2. Given all specialist invocations complete, When the host merges results, Then the combined session output is a single coherent list of autonomous actions and governed decisions, consistent with the Feature 003 merge format.
3. Given a `codebase` or `responsibility` item that cannot be confidently acted on autonomously, When the specialist raises a governed decision, Then the governed decision appears in the merged output and is presented to the user for resolution.

---

## Feature 006 — Edge Cases: Specialist Subagent Extension
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-9c0d]

- **Missing context file for new specialist**: If `codebases.md` or `responsibilities.md` does not yet exist in the domain, the specialist is still invoked using only `identity.md`; it MUST NOT fall back to a full-context load.
- **Responsibility item spanning two distilled files**: The specialist's defined context files govern — the host does not expand the context. Items that are genuinely ambiguous across files can be escalated as governed decisions.
- **Both `codebase` and `responsibility` items in same batch**: Both specialists are invoked concurrently, following the existing multi-specialist pattern from Feature 003.
- **All items covered by specialists, no `other` or unrecognised items**: The generalist is not invoked. This is the desired outcome satisfying SC-005.
- **Governed decision from new specialist conflicts with autonomous action from another specialist**: The merge step concatenates all results; conflict resolution follows the existing governed-decision escalation flow.

---

## Feature 006 — Functional Requirements: Extended Specialist Routing in /refine (FR-001–FR-009)
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-b1e2]

- **FR-001**: The `/refine` host routing table MUST include a `codebase` type cluster with a dedicated specialist subagent.
- **FR-002**: The `/refine` host routing table MUST include a `responsibility` type cluster with a dedicated specialist subagent.
- **FR-003**: The codebase specialist MUST receive only `codebases.md` and `identity.md` as distilled context — no other distilled files.
- **FR-004**: The responsibility specialist MUST receive only `responsibilities.md` (if it exists in the domain) and `identity.md` as distilled context — no other distilled files.
- **FR-005**: If the designated context file for a new specialist does not exist in the domain, the specialist MUST still be invoked using only `identity.md`, and MUST NOT fall back to a full-context load.
- **FR-006**: Items of type `stakeholder`, `task`, `mom`, `other`, and any unrecognised types MUST continue to fall back to the generalist subagent as defined in Feature 003 FR-008.
- **FR-007**: The host MUST continue to merge results from all specialist and generalist invocations into a single coherent session output, consistent with the merge behaviour specified in Feature 003 FR-009.
- **FR-008**: The session output MUST identify which specialist handled each item (for auditability), consistent with the existing per-cluster tracking.
- **FR-009**: The updated routing table MUST be documented in `refine.md` and supersede the Feature 003 FR-007 list.

---

## Feature 006 — Technical Constraints: /refine Specialist Extension
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-c3f4]

- **Delivery mechanism**: Changes are implemented as modifications to the `/refine` command file — no standalone application or new command introduced.
- **Command surface**: Only `/refine` is modified. No changes to `/capture`, `/seed`, or any other command.
- **Storage format**: Markdown with YAML frontmatter; no schema changes required.
- **Host AI**: Claude (claude-sonnet-4-6+); new specialists are additional Agent tool invocations following the same pattern as existing specialists.

---

## Feature 006 — Success Criteria (SC-001–SC-004)
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-e7b8]

- **SC-001**: After this feature ships, the generalist subagent receives fewer items in a representative mixed batch — at minimum, `codebase` and `responsibility` items are no longer in its input, reducing generalist input by the proportion those types represent.
- **SC-002**: At least 70% of raw items across a representative set of `/refine` sessions are processed fully autonomously (no human intervention), meeting the system-wide SC-002 target more consistently than the Feature 003 baseline.
- **SC-003**: No `/refine` session triggers a full-distilled-files load for `codebase` or `responsibility` items; these types now satisfy SC-005 alongside requirements, interfaces, and decisions.
- **SC-004**: The governed-decision rate for `codebase` and `responsibility` items drops by at least 20% compared to processing those same items through the generalist, measured over a representative sample.

---

## Distilled Entry Consistency with Implementation (FR-024)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: [domain-20260316-a8e2, domain-20260316-c4f1]

**Motivation**: Distilled data accuracy is critical to user trust. If distilled entries describing implementation are stale or incorrect, queries produce misleading answers and users lose confidence in Domain Brain.

**Constraint**: Distilled entries that describe implementation MUST be kept current with the corresponding implementation. When implementation changes, affected distilled entries MUST be updated via the raw queue.

**Mechanism**: To be determined (see ADR-016).

---

## Feature 007 — Fix Stale /refine Interface Contract Routing Table
**Type**: requirement
**Captured**: 2026-03-16
**Source**: [domain-20260316-7a2c, domain-20260316-7a3d, domain-20260316-7a4e, domain-20260316-7a5f, domain-20260316-7a6a]

### User Story
A domain brain maintainer or developer consults the `/refine` Interface Contract to understand how item types are routed during a refine session. They need the routing table to accurately reflect the current system behaviour so they can correctly predict context loading and subagent selection.

**Why this priority**: The interface contract is the single authoritative reference for how `/refine` works. An incorrect routing table misleads developers building on or maintaining the system, and may cause future features to be designed against the wrong baseline.

**Acceptance Scenarios**:
1. Given the `/refine` Interface Contract routing table, When a developer looks up `codebase`, Then the table shows cluster `codebase` (specialist) and context files `codebases.md, identity.md`.
2. Given the `/refine` Interface Contract routing table, When a developer looks up `responsibility`, Then the table shows cluster `responsibility` (specialist) and context files `responsibilities.md (if present), identity.md`.
3. Given the routing table, When compared to the authoritative description in `codebases.md` ("Refine Pipeline — Type Clusters and Subagents"), Then the two are fully consistent with no contradictions.

### Edge Cases
- If `responsibilities.md` does not exist, the table still reflects the correct cluster assignment; the "(if present)" qualifier on the context file is preserved.
- Only the two explicitly identified rows (`codebase` and `responsibility`) are in scope for this fix; all other rows remain unchanged.

### Functional Requirements (FR-001–FR-004)
- **FR-001**: The routing table in the `/refine` Interface Contract MUST list `codebase` as routing to the `codebase` specialist cluster with context files `codebases.md, identity.md`.
- **FR-002**: The routing table MUST list `responsibility` as routing to the `responsibility` specialist cluster with context files `responsibilities.md (if present), identity.md`.
- **FR-003**: All other rows in the routing table MUST remain unchanged.
- **FR-004**: The updated routing table MUST be consistent with the "Refine Pipeline — Type Clusters and Subagents" entry in `distilled/codebases.md`.

### Technical Constraints
- **Delivery mechanism**: Direct edit to `distilled/interfaces.md` — no command file changes required.
- **Storage format**: Markdown file in version-controlled repository.
- **Scope**: Single table edit in one file. No behaviour changes; documentation fix only.

### Success Criteria (SC-001–SC-003)
- **SC-001**: The routing table in `distilled/interfaces.md` contains zero rows that contradict the routing behaviour documented in `distilled/codebases.md`.
- **SC-002**: A developer reading both files can confirm `codebase` and `responsibility` routing is identical across both sources in under 30 seconds.
- **SC-003**: The fix is a single, reviewable edit with no unintended side effects on other table rows or surrounding content.

---

## Feature 008 — Consistency-Check Mechanism
**Type**: requirement
**Captured**: 2026-03-16
**Source**: [domain-20260316-8b5a, domain-20260316-8b6b, domain-20260316-8b8d, domain-20260316-8b9e]

### Functional Requirements (FR-001–FR-008)
- **FR-001**: The consistency-check mechanism MUST identify distilled entries whose source artefacts have changed since the entry was last updated.
- **FR-002**: The mechanism MUST NOT flag entries whose source artefacts are unchanged (zero false positives on unchanged sources).
- **FR-003**: The mechanism MUST surface flagged entries with sufficient context for the steward to decide: entry title, source artefact path, and an indication of what changed.
- **FR-004**: The steward MUST be able to dismiss a flagged entry (mark as reviewed without content change).
- **FR-005**: The steward MUST be able to initiate re-capture of a flagged entry's content (handoff to `/capture` or direct edit).
- **FR-006**: The mechanism MUST operate without external services or persistent background processes, consistent with the Extension-First principle.
- **FR-007**: ADR-018 MUST be resolved before implementation begins. ADR-018 has been resolved as of 2026-03-16 as Option B: standalone `/consistency-check` command. (The Feature 008 spec referred to this as ADR-016; it is recorded as ADR-018 in `distilled/decisions.md`.)
- **FR-008**: Each consistency-check run MUST append a summary of candidates found and resolutions made to `distilled/changelog.md`.

### Technical Constraints
- **Delivery mechanism**: Claude command file — no standalone app, no server, no daemon.
- **Storage format**: Markdown with YAML frontmatter in a version-controlled repository.
- **External services**: None. Change detection uses only local information (git history or file metadata).
- **Host AI**: Claude (claude-sonnet-4-6+); built-in tools only.
- **Invocation model**: Determined by ADR-018 (Option B: standalone `/consistency-check` command).

### Success Criteria (SC-001–SC-005)
- **SC-001**: A steward can identify all distilled entries affected by a set of source changes in a single consistency-check run — zero manual cross-referencing required.
- **SC-002**: Zero false positives: entries with unchanged source artefacts are never surfaced as stale candidates.
- **SC-003**: A steward can complete the full review-and-resolve cycle for a single flagged entry in under 3 minutes.
- **SC-004**: The mechanism runs fully offline — no network access or external service calls.
- **SC-005**: ADR-018 is resolved and recorded in `distilled/decisions.md` before any implementation work begins. (Satisfied as of 2026-03-16.)

### Assumptions
- Distilled entries eligible for consistency-checking carry a `**Source**` field referencing a command file path. Entries without this field are skipped.
- Change detection uses git commit history or file modification timestamps, as specified by ADR-018 (Option B).
- The steward's action workflow (re-capture, archive, dismiss) reuses the existing `/capture` and `/refine` pipeline; no new write path is introduced.
- At any given time, 10–30 distilled entries are expected to have trackable source links — well within the in-context retrieval tier.

---

## Feature 009 — User Story 1: Detect an Oversized Distilled File (P1)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-4c5d

A steward running `/refine` encounters a distilled file that has grown beyond the reliable-retrieval threshold. Before processing any raw items, the pre-processing phase detects the oversized file and surfaces a governed decision proposing a split plan. The session pauses until the steward confirms or dismisses.

**Acceptance Scenarios**:
1. Given a distilled file above threshold, when `/refine` is invoked, then a split proposal is surfaced as a governed decision before any raw items are processed.
2. Given all distilled files below threshold, when `/refine` is invoked, then no split proposal is surfaced and the session proceeds normally.
3. Given multiple oversized files, when `/refine` is invoked, then each is surfaced as a separate governed decision, one at a time.

---

## Feature 009 — User Story 2: Confirm and Execute a Split (P2)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-6e7f

The steward reviews the proposed split (showing which entries go into each sub-file) and confirms. The system creates the sub-files, retires the original, appends a changelog entry, and resumes the raw queue — all within the same invocation.

**Acceptance Scenarios**:
1. Given a confirmed split proposal, the system creates sub-files with entries distributed as proposed.
2. The original oversized file is retired (not left as a duplicate alongside sub-files).
3. A changelog entry is appended recording the split action, source file, and resulting sub-files.
4. The refine session resumes the raw queue without requiring a new invocation.

---

## Feature 009 — User Story 3: Dismiss or Flag a Split Proposal (P3)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-8a9b

The steward may dismiss a split proposal (skip for now) or flag it as an unresolved decision. In either case the session continues without splitting and no files are modified. The same file will be flagged again in the next session until the steward acts.

**Acceptance Scenarios**:
1. Given "skip for now", the session continues and no files are modified.
2. Given "flag as unresolved" (option Z), an open ADR is created in `decisions.md` and the session continues.
3. At the next `/refine` invocation the split proposal is surfaced again — dismissal is not permanent.

---

## Feature 009 — Functional Requirements FR-001–FR-010
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-2e3f

- **FR-001**: `/refine` MUST include a pre-processing phase that detects oversized distilled files before processing raw items.
- **FR-002**: For each oversized file, generate a split proposal grouping by recency (active/recent vs. older/archived) as default axis. Sub-file names follow `{base}-{group-label}-{n}.md`. Proposal MUST include a stated grouping rationale.
- **FR-003**: Each split proposal MUST be surfaced as a governed decision, one at a time (not batched).
- **FR-004**: Every split governed decision MUST include "flag as unresolved" as an option, creating an open ADR in `decisions.md`.
- **FR-005**: The steward MUST be able to accept, dismiss, or redirect (with a different grouping) within the governed decision exchange.
- **FR-006**: On confirmed split: create sub-files, retire the original, update changelog — then resume the raw item queue.
- **FR-007**: Executed split MUST be recorded in `distilled/changelog.md` with source file name, resulting sub-file names, entry counts per sub-file, and steward's rationale (or "no rationale provided").
- **FR-008**: After a confirmed split the refine session MUST resume the remaining raw queue within the same invocation.
- **FR-009**: The entry-count threshold MUST be configurable; a sensible default MUST apply when no configuration is present.
- **FR-010**: If a file cannot be meaningfully split (e.g., single entry), surface a warning rather than a split proposal and continue without blocking.

---

## Feature 009 — Sub-file Naming Convention
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-3c4d

Sub-file names MUST follow `{base}-{group-label}-{n}.md`:

| Component | Rule |
|---|---|
| `{base}` | Original filename without `.md` (e.g., `requirements`) |
| `{group-label}` | Derived from grouping label (`active`, `archived`) or steward-provided name |
| `{n}` | Sequential integer starting at 1; incremented if a file with that name already exists |

Examples: `requirements-active-1.md`, `requirements-archived-1.md`; steward-named groups: `requirements-core-1.md`, `requirements-legacy-1.md`.

---

## Feature 009 — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-4a5b

- **Delivery**: Integrated into `/refine` as a pre-processing phase; no separate command.
- **Command surface**: Extends `.claude/commands/refine.md` only — no new commands or storage formats.
- **Storage format**: Markdown files with YAML frontmatter; sub-files follow the same naming and header conventions as existing distilled files.
- **Host AI**: Claude (claude-sonnet-4-6+); built-in tools only (Read, Write, Edit, Glob, Bash for git).
- **Governed action pattern**: All file writes require steward confirmation. No silent file creation or deletion.

---

## Feature 009 — Edge Cases
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-0c1d

- **Single-entry oversized file**: Split cannot be proposed; system warns the steward that the entry itself may need condensing, not the file split.
- **Proposed split yields empty sub-file**: System MUST NOT propose splits resulting in empty files; must re-partition until all sub-files have at least one entry.
- **Steward wants different grouping**: System accepts natural language re-grouping instructions in the governed decision response and revises the proposal.
- **Multiple oversized files simultaneously**: Each is presented as a separate governed decision, sequentially.
- **Split sub-file later grows past threshold**: Subject to the same detection on the next refine session.
- **All entries share the same `Captured` date**: Recency grouping falls back to the `**Type**` field as a secondary axis; steward may override.

---

## Feature 009 — Success Criteria SC-001–SC-005
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-8e9f

- **SC-001**: A steward running `/refine` against an oversized distilled file is shown a split proposal before any raw items are processed — zero sessions where oversized files silently grow further.
- **SC-002**: The steward can confirm, dismiss, or redirect a split proposal in a single exchange (at most one clarifying follow-up turn per proposal).
- **SC-003**: After a confirmed split, sub-files together contain exactly the same entries as the original — zero entries lost or duplicated.
- **SC-004**: Every executed split is recorded in the changelog with source file, sub-file names, and rationale — 100% traceability.
- **SC-005**: Dismissing a split proposal does not block the refine session — raw item processing continues within the same invocation.

---

## Feature 001 (explicit-subagents) — User Story 1: Edit Subagent Instructions Without Touching the Refine Command
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-1a2b

A maintainer wants to tune the subagent's classification rules or update the output format contract without navigating the full 700-line refine command. With subagent instructions extracted to their own file, they can open, edit, and review just the subagent content — no risk of inadvertently modifying the host command's step logic.

**Why this priority**: The entire refine pipeline is currently a single monolithic file; any edit requires the maintainer to navigate the full file, increasing the risk of accidental side-effects. Separating subagent instructions is the direct fix.

**Acceptance Scenarios**:
1. Given the subagent instructions are in a separate file, When a maintainer edits only that file to add a new autonomous action type, Then the next `/refine` session uses the updated instructions with no changes to the host command file.
2. Given the subagent instructions are in a separate file, When a maintainer opens `refine.md` to adjust the step 6.5 pre-filtering logic, Then the subagent instructions file is not opened or modified.

---

## Feature 001 (explicit-subagents) — User Story 2: Subagent Files Are Discoverable and Self-Describing
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-2c3d

A maintainer new to the codebase wants to understand which subagents the refine pipeline uses and what each one does. Separate subagent files should be named and located so their purpose is immediately clear without requiring the maintainer to read the full host command.

**Why this priority**: Discoverability compounds the value of separation. A file named `refine-subagent.md` in a predictable location communicates its purpose at a glance; a buried section heading inside a 700-line file does not.

**Acceptance Scenarios**:
1. Given the refine pipeline is in place, When a maintainer lists the command files, Then the subagent file(s) are visible and their names describe their role (e.g., `refine-subagent.md`).
2. Given a subagent file exists, When a maintainer reads it, Then its header or opening paragraph identifies which command invokes it and what its output contract is.

---

## Feature 001 (explicit-subagents) — User Story 3: Host Command References Subagent File, Not Inline Block
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-3e4f

When `/refine` invokes a specialist subagent via the Agent tool, it loads the subagent's instructions from the dedicated file rather than embedding them inline. This keeps the host command lean and ensures a single source of truth for subagent behaviour.

**Acceptance Scenarios**:
1. Given the refine command has been updated, When a maintainer reads `refine.md`, Then no inline subagent instructions section is present.
2. Given the refine command invokes a subagent, When the session runs, Then the subagent receives the same instructions it received when they were inline — behaviour is unchanged.
3. Given the subagent file is missing or unreadable at session start, When `/refine` is invoked, Then the command surfaces an error identifying the missing file before attempting any processing.

---

## Domain Brain Must Be Installable in Any Project
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-3f7c, domain-20260319-c4f1

It must be possible to install Domain Brain in any project as an AI extension (similar to speckit), to keep track of a defined domain of knowledge. The system's portability is a first-class product requirement — not a consequence of how it happens to be built.

**Installation model**: Domain Brain installs per-project (not globally), supporting multiple parallel instances on the same machine. The installer (future feature) must set up:
- Scaffold folders: `distilled/`, `raw/`, `config/`
- Project-local commands (`.claude/commands/`): `refine`, `triage`, `consistency-check`, `query`, `frame`
- Project-local skills (`.claude/skills/`): `capture`, `seed`

---

## Feature 001 (explicit-subagents) — Edge Cases
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-4a5b

- **Accidentally deleted subagent file**: The host command must detect the missing file at start-up and report an actionable error rather than invoking the Agent tool with empty instructions.
- **Both files modified in same change**: Changes to host command and subagent file are independent; no coupling or merge logic is required.
- **Multiple specialist subagent types introduced in future**: The file structure accommodates additional subagent files without requiring changes to the naming convention.
- **Subagent file contains host-injected context (e.g., `priority_guidelines`)**: Separation must preserve the host's responsibility for assembling the full Agent tool invocation payload; the subagent file contains only the static instruction text.

---

## Feature 001 (explicit-subagents) — Functional Requirements (FR-001–FR-006)
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-5c6d

- **FR-001**: The `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block currently embedded in `refine.md` MUST be extracted to one or more dedicated subagent instruction files.
- **FR-002**: Each subagent instruction file MUST be stored in `.claude/agents/` — a dedicated directory separate from host commands in `.claude/commands/`.
- **FR-003**: The `/refine` host command MUST load the subagent instruction file(s) at session start and use their contents when invoking the Agent tool — no inline instruction text remains in `refine.md`.
- **FR-004**: If a required subagent instruction file is absent or unreadable, the host command MUST stop and output an error message that identifies the missing file by path before any processing begins.
- **FR-005**: The `/refine` command's observable behaviour — types processed, output format, governed decision flow, changelog entries — MUST be identical before and after this change.
- **FR-006**: Each subagent instruction file MUST open with a plain Markdown prose header (no YAML frontmatter) identifying: the command that invokes it, the types of items it processes, and the output contract it must satisfy.

---

## Feature 001 (explicit-subagents) — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-6e7f

- **Delivery mechanism**: Claude command file modification — no new programming language or runtime required.
- **Command surface**: `/refine` is the only command affected; no new commands or skills are exposed.
- **Storage format**: Markdown files; host commands in `.claude/commands/`, subagent instruction files in `.claude/agents/`.
- **Host AI**: Claude (claude-sonnet-4-6+); the Agent tool is used to invoke subagents and is the mechanism for passing instruction content.

---

## Feature 001 (explicit-subagents) — Success Criteria (SC-001–SC-004)
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-8c9d

- **SC-001**: After the change, `refine.md` contains no inline subagent instructions section — a search of the file for the `SUBAGENT INSTRUCTIONS` heading returns no matches.
- **SC-002**: A `/refine` session run against a representative batch produces the same autonomous actions, governed decision prompts, and changelog output as the pre-change baseline — zero behavioural regressions.
- **SC-003**: All subagent instruction files are locatable by listing `.claude/agents/` — a maintainer can find every subagent file without reading `refine.md`.
- **SC-004**: Editing the subagent instruction file and running `/refine` uses the updated instructions without any modification to `refine.md`.

---

## Domain Brain — Multi-AI Support (Product Direction)
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-a4f2

The product direction is that Domain Brain should support AI assistants beyond Claude, including self-hosted AIs such as Ollama and Qwen. This is a stated product direction and near-term goal — not yet a hard MUST constraint on any current feature. Multi-assistant support remains deferred to a future feature iteration, to be specified when implementation options are understood.

---

## Feature 001 (explicit-subagents) — Data Model Invariants
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-e9fa

- The content of the subagent instructions MUST be byte-for-byte identical to the current inline block (no rewording, no additions) — this feature is a structural refactor only.
- The `.claude/agents/` directory MUST exist before `/refine` is invoked.
- No other files are created or modified by this feature.

---

## Feature 010 — User Stories (US1–US3)
**Type**: requirement
**Captured**: 2026-03-18
**Source**: [domain-20260318-b2c3, domain-20260318-c4d5, domain-20260318-d6e7]

> **Command note**: These stories were written against a standalone `/consolidate` command. That command was subsequently merged into `/consistency-check` as Step 6 (README refresh). All `/consolidate` references below apply to `/consistency-check` Step 6.

### US1 — Steward Generates Domain README (P1)
The steward runs `/consistency-check` for the first time in a domain brain project. A human-readable `domain/README.md` is created containing: the domain one-liner and pitch, the interfaces the domain exposes, a brief guide to using the domain brain, and the current top open priorities from the backlog. Stakeholders and new contributors can read a single document to understand the domain — no AI interaction required.

**Why**: Without this, distilled knowledge is only accessible through AI queries. This makes the knowledge base legible to anyone with repository access.

**Acceptance scenarios**:
1. Given `domain/README.md` does not exist, When the steward runs `/consistency-check`, Then the file is created with four labelled sections.
2. Given `config/identity.md` exists, When the command runs, Then the Domain Summary section reflects the current identity file content verbatim.
3. Given a changelog entry for the run is expected, When the command completes, Then an entry is appended to `distilled/changelog.md`.

### US2 — New Team Member Reads the README (P2)
A new developer clones the repository and opens `domain/README.md` in their git browser. Without running any command or interacting with AI, they can read the domain's purpose, see which interfaces exist, understand how to query the domain brain, and identify what the team is currently working on.

**Acceptance scenarios**:
1. Given a generated `domain/README.md`, When a reader opens it in a git browser, Then all content is readable as standard Markdown.
2. Given the domain has open high-priority backlog items, When a reader reads the Top Priorities section, Then they see item titles and a one-line description ordered high → medium.
3. Given the domain has active interface contracts, When a reader reads the Exposed Interfaces section, Then they see each interface contract title listed.

### US3 — README Stays Current After Domain Changes (P3)
After the team closes several backlog items and adds a new interface contract, the steward runs `/consistency-check` again. The existing `domain/README.md` is updated — new priorities surface, the new interface appears, and outdated content is replaced.

**Why**: A stale README is worse than no README. Ensuring the command overwrites rather than appends is essential for the document's trust.

**Acceptance scenarios**:
1. Given `domain/README.md` already exists, When the steward runs `/consistency-check`, Then the existing file is fully overwritten (not appended to).
2. Given a backlog item was closed, When the command runs again, Then the closed item does not appear in Top Priorities.
3. Given a new interface contract was added, When the command runs again, Then the new interface appears in Exposed Interfaces.

---

## Feature 010 — Edge Cases (README Generation)
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-e8f9

> **Command note**: Written against `/consolidate`; now applies to `/consistency-check` Step 6.

- `config/identity.md` absent → Step 6 MUST error: "Domain identity not found. Run /frame first." README is not created or modified.
- `distilled/interfaces.md` absent → Exposed Interfaces section displays "No interfaces defined yet." No error.
- `distilled/backlog.md` has no open items → Top Priorities section displays "No open items." No error.
- Backlog has only low-priority items → Include the top 5 open items regardless of priority level.
- More than 5 high-priority items → Show the top 5 by priority tier and append "… and N more open items — run /query for the full list."
- `distilled/changelog.md` absent → Step 6 creates it before appending the session entry.

---

## Feature 010 — Functional Requirements (FR-001–FR-010)
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-fa0b

> **Command note**: Written against `/consolidate`; now applies to `/consistency-check` Step 6.

- **FR-001**: Step 6 MUST create `domain/README.md` if it does not exist.
- **FR-002**: Step 6 MUST fully overwrite `domain/README.md` if it already exists — never append.
- **FR-003**: README MUST include a **Domain Summary** section containing the domain one-liner, pitch, and steward name sourced from `config/identity.md`.
- **FR-004**: README MUST include an **Exposed Interfaces** section listing all interface contract titles from `distilled/interfaces.md`. If absent or empty: "No interfaces defined yet."
- **FR-005**: README MUST include an **Intended Usage** section describing the primary commands — as static prose.
- **FR-006**: README MUST include a **Top Priorities** section listing up to 5 open backlog items, ordered high → medium → low. Each item MUST show its title and a one-line description. If no open items: "No open items."
- **FR-007**: README MUST be valid, human-readable Markdown renderable in standard git hosting interfaces.
- **FR-008**: Step 6 MUST append an entry to `distilled/changelog.md` at the end of each run.
- **FR-009**: If `config/identity.md` does not exist, Step 6 MUST stop with "Domain identity not found. Run /frame first." and MUST NOT create or modify `domain/README.md`.
- **FR-010**: README MUST include a footer line indicating when it was last generated.

---

## Feature 010 — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-18
**Source**: domain-20260318-0c1d

> **Command note**: Written against a standalone `/consolidate` command; now applies to `/consistency-check` Step 6. There is no separate `.claude/commands/consolidate.md` file.

- **Delivery mechanism**: Step 6 of `.claude/commands/consistency-check.md` — no standalone application, no external services.
- **Command surface**: `/consistency-check` (existing command, Step 6); no new commands added.
- **Output file**: `domain/README.md` — a standard Markdown file in the domain root directory.
- **Host AI**: Claude (claude-sonnet-4-6+); no dependencies beyond built-in Read, Write, Glob tools.
- **Context loading**: Reads only `config/identity.md`, `distilled/interfaces.md`, `distilled/backlog.md`. MUST NOT load changelog, raw items, decisions, or requirements files.

---

## Feature 010 — Success Criteria and Assumptions
**Type**: requirement
**Captured**: 2026-03-18
**Source**: [domain-20260318-2e3f, domain-20260318-4a5b]

> **Command note**: Written against `/consolidate`; now applies to `/consistency-check` Step 6.

### Success Criteria (SC-001–SC-005)
- **SC-001**: A person who has never interacted with the domain brain can correctly identify the domain's purpose, at least one exposed interface, and the team's current top priority by reading `domain/README.md` alone — zero AI interaction required.
- **SC-002**: Step 6 completes and produces a complete, valid README in a single invocation with no follow-up prompts.
- **SC-003**: After running `/consistency-check` a second time following any change to backlog or interfaces, the README accurately reflects the current state — zero stale content.
- **SC-004**: The generated README renders without broken formatting in at least two standard git hosting interfaces (GitHub-style Markdown).
- **SC-005**: The Top Priorities section always reflects the current open backlog state — no closed or dropped items appear after a run.

### Assumptions
- The output file path is always `domain/README.md` (relative to the domain brain root).
- The Intended Usage section is static prose describing the primary commands; it does not vary by domain and does not require reading from any file.
- `/consistency-check` is invoked manually by the steward — there is no automatic trigger from other commands. Automation is deferred.
- The "top 5 priorities" cap is fixed (not configurable in v1).
- Interface contracts are listed by title only in the README — no body content included.
- The command does not validate the content of `config/identity.md` beyond confirming the file exists.

---

## Open Questions and Long-Running Problem Resolution (Intent)
**Type**: requirement
**Captured**: 2026-03-25
**Source**: domain-brain-20260325-a1b2

Domain Brain must support "open questions" — topics that cannot be immediately answered but accumulate evidence over time until they are resolved.

A domain may have many open questions at any point (e.g. "What technology should we use?", "How do we handle security?"). Over time, information relevant to a question is captured — including from sources the user does not consciously connect to the question (e.g. a meeting minute that mentions something pertinent). Domain Brain must serve as the memory that compiles whatever is currently known about a question at any point in time.

Required query capabilities:
- What open questions do we currently have?
- What do we currently know about question X?
- What decisions have already been made regarding question X?
- What should the next steps be to resolve question X?

Questions may be hierarchically related: a question like "How do we handle client authentication?" may be a sub-question of "How do we handle security on future APIs?". The system must be able to represent and navigate these relationships.

**Implementation approach is unspecified.** See backlog task "Open Question Support & Long-Running Problem Resolution" for analysis work.

---

## Feature 002 Extension: Online Sources, Source Preservation, and Partial-Relevance Filtering
**Type**: requirement
**Captured**: 2026-03-26
**Source**: [domain-20260326-a4f2]

Extends Feature 002 (Seed Pipeline) with three additions:

### FR-002-EXT-1: MCP Connection Sources
The /seed command MUST support MCP connections as a source type in addition to Markdown files, PDFs, and web URLs. MCP sources expose structured content (e.g. Confluence spaces, Notion databases) through a standard protocol. The technical constraint 'No MCP connection support (future feature)' in Feature 002 is hereby lifted and replaced by this requirement.

### FR-002-EXT-2: Source Reference Preservation on Chunking
When any online source (web URL or MCP resource) is split into chunks, each chunk MUST carry a source reference in its frontmatter that is resolvable back to the original online resource. For web URLs this is the canonical URL plus a byte-offset or heading anchor. For MCP resources this is the MCP resource URI plus any applicable sub-resource identifier. This extends the existing source-location frontmatter requirement to cover online sources explicitly.

### FR-002-EXT-3: Partial-Relevance Filtering for Large Online Sources
Online sources may contain large volumes of content with only partial relevance to the target domain. The seed pipeline MUST apply a relevance filter before storing chunks. Chunks assessed as out-of-scope for the configured domain MUST be discarded rather than stored. The filtering decision and the count of discarded chunks MUST be reported to the user at the end of a seed operation. The filter MUST operate per-chunk so that a single large document can yield both retained and discarded chunks.

---
