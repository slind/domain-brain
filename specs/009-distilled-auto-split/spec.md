# Feature Specification: Distilled File Auto-Splitting

**Feature Branch**: `009-distilled-auto-split`
**Created**: 2026-03-16
**Status**: Draft

## Clarifications

### Session 2026-03-16

- Q: Where should split-detection and proposal logic be delivered — integrated into `/refine` or as a standalone command? → A: Integrated into `/refine` as a pre-processing phase (Option A).
- Q: How should sub-files be named when a split is executed? → A: `{base}-{group-label}-{n}.md` — group label derived from entry type or steward-provided name, plus a sequential number for disambiguation (e.g., `requirements-archived-1.md`).
- Q: What should be the default grouping axis when proposing a split? → A: Recency — recent/active entries in one sub-file, older/archived entries in another (Option B).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Detect an Oversized Distilled File (Priority: P1)

A domain steward runs `/refine` with a backlog to process. Before processing any raw items, the `/refine` pre-processing phase detects that one or more distilled files have grown beyond the reliable-retrieval threshold. It surfaces a governed decision proposing a split plan for the affected file, pausing until the steward confirms or dismisses the proposal.

**Why this priority**: Without detection, the refine pipeline silently adds entries to an already-oversized file, degrading query quality. Detection is the minimal viable capability for this feature.

**Independent Test**: Can be fully tested by seeding a distilled file past the threshold, running `/refine`, and confirming the system surfaces a split proposal before processing any new items.

**Acceptance Scenarios**:

1. **Given** a distilled file with entry count above the threshold, **When** `/refine` is invoked, **Then** the system surfaces a split proposal as a governed decision before processing any queued raw items.
2. **Given** all distilled files below threshold, **When** `/refine` is invoked, **Then** no split proposal is surfaced and the session proceeds normally.
3. **Given** multiple oversized files, **When** `/refine` is invoked, **Then** each oversized file is surfaced as a separate governed decision, one at a time (not batched).

---

### User Story 2 — Confirm and Execute a Split (Priority: P2)

The steward reviews the system's proposed file split — showing which entries would go into each sub-file — and confirms the restructuring. The system executes the split: creates the new sub-files, retires the original oversized file, and appends a changelog entry. The refine session then continues processing the raw queue.

**Why this priority**: Confirmation and execution complete the governed-action loop. Without this, detection alone provides no remediation path.

**Independent Test**: Can be fully tested by accepting a split proposal and verifying the resulting sub-files contain the correct entries and the changelog records the action.

**Acceptance Scenarios**:

1. **Given** a split proposal, **When** the steward confirms, **Then** the system creates the proposed sub-files with entries distributed as proposed.
2. **Given** the split is executed, **Then** the original oversized file is replaced or retired, not left as a duplicate alongside the new sub-files.
3. **Given** the split is executed, **Then** a changelog entry is appended recording the split action, the source file, and the resulting sub-files.
4. **Given** the split is executed, **Then** the refine session resumes processing the raw queue without requiring a new invocation.

---

### User Story 3 — Dismiss or Flag a Split Proposal (Priority: P3)

The steward chooses not to split at this time — either dismissing the proposal (skip for now) or flagging it as an unresolved decision. The session continues without splitting. The same file will be flagged again in the next session until the steward acts.

**Why this priority**: Governed actions must always be dismissible. This user story ensures the feature cannot block the refine workflow.

**Independent Test**: Can be fully tested by dismissing a split proposal and confirming the session proceeds and the oversized file is unchanged.

**Acceptance Scenarios**:

1. **Given** a split proposal, **When** the steward chooses "skip for now", **Then** the refine session continues and no files are modified.
2. **Given** a split proposal, **When** the steward chooses "flag as unresolved" (option Z), **Then** an open ADR is created in `decisions.md` and the session continues.
3. **Given** the same oversized file at the next `/refine` invocation, **Then** the split proposal is surfaced again (dismissal is not permanent).

---

### Edge Cases

