# Feature Specification: Semantic Duplicate Detection in /refine

**Feature Branch**: `005-semantic-dedup-refine`
**Created**: 2026-03-13
**Status**: Draft
**Input**: Upgrade the host pre-filtering stage in `/refine` from byte-for-byte exact match to semantic similarity detection, so that near-duplicate and paraphrased items are eliminated before reaching a subagent rather than consuming a governed decision.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Near-Duplicates Filtered Before Subagent (Priority: P1)

A user runs `/refine` on a raw queue that includes several items which paraphrase or partially overlap with knowledge already distilled. Today those items all reach the subagent and each one consumes either an autonomous routing decision or a governed human decision. With this feature, the host scores each incoming item against existing distilled entries; items above the similarity threshold are identified as semantic duplicates and removed from the subagent batch automatically — the same way exact duplicates are handled today.

**Why this priority**: This is the core value of the feature. Every near-duplicate that reaches a subagent wastes a governed decision slot (or at minimum a token budget). Catching them at host pre-filter time is the highest-leverage intervention and can be built and validated without touching any subagent logic. It directly improves the SC-002 autonomy target toward the 90%+ range.

**Independent Test**: Prepare a raw queue where at least 4 of 10 items are paraphrases or semantic rewrites of existing distilled entries. Run `/refine`. Verify that all 4 paraphrased items are identified and removed before the subagent is invoked, that the subagent receives at most 6 items, and that the session output names each removed item and the distilled entry it matched.

**Acceptance Scenarios**:

1. **Given** a raw item that is a close paraphrase of an existing distilled entry, **When** `/refine` runs, **Then** the host identifies it as a semantic duplicate, excludes it from the subagent batch, and records it as `[semantic-duplicate: <matched-entry-id>]` in the session output.
2. **Given** a raw item that mentions the same fact as a distilled entry but using entirely different words, **When** `/refine` runs, **Then** the host identifies the semantic overlap and excludes the item before any subagent is invoked.
3. **Given** a raw item that is genuinely new knowledge with no significant overlap to any distilled entry, **When** `/refine` runs, **Then** the item passes through pre-filtering unchanged and reaches the subagent as normal.
4. **Given** a raw item that is an exact byte-for-byte duplicate of a distilled entry, **When** `/refine` runs, **Then** the existing exact-duplicate pre-filter still catches it (no regression from Feature 003 FR-001).

---

### User Story 2 - Configurable Similarity Threshold (Priority: P2)

A domain owner wants to tune how aggressively near-duplicates are suppressed. A low threshold means only very close paraphrases are filtered; a higher threshold catches more loosely-related items. The threshold is stored in the domain's config directory and can be changed without modifying any command file.

**Why this priority**: The right threshold varies by domain maturity and knowledge density. A new domain brain with sparse distilled content needs a conservative threshold to avoid accidentally discarding genuinely distinct items; a mature domain can afford a more aggressive one. Making this configurable prevents the feature from being a blunt instrument and lets domain owners adapt it over time.

**Independent Test**: Set the similarity threshold to a known value (e.g., conservative). Run `/refine` with items at various overlap levels. Adjust the threshold to aggressive. Re-run the same items. Verify that more items are filtered at the aggressive setting and fewer at the conservative setting, with no command-file changes required.

**Acceptance Scenarios**:

1. **Given** a similarity threshold configured in `config/`, **When** `/refine` runs, **Then** the host uses that threshold for all pre-filter comparisons in the session.
2. **Given** no similarity threshold configured, **When** `/refine` runs, **Then** the host applies a built-in default threshold and notes in session output that the default is in use.
3. **Given** a threshold value outside the valid range, **When** `/refine` runs, **Then** the host rejects the config value, falls back to the default, and warns the user.

---

### User Story 3 - Semantic Duplicate Outcomes Visible in Changelog (Priority: P3)

After a `/refine` session, a domain owner wants to understand what was suppressed and why. The session changelog already records exact-duplicate and out-of-scope filtering outcomes; semantic duplicate outcomes should appear in the same place, clearly distinguished from other filter reasons, so that users can audit the feature's behaviour and spot if the threshold needs adjustment.

**Why this priority**: Auditability is a core principle of the domain brain system (governed decisions, changelog entries). If semantic duplicates are silently suppressed with no trace, users lose confidence in the pipeline and cannot diagnose threshold problems. This is lower priority than the core filtering behaviour (P1, P2) but necessary for the feature to be trustworthy.

**Independent Test**: Run `/refine` with a batch containing semantic duplicates. Open `distilled/changelog.md`. Verify a `### Semantic Duplicates` (or equivalent) subsection exists in the session entry, listing each suppressed item, the matched distilled entry, and the similarity basis. Verify exact-duplicate and out-of-scope outcomes continue to be recorded as before.

**Acceptance Scenarios**:

1. **Given** one or more semantic duplicates were suppressed in a `/refine` session, **When** the session completes, **Then** each suppressed item is recorded in the session changelog entry with the matched distilled entry reference.
2. **Given** a `/refine` session where no semantic duplicates were found, **When** the session completes, **Then** the changelog entry does not add a semantic-duplicate section (no empty noise).
3. **Given** a session that suppresses both exact duplicates and semantic duplicates, **When** the changelog is written, **Then** the two categories appear separately and are clearly labelled.

---

### Edge Cases

