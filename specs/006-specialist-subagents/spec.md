# Feature Specification: Additional Specialist Subagents in /refine

**Feature Branch**: `006-specialist-subagents`
**Created**: 2026-03-13
**Status**: Draft
**Input**: Extend the specialist subagent roster beyond the three mandated by Feature 003 FR-007 (requirements, interfaces, decisions) to cover at least `codebase` and `responsibility` type clusters, which currently fall to the generalist subagent with full context loading.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Codebase Items Routed to Focused Specialist (Priority: P1)

A user runs `/refine` with a batch that includes items of type `codebase` — descriptions of repositories, services, or tech stack entries. Instead of falling to the generalist subagent (which loads every distilled file), these items are routed to a dedicated codebase specialist that receives only `codebases.md` and `identity.md`.

**Why this priority**: `codebase` items are among the highest-volume types in a typical domain brain. Removing them from the generalist's load is the single biggest reduction in unnecessary context. This is directly measurable and can be shipped and validated independently.

**Independent Test**: Run `/refine` with a batch containing only `codebase` items. Verify no full-distilled-files load occurs, the codebase specialist receives only `codebases.md` + `identity.md`, and decisions are consistent with the existing three-specialist pattern.

**Acceptance Scenarios**:

1. **Given** a raw item of type `codebase` in the active batch, **When** `/refine` runs, **Then** the item is routed to the codebase specialist, not the generalist.
2. **Given** the codebase specialist is invoked, **When** it processes items, **Then** it receives only `codebases.md` and `identity.md` — no other distilled files.
3. **Given** a batch containing only `codebase` items, **When** `/refine` completes, **Then** no full-distilled-files load is triggered and SC-005 is satisfied.

---

### User Story 2 - Responsibility Items Routed to Focused Specialist (Priority: P2)

A user runs `/refine` with items of type `responsibility` — team ownership records, role definitions, or accountability mappings. These are routed to a responsibility specialist that loads only `responsibilities.md` and `identity.md`, rather than the full distilled context.

**Why this priority**: Responsibility items require a focused view of existing ownership records and the domain identity to make merge/update decisions. They do not benefit from knowledge of interfaces, codebases, or decisions. Routing them to a specialist reduces noise in the subagent's context and improves decision consistency.

**Independent Test**: Run `/refine` with a batch of `responsibility` items only. Verify the responsibility specialist is invoked with `responsibilities.md` + `identity.md`, and that the generalist is not invoked for those items.

**Acceptance Scenarios**:

1. **Given** a raw item of type `responsibility` in the active batch, **When** `/refine` runs, **Then** it is routed to the responsibility specialist, not the generalist.
2. **Given** the responsibility specialist is invoked, **When** it processes items, **Then** it receives only `responsibilities.md` and `identity.md`.
3. **Given** a batch where all items are either `codebase` or `responsibility`, **When** `/refine` completes, **Then** the generalist subagent is not invoked at all.

---

### User Story 3 - Mixed Batch Correctly Partitioned Across All Specialists (Priority: P3)

A user runs `/refine` with a real-world mixed batch: some requirements, some interface definitions, some codebase entries, some responsibility records, and a few unrecognised items. The host correctly partitions the batch across five specialists (requirements, interfaces, decisions, codebase, responsibility) and the generalist, merges all results, and presents a single coherent session output.

**Why this priority**: The merge-and-present flow is already validated by Feature 003. This story verifies that the extended routing table integrates cleanly with the existing merge logic without regressions.

**Independent Test**: Run `/refine` with a batch spanning all five specialist-covered types plus one `other` item. Verify five specialist invocations and one generalist invocation occur, results are merged correctly, and the output is indistinguishable in format from a Feature 003 session.

**Acceptance Scenarios**:

1. **Given** a mixed batch covering `requirement`, `interface`, `decision`, `codebase`, and `responsibility` types plus one `other` item, **When** `/refine` runs, **Then** exactly five specialist invocations and one generalist invocation occur.
2. **Given** all specialist invocations complete, **When** the host merges results, **Then** the combined session output is a single coherent list of autonomous actions and governed decisions, consistent with the Feature 003 merge format.
3. **Given** a `codebase` or `responsibility` item that cannot be confidently acted on autonomously, **When** the specialist raises a governed decision, **Then** the governed decision appears in the merged output and is presented to the user for resolution.

---

### Edge Cases

