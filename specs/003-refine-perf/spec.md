# Feature Specification: Refine Pipeline Performance Improvements

**Feature Branch**: `003-refine-perf`
**Created**: 2026-03-12
**Status**: Draft
**Input**: Three targeted performance improvements to the `/refine` pipeline: host-level pre-filtering, specialist subagents, and elimination of the `other`-type full-load penalty.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fast Batch Processing via Host Pre-Filtering (Priority: P1)

A user invokes `/refine` with a raw queue containing 20 items. Before any subagent is invoked, the host eliminates exact duplicates (items whose content already exists verbatim in the distilled knowledge base) and items that clearly fall outside the domain scope (as defined in `config/identity.md`). The subagent receives only the items that genuinely require reasoning.

**Why this priority**: This directly reduces the cost and latency of every single `/refine` session. It is the most broadly applicable improvement and has the highest impact on the SC-002 autonomy target. It can be built and validated without changing any subagent logic.

**Independent Test**: Run `/refine` with a batch where at least 30% of items are exact duplicates or clearly out-of-scope. Verify the subagent receives a smaller batch and that the filtered items are correctly archived or discarded without human review.

**Acceptance Scenarios**:

1. **Given** a raw queue item whose content is identical to an existing distilled entry, **When** `/refine` runs, **Then** the host discards or archives the item before invoking any subagent, and the item does not appear in the subagent's input.
2. **Given** a raw queue item whose content matches a keyword or pattern explicitly listed in the domain's Out-of-scope list, **When** `/refine` runs, **Then** the host archives the item as out-of-scope before invoking any subagent.
3. **Given** a batch of 20 items where 8 are duplicates and 4 are out-of-scope, **When** `/refine` runs, **Then** the subagent receives at most 8 items, and all 12 filtered items are accounted for in the session output.

---

### User Story 2 - Specialist Subagents Per Item-Type Cluster (Priority: P2)

A user invokes `/refine` with a mixed batch containing requirements, interface definitions, and ADR items. Instead of routing all items to one generalist subagent, the host routes each item to a specialist subagent matched to its type cluster. Each specialist uses a focused context window containing only the distilled files relevant to its type.

**Why this priority**: Specialist agents make faster and more consistent decisions, reducing the proportion of items escalated for human review. This directly advances the SC-002 autonomy target for each item type independently. It builds on the pre-filtering improvement (P1) but can be scoped to one specialist at a time.

**Independent Test**: Run `/refine` with a batch containing only requirements-type items routed to a requirements specialist. Verify decisions are consistent and the governed-decision rate drops compared to the generalist baseline.

**Acceptance Scenarios**:

1. **Given** a raw item classified as type `requirements`, **When** `/refine` runs, **Then** the item is routed to the requirements specialist subagent, not a generalist.
2. **Given** a raw item classified as type `interfaces`, **When** `/refine` runs, **Then** the item is routed to the interfaces specialist subagent with only interface-relevant distilled context loaded.
3. **Given** a batch with items of three different type clusters, **When** `/refine` runs, **Then** each item is processed by its corresponding specialist and the host merges the results into a single session output.
4. **Given** an item whose type cannot be determined, **When** `/refine` runs, **Then** the item falls back to the generalist subagent with full context.

---

### User Story 3 - Improved Type Inference at Capture Time (Priority: P3)

A user invokes `/capture` to add a new knowledge item. Instead of defaulting to type `other` when the type is ambiguous, the system applies higher-confidence inference rules to assign a specific type at capture time. This prevents `other`-typed items from accumulating in the raw queue and triggering the full-load penalty during `/refine`.

**Why this priority**: This is an upstream fix that reduces the root cause of the `other`-type full-load penalty. However, its effect is proportional to how many new items are captured going forward — it does not retroactively fix existing `other` items. It is lower priority than the direct pipeline improvements (P1, P2) but compounds with them over time.

**Independent Test**: Capture 10 knowledge items that would previously have been typed as `other`. Verify that at least 7 receive a specific type (not `other`) based on improved inference, and that those items do not trigger full-load behaviour during the next `/refine` run.

**Acceptance Scenarios**:

1. **Given** a captured item whose content clearly describes a system interface, **When** `/capture` runs, **Then** the item is assigned type `interfaces` rather than `other`.
2. **Given** a captured item whose content clearly describes a system decision or rationale, **When** `/capture` runs, **Then** the item is assigned an ADR-type rather than `other`.
3. **Given** a captured item that is genuinely ambiguous with no strong type signal, **When** `/capture` runs, **Then** the item is assigned type `other` and a note is added indicating the inference was inconclusive.
4. **Given** a `/refine` session where no items are typed `other`, **When** the host loads context, **Then** the full-distilled-files load is not triggered and only type-specific files are loaded.

---

### Edge Cases

- What happens when a raw item is a near-duplicate (semantically similar but not identical) of a distilled entry? Host pre-filtering handles only exact duplicates; near-duplicates pass through to the subagent.
- What happens when a batch contains items spanning more types than there are specialist subagents? Items whose type has no specialist fall back to the generalist.
- What happens when the Out-of-scope list in `config/identity.md` is empty or missing? Host pre-filtering skips scope-based elimination and passes all items to the subagent.
- What happens when type inference confidence is below threshold at capture time? The item is stored as type `other` with a flag indicating low-confidence inference.
- What happens when the host pre-filters all items in a batch (nothing left for the subagent)? The `/refine` session completes immediately with a summary of what was filtered and why.

