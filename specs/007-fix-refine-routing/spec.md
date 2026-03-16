# Feature Specification: Fix Stale /refine Interface Contract — Specialist Routing Table

**Feature Branch**: `007-fix-refine-routing`
**Created**: 2026-03-16
**Status**: Draft
**Input**: Fix the /refine Interface Contract routing table in distilled/interfaces.md to reflect Feature 006 specialist routing for `codebase` and `responsibility` item types.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Correct Routing Reference (Priority: P1)

A domain brain maintainer or developer consults the `/refine` Interface Contract to understand how item types are routed during a refine session. They need the routing table to accurately reflect the current system behaviour so they can correctly predict context loading and subagent selection.

**Why this priority**: The interface contract is the single authoritative reference for how `/refine` works. An incorrect routing table misleads developers building on or maintaining the system, and may cause future features to be designed against the wrong baseline.

**Independent Test**: Can be fully tested by reading the routing table in `distilled/interfaces.md` and confirming both `codebase` and `responsibility` rows show specialist cluster routing with the correct context file sets.

**Acceptance Scenarios**:

1. **Given** the `/refine` Interface Contract routing table, **When** a developer looks up `codebase`, **Then** the table shows cluster `codebase` (specialist) and context files `codebases.md, identity.md`.
2. **Given** the `/refine` Interface Contract routing table, **When** a developer looks up `responsibility`, **Then** the table shows cluster `responsibility` (specialist) and context files `responsibilities.md (if present), identity.md`.
3. **Given** the routing table, **When** compared to the authoritative description in `codebases.md` ("Refine Pipeline — Type Clusters and Subagents"), **Then** the two are fully consistent with no contradictions.

---

### Edge Cases

- What if `responsibilities.md` does not exist? The table should still reflect the correct cluster assignment; the "(if present)" qualifier on the context file must be preserved.
- What if other rows in the routing table are also stale? Only the two explicitly identified rows (`codebase` and `responsibility`) are in scope for this fix.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The routing table in the `/refine` Interface Contract MUST list `codebase` as routing to the `codebase` specialist cluster with context files `codebases.md, identity.md`.
- **FR-002**: The routing table MUST list `responsibility` as routing to the `responsibility` specialist cluster with context files `responsibilities.md (if present), identity.md`.
- **FR-003**: All other rows in the routing table MUST remain unchanged.
- **FR-004**: The updated routing table MUST be consistent with the "Refine Pipeline — Type Clusters and Subagents" entry in `distilled/codebases.md`.

### Technical Constraints

- **Delivery mechanism**: Direct edit to `distilled/interfaces.md` — no command file changes required.
- **Storage format**: Markdown file in version-controlled repository.
- **Scope**: Single table edit in one file. No behaviour changes; documentation fix only.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The routing table in `distilled/interfaces.md` contains zero rows that contradict the routing behaviour documented in `distilled/codebases.md`.
- **SC-002**: A developer reading both files can confirm `codebase` and `responsibility` routing is identical across both sources in under 30 seconds.
- **SC-003**: The fix is a single, reviewable edit with no unintended side effects on other table rows or surrounding content.