- What if a raw item is semantically similar to two or more distilled entries? The host records the closest match and suppresses the item once; both matched entries may be noted in the session output.
- What if all items in a batch are identified as semantic duplicates? The session completes immediately with a full suppression summary; no subagent is invoked.
- What if the distilled knowledge base is empty or very sparse (new domain)? Similarity scoring finds no matches; all items pass through to the subagent as normal.
- What if an item's content is too short to meaningfully compare (e.g., a one-word note)? The host skips similarity scoring for that item and passes it through; a minimum-length threshold prevents false positives on micro-items.
- What if the similarity comparison itself fails mid-batch (e.g., timeout or error)? The failing item passes through to the subagent as a safe fallback; the failure is noted in session output but does not abort the session.

## Requirements *(mandatory)*

### Functional Requirements

**Semantic Pre-Filtering (FR-001 – FR-006)**

- **FR-001**: Before invoking any subagent, the `/refine` host MUST compare each raw item against all existing distilled entries for semantic similarity, extending (not replacing) the existing exact-duplicate check from Feature 003 FR-001.
- **FR-002**: The host MUST apply a configurable similarity threshold when classifying an item as a semantic duplicate; items scoring at or above the threshold MUST be excluded from the subagent batch.
- **FR-003**: Semantic duplicate items MUST be accounted for in the session output with: (a) the suppressed item's identifier, (b) the matched distilled entry reference, and (c) the basis for the match.
- **FR-004**: Items scoring below the similarity threshold MUST pass through to the subagent unchanged; the feature MUST NOT increase the false-negative rate for genuinely new knowledge.
- **FR-005**: The minimum content length for similarity comparison MUST be enforced; items below the minimum length MUST be passed through without similarity scoring.
- **FR-006**: Similarity comparison MUST be performed solely by the AI host's in-context reasoning; no external embedding APIs or external service calls are permitted. This preserves the no-external-service constraint established in Feature 003 Design Assumptions.

**Threshold Configuration (FR-007 – FR-009)**

- **FR-007**: A similarity threshold value MUST be readable from the domain's `config/` directory; the config key and file path MUST be documented in the feature's data model.
- **FR-008**: When no threshold is configured, the host MUST apply a documented default value and surface a visible notice in the session output.
- **FR-009**: An invalid or out-of-range threshold value MUST cause the host to fall back to the default and warn the user; it MUST NOT abort the session.

**Changelog Integration (FR-010 – FR-012)**

- **FR-010**: Every `/refine` session that suppresses one or more semantic duplicates MUST append a `### Semantic Duplicates` subsection to the session's changelog entry in `distilled/changelog.md`.
- **FR-011**: Sessions with zero semantic duplicates MUST NOT add a semantic-duplicate section to the changelog entry (no empty sections).
- **FR-012**: Semantic duplicate records in the changelog MUST be formatted consistently with existing exact-duplicate and out-of-scope records.

### Technical Constraints

- **Delivery mechanism**: Enhancement to the existing `/refine` Claude command file — no new command surfaces introduced.
- **Command surface**: `/refine` (modified); no new skills or commands.
- **Storage format**: Similarity threshold stored as a config value in a Markdown or YAML file under `domain/config/`; changelog entries in existing `distilled/changelog.md` format.
- **Host AI**: Claude (claude-sonnet-4-6+); multi-host support deferred per Feature 001 constraints.
- **Scope boundary**: This feature modifies the host pre-filtering stage only. Subagent logic, governed-decision flow, and distilled-file write operations are unchanged.

### Key Entities

- **Raw item**: An unprocessed knowledge capture in `distilled/raw-queue.md` awaiting `/refine`; has an identifier and content body.
- **Distilled entry**: An existing processed knowledge item in any `distilled/` file; is the corpus against which incoming raw items are compared.
- **Similarity score**: A measure of semantic overlap between a raw item and a distilled entry; compared against the threshold to determine suppression.
- **Similarity threshold**: A configurable value stored in `domain/config/` that sets the suppression boundary; items at or above this value are treated as semantic duplicates.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The proportion of raw items autonomously resolved (without a governed human decision) increases by at least 15 percentage points above the Feature 003 baseline, pushing the overall autonomy rate toward the 90%+ target stated in the backlog item.
- **SC-002**: Zero semantic duplicate items reach the subagent when the similarity threshold is correctly configured — confirmed by running a test batch where all near-duplicate items are known in advance.
- **SC-003**: A domain owner can adjust the similarity threshold and observe a measurable change in suppression behaviour on the next `/refine` run, without modifying any command file.
- **SC-004**: Every `/refine` session output provides a complete account of all suppressed items — exact duplicates, out-of-scope items, and semantic duplicates — so that no item silently disappears from the pipeline.

## Assumptions

- The domain's distilled knowledge base is small enough to compare against in a single `/refine` session context without hitting context-length limits (consistent with the ≤500-entry scope boundary established in Feature 001; the hosted-index tier for larger domains is a separate backlog item).
- The similarity comparison will be performed by the AI host reasoning in-context, unless FR-006 is resolved to permit an external embedding service.
- "Semantic similarity" is interpreted as meaning-level overlap sufficient that the incoming item would add no new distilled knowledge — not surface-level word overlap.
- The existing pre-filter accounting structure from Feature 003 (archiving filtered items with a reason) is extended, not replaced.