- What if the file is oversized but contains only a single entry? — Split cannot be proposed; system should warn the steward that the entry itself may need to be condensed, not the file split.
- What if the proposed split would produce a sub-file with zero entries? — System MUST NOT propose splits that result in empty files; it must re-partition until all sub-files have at least one entry.
- What if the steward wants a different grouping than the system proposed? — The system accepts natural language re-grouping instructions as part of the governed decision response and revises the proposal.
- What if two distilled files both exceed the threshold simultaneously? — Each is presented as a separate governed decision, sequentially.
- What if a sub-file created by a prior split later grows past the threshold? — It is subject to the same detection on the next refine session.
- What if all entries in the file have the same `**Captured**` date? — Recency grouping falls back to the `**Type**` field as a secondary axis; steward may override.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `/refine` command MUST include a pre-processing phase that detects when any distilled file exceeds the defined entry-count threshold, before processing raw items.
- **FR-002**: For each oversized file detected, the system MUST generate a split proposal grouping entries by recency (active/recent vs. older/archived) as the default axis. Sub-file names MUST follow the `{base}-{group-label}-{n}.md` convention (e.g., `requirements-active-1.md`, `requirements-archived-1.md`). The proposal MUST include a stated grouping rationale.
- **FR-003**: Each split proposal MUST be surfaced as a governed decision, presented one at a time (not batched), consistent with the existing single-decision-per-prompt constraint.
- **FR-004**: Every split governed decision MUST include "flag as unresolved" as an option, which creates an open ADR in `decisions.md`.
- **FR-005**: The steward MUST be able to accept, dismiss, or redirect a split proposal (providing a different grouping) within the governed decision exchange.
- **FR-006**: When the steward confirms a split, the system MUST create the sub-files, retire the original, and update the changelog before resuming the raw item queue.
- **FR-007**: The executed split MUST be recorded in `distilled/changelog.md` with: source file name, resulting sub-file names, entry counts per sub-file, and steward's rationale (or "no rationale provided").
- **FR-008**: After a confirmed split is executed, the refine session MUST resume processing the remaining raw queue within the same invocation.
- **FR-009**: The entry-count threshold MUST be configurable. A sensible default MUST apply when no configuration is present.
- **FR-010**: If a file cannot be meaningfully split (e.g., single entry), the system MUST surface a warning rather than a split proposal, and continue the session without blocking.

### Technical Constraints

- **Delivery mechanism**: Integrated into `/refine` as a pre-processing phase — runs automatically before raw items are processed; no separate command invocation required.
- **Command surface**: Extends `.claude/commands/refine.md` only. No new commands or storage formats introduced.
- **Storage format**: Markdown files with YAML frontmatter in version-controlled repository. Sub-files follow the same naming and header conventions as existing distilled files.
- **Host AI**: Claude (claude-sonnet-4-6+); built-in tools only (Read, Write, Edit, Glob, Bash for git).
- **Governed action pattern**: All file writes require steward confirmation consistent with FR-009 through FR-015. No silent file creation or deletion.

### Key Entities

- **Split Proposal**: The system's suggested partition of a distilled file's entries into named sub-files. Contains: source file path, proposed sub-file names, entry-to-sub-file mapping, grouping rationale. Ephemeral — exists only during the governed decision exchange; never written to disk.
- **Threshold Configuration**: Per-type or global entry-count limit beyond which a file is oversized. Consulted at the start of the `/refine` pre-processing phase.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A steward running `/refine` against an oversized distilled file is shown a split proposal before any raw items are processed — zero sessions where oversized files silently grow further.
- **SC-002**: The steward can confirm, dismiss, or redirect a split proposal in a single exchange (at most one clarifying follow-up turn per proposal).
- **SC-003**: After a confirmed split, the sub-files together contain exactly the same entries as the original file — zero entries lost or duplicated.
- **SC-004**: Every executed split is recorded in the changelog with source file, sub-file names, and rationale — 100% traceability.
- **SC-005**: Dismissing a split proposal does not block the refine session — raw item processing continues within the same invocation.

---

## Assumptions

- The primary splitting axis is entry count, not file size in bytes. Entry count is a more stable and intent-aligned metric for distilled Markdown files.
- Default threshold is approximately 50 entries per file; the exact value will be calibrated during implementation against context-window constraints.
- The default grouping axis is recency: recent/active entries form one sub-file; older/archived entries form another. This directly addresses the root cause of file growth (accumulation of historical entries) while keeping the most queried content in a compact, focused file. The steward may override the grouping in natural language.
- Sub-file naming follows the convention `{base}-{group-label}-{n}.md` (e.g., `requirements-archived-1.md`): the group label is derived from the dominant entry type or a steward-provided name; the sequential number disambiguates when multiple sub-files share a label.
- The split detection phase runs at the start of `/refine`, not on every file write — real-time monitoring is out of scope.
