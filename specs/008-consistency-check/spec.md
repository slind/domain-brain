# Feature Specification: Distilled Entry Consistency-Check Mechanism (FR-024)

**Feature Branch**: `008-consistency-check`
**Created**: 2026-03-16
**Status**: Draft
**Input**: Implement FR-024 — a mechanism that ensures distilled entries describing domain brain's own implementation remain current when corresponding command files or source artefacts change. ADR-016 is the blocking decision; resolving it is the first sub-step.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Detect Stale Distilled Entries (Priority: P1)

A domain brain steward has updated a command file (e.g., revised the `/refine` step flow). They need to discover which distilled entries no longer accurately describe the system, before those entries mislead future queries or governed decisions.

**Why this priority**: Stale distilled entries directly undermine the knowledge base's reliability. This is the core value of FR-024 — a steward who cannot detect staleness cannot maintain an accurate domain brain.

**Independent Test**: Can be fully tested by making a deliberate change to a command file and confirming the consistency-check mechanism surfaces the affected distilled entry as a staleness candidate.

**Acceptance Scenarios**:

1. **Given** a distilled entry that references a source artefact, **When** that artefact has changed since the entry was last updated, **Then** the mechanism surfaces the entry as a staleness candidate.
2. **Given** a distilled entry with no linked source artefact, **When** the consistency check runs, **Then** the entry is not flagged (no false positives on unlinked entries).
3. **Given** a distilled entry whose source artefact has not changed, **When** the consistency check runs, **Then** the entry is not flagged.

---

### User Story 2 — Act on a Staleness Report (Priority: P2)

Having received a list of potentially stale entries, the steward reviews each one and decides: re-capture (update the distilled entry), archive (the entry is no longer relevant), or dismiss (the change was not material).

**Why this priority**: Detection without action is incomplete. The mechanism must connect to the existing governed-decision workflow so the steward can close the loop.

**Independent Test**: Can be fully tested by confirming that a flagged entry can be dismissed, re-captured, or archived — and that acting on one does not affect others.

**Acceptance Scenarios**:

1. **Given** a flagged stale entry, **When** the steward re-captures updated content, **Then** the entry is updated and the staleness flag is cleared.
2. **Given** a flagged stale entry, **When** the steward dismisses it as a non-material change, **Then** the flag is cleared without modifying the distilled entry.
3. **Given** multiple flagged entries, **When** the steward acts on one, **Then** the remaining flagged entries are unaffected.

---

### Edge Cases

- What if a distilled entry references a source artefact that no longer exists? Surface as "source deleted" — a distinct case from staleness.
- What if a distilled entry has no `**Source**` field? Skip it — no source, no change detection possible.
- What if many entries are flagged at once? Present them oldest-first (by last-updated date) to focus effort on the most neglected entries.
- What if the steward wants to acknowledge a review without changing content? A "mark as reviewed" action clears the flag without requiring an edit.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The consistency-check mechanism MUST identify distilled entries whose source artefacts have changed since the entry was last updated.
- **FR-002**: The mechanism MUST NOT flag entries whose source artefacts are unchanged (zero false positives on unchanged sources).
- **FR-003**: The mechanism MUST surface flagged entries with sufficient context for the steward to decide: entry title, source artefact path, and an indication of what changed.
- **FR-004**: The steward MUST be able to dismiss a flagged entry (mark as reviewed without content change).
- **FR-005**: The steward MUST be able to initiate re-capture of a flagged entry's content (handoff to `/capture` or direct edit).
- **FR-006**: The mechanism MUST operate without external services or persistent background processes, consistent with the Extension-First principle.
- **FR-007**: ADR-016 MUST be resolved before implementation begins. The resolved option determines the invocation model (integrated into `/refine`, standalone command, or hook-based).
- **FR-008**: Each consistency-check run MUST append a summary of candidates found and resolutions made to `distilled/changelog.md`.

### Technical Constraints

- **Delivery mechanism**: Claude command file — no standalone app, no server, no daemon.
- **Storage format**: Markdown with YAML frontmatter in a version-controlled repository.
- **External services**: None. Change detection uses only local information (git history or file metadata).
- **ADR-016 dependency**: The invocation model (option A/B/C) is decided by ADR-016, not this spec. This spec defines the *what*; the ADR defines the *how* for the delivery surface.
- **Host AI**: Claude (claude-sonnet-4-6+); built-in tools only.

### Key Entities

- **Staleness Candidate**: A distilled entry whose source artefact has a more recent modification than the entry's last-updated date. Ephemeral — produced during a run, never persisted as a separate file.
- **Staleness Resolution**: The outcome of a steward reviewing a candidate: `reviewed` (dismissed as non-material), `re-captured` (content updated), or `archived` (entry removed). Recorded in `changelog.md`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A steward can identify all distilled entries affected by a set of source changes in a single consistency-check run — zero manual cross-referencing required.
- **SC-002**: Zero false positives: entries with unchanged source artefacts are never surfaced as stale candidates.
- **SC-003**: A steward can complete the full review-and-resolve cycle for a single flagged entry in under 3 minutes.
- **SC-004**: The mechanism runs fully offline — no network access or external service calls.
- **SC-005**: ADR-016 is resolved and recorded in `distilled/decisions.md` before any implementation work begins.

## Assumptions

- Distilled entries eligible for consistency-checking carry a `**Source**` field referencing a command file path. Entries without this field are skipped.
- Change detection uses git commit history or file modification timestamps — whichever the resolved ADR-016 option specifies.
- The steward's action workflow (re-capture, archive, dismiss) reuses the existing `/capture` and `/refine` pipeline; no new write path is introduced.
- At any given time, 10–30 distilled entries are expected to have trackable source links — well within the in-context retrieval tier.