## Requirements *(mandatory)*

### Functional Requirements

**Pre-Filtering (FR-001 – FR-004)**

- **FR-001**: Before invoking any subagent, the `/refine` host MUST compare each raw item's content against all existing distilled entries and exclude exact duplicates from the subagent batch.
- **FR-002**: Before invoking any subagent, the `/refine` host MUST evaluate each raw item against the Out-of-scope list in the domain identity document and exclude items that clearly match Out-of-scope criteria.
- **FR-003**: Items excluded by pre-filtering MUST be accounted for in the session output (archived or discarded) with a reason recorded.
- **FR-004**: Pre-filtering MUST NOT exclude items that are ambiguous or only partially matching Out-of-scope criteria; those MUST pass through to the subagent.

**Specialist Subagents (FR-005 – FR-009)**

- **FR-005**: The `/refine` host MUST route each item to a subagent matched to the item's type cluster rather than always using a single generalist subagent.
- **FR-006**: Each specialist subagent MUST receive only the distilled context files relevant to its type cluster (as defined by the type-routing rules established in ADR-015).
- **FR-007**: At least the following type clusters MUST have dedicated specialists: `requirements`, `interfaces`, `decisions` (ADRs).
- **FR-008**: Items of type `other` or any type without a dedicated specialist MUST fall back to the generalist subagent.
- **FR-009**: The host MUST merge results from all specialist invocations into a single coherent session output before presenting results to the user.

**Type Inference at Capture and Seed (FR-010 – FR-014)**

- **FR-010**: At `/capture` time, the system MUST apply type inference logic to assign the most specific applicable type to each new item.
- **FR-011**: At `/seed` time, the same type inference logic MUST be applied to each item ingested from the source material, so that bulk-imported items arrive in the raw queue with specific types rather than defaulting to `other`.
- **FR-012**: Type inference MUST use content signals (keywords, structural patterns, referenced entities) to distinguish between `requirements`, `interfaces`, `decisions`, and other known types.
- **FR-013**: Type inference MUST assign type `other` only when no type-specific signal exceeds the confidence threshold.
- **FR-014**: Items assigned type `other` at capture or seed time MUST be flagged to indicate that inference was inconclusive, to aid future reclassification.

### Technical Constraints

- **Delivery mechanism**: All changes are implemented as modifications to Claude command/skill files and their supporting prompt instructions — no standalone application.
- **Command surface**: Changes affect `/refine` (host pre-filtering, specialist routing), `/capture` (type inference), and `/seed` (type inference for bulk-imported items). No new commands are introduced.
- **Storage format**: Markdown with YAML frontmatter in version-controlled repository; no schema changes required.
- **Host AI**: Claude (claude-sonnet-4-6+); specialist subagents are additional Agent tool invocations orchestrated by the existing host.

### Key Entities

- **Raw item**: A pending knowledge entry in the raw queue, with content, type, and metadata.
- **Distilled entry**: A finalised knowledge record in one of the distilled files; used as the deduplication reference.
- **Domain identity document** (`config/identity.md`): Authoritative source for In-scope and Out-of-scope lists used in host pre-filtering.
- **Type cluster**: A grouping of related item types (e.g., `requirements`, `interfaces`, `decisions`) that maps to a specialist subagent.
- **Specialist subagent**: A subagent invoked by the host with a focused context window for a specific type cluster.
- **Generalist subagent**: The existing single subagent, retained as a fallback for unclassified or mixed-type items.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 30% of raw items in a representative batch are eliminated by host pre-filtering (duplicate or out-of-scope) before any subagent is invoked, reducing subagent input size by at least 30% on average.
- **SC-002**: At least 70% of raw items are processed fully autonomously (no human intervention required) across a representative set of `/refine` sessions, meeting the existing SC-002 autonomy target more consistently than the baseline.
- **SC-003**: The governed-decision rate (items escalated to human review) drops by at least 20% for batches processed by specialist subagents compared to the generalist baseline on the same item types.
- **SC-004**: Fewer than 20% of newly captured or seeded items are assigned type `other` after the improved inference is in place, compared to the pre-improvement baseline.
- **SC-005**: No `/refine` session triggers a full-distilled-files load unless at least one item in the batch genuinely cannot be typed (i.e., is legitimately `other`).

## Assumptions

- The host already has access to all distilled files in memory during a `/refine` session (per ADR-015); exact-duplicate detection requires no additional I/O.
- "Exact duplicate" means byte-for-byte identical content between the raw item and a distilled entry; semantic similarity detection is out of scope for this feature.
- The Out-of-scope list in `config/identity.md` contains explicit keywords or patterns sufficient for deterministic matching; fuzzy scope detection is out of scope.
- Three specialist subagents (`requirements`, `interfaces`, `decisions`) cover the majority of high-volume item types; additional specialists can be added in future iterations.
- Type inference at `/capture` and `/seed` time uses heuristic content analysis; machine-learning-based classification is out of scope.
- Existing `other`-typed items already in the raw queue are not retroactively reclassified; the improvement applies only to newly captured or seeded items.