- What happens when the `codebase` or `responsibility` distilled file does not yet exist for the domain? The specialist receives an empty file or skips the file load; it still processes the items using only `identity.md` for scope context.
- What happens when a raw item's type is `responsibility` but maps to a concept that spans two distilled files? The specialist's defined context files govern — the host does not expand the context. Ambiguous items can be escalated as governed decisions.
- What happens when `codebase` and `responsibility` items both appear in the same batch? Both specialists are invoked concurrently (same as the existing multi-specialist pattern from Feature 003).
- What happens when all items in the batch are covered by specialists and no `other` or unrecognised items exist? The generalist is not invoked. This is the desired outcome for SC-005.
- What happens when the new specialist produces a governed decision that conflicts with an autonomous action from another specialist? The merge step concatenates all results; conflict resolution follows the existing governed-decision escalation flow.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `/refine` host routing table MUST include a `codebase` type cluster with a dedicated specialist subagent.
- **FR-002**: The `/refine` host routing table MUST include a `responsibility` type cluster with a dedicated specialist subagent.
- **FR-003**: The codebase specialist MUST receive only `codebases.md` and `identity.md` as distilled context — no other distilled files.
- **FR-004**: The responsibility specialist MUST receive only `responsibilities.md` (if it exists in the domain) and `identity.md` as distilled context — no other distilled files.
- **FR-005**: If the designated context file for a new specialist does not exist in the domain, the specialist MUST still be invoked using only `identity.md`, and MUST NOT fall back to a full-context load.
- **FR-006**: Items of type `stakeholder`, `task`, `mom`, `other`, and any unrecognised types MUST continue to fall back to the generalist subagent as defined in Feature 003 FR-008.
- **FR-007**: The host MUST continue to merge results from all specialist and generalist invocations into a single coherent session output, consistent with the merge behaviour specified in Feature 003 FR-009.
- **FR-008**: The session output MUST identify which specialist handled each item (for auditability), consistent with the existing per-cluster tracking.
- **FR-009**: The updated routing table MUST be documented in `refine.md` and supersede the Feature 003 FR-007 list.

### Technical Constraints

- **Delivery mechanism**: Changes are implemented as modifications to the `/refine` command file — no standalone application or new command introduced.
- **Command surface**: Only `/refine` is modified. No changes to `/capture`, `/seed`, or any other command.
- **Storage format**: Markdown with YAML frontmatter; no schema changes required.
- **Host AI**: Claude (claude-sonnet-4-6+); new specialists are additional Agent tool invocations following the same pattern as existing specialists.

### Key Entities

- **Type cluster**: A grouping of related raw item types that maps to one specialist subagent. This feature adds two new clusters: `codebase` and `responsibility`.
- **Specialist subagent**: An Agent-tool invocation with a focused context window. The new specialists follow the same instruction template as the existing three from Feature 003.
- **Generalist subagent**: Retained as the fallback for `stakeholder`, `task`, `mom`, `other`, and unrecognised types. Its behaviour is unchanged by this feature.
- **Context file set**: The specific subset of distilled files passed to a specialist. Defined per cluster in the routing table.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After this feature ships, the generalist subagent receives fewer items in a representative mixed batch — at minimum, `codebase` and `responsibility` items are no longer in its input, reducing generalist input by the proportion those types represent.
- **SC-002**: At least 70% of raw items across a representative set of `/refine` sessions are processed fully autonomously (no human intervention), meeting the system-wide SC-002 target more consistently than the Feature 003 baseline.
- **SC-003**: No `/refine` session triggers a full-distilled-files load for `codebase` or `responsibility` items; these types now satisfy SC-005 alongside requirements, interfaces, and decisions.
- **SC-004**: The governed-decision rate for `codebase` and `responsibility` items drops by at least 20% compared to processing those same items through the generalist, measured over a representative sample.

## Assumptions

- The `codebases.md` and `responsibilities.md` distilled files exist (or are empty) in the domain brain; the specialist does not depend on their presence but benefits from it.
- The context files needed for `codebase` and `responsibility` decisions are primarily the respective distilled file plus `identity.md`. Cross-file lookups (e.g., a codebase entry referencing an interface) are handled by governing decisions rather than expanding context.
- The Feature 003 specialist instruction template (SUBAGENT INSTRUCTIONS — REFINE AGENT) is reused unchanged for the new specialists; no new instruction variant is required.
- `stakeholder`, `task`, and `mom` types remain in the generalist cluster for now; their relative volume and decision complexity do not yet justify dedicated specialists.
- This feature does not retroactively reclassify or reprocess any items already in the raw queue or distilled files.
