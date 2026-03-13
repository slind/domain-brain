# Research: Semantic Duplicate Detection in /refine

**Branch**: `005-semantic-dedup-refine` | **Phase**: 0 | **Date**: 2026-03-13

---

## Decision 1: Similarity Comparison Mechanism

**Decision**: AI host (Claude) performs similarity comparison in-context. No external embedding APIs.

**Rationale**: Resolved in spec FR-006 (user-confirmed Option A). Claude already loads the full distilled context in Step 6 before the pre-filter stage runs. This means the AI host already has both the incoming raw item and all distilled entries in its context window — semantic comparison is a natural extension of the reasoning it already performs. No new dependencies, no API keys, no latency from external calls.

**Alternatives considered**:
- External embedding API (e.g., OpenAI, Anthropic): Higher recall for large corpora, but introduces external service dependency and breaks the no-external-service constraint. Deferred.
- Local embedding model: Better accuracy than in-context reasoning for very large corpora but requires a model runtime. Conflicts with the no-binary, no-server principle. Deferred.

**Constraint noted**: In-context comparison is bounded by the context window. For domains approaching the 500-entry limit, comparison quality may degrade. This is acceptable — the hosted vector index feature (backlog item 2) handles the >500-entry scaling tier.

---

## Decision 2: Threshold Representation

**Decision**: Named levels (`conservative`, `moderate`, `aggressive`) rather than a numerical score.

**Rationale**: Numerical similarity thresholds (e.g., cosine similarity ≥ 0.85) are meaningful when computed by an embedding model that produces consistent, calibrated scores. When similarity is determined by LLM in-context reasoning, the "score" is not a stable number — it is a judgment. Named levels map directly to the behavioral description the host uses when making that judgment, making the config more meaningful and auditable.

| Level | Behavioral definition | Default? |
|-------|----------------------|----------|
| `conservative` | Filter only when the raw item is a near-verbatim restatement of a distilled entry; paraphrase with different framing passes through | No |
| `moderate` | Filter when the raw item conveys the same core fact as a distilled entry, even if framed or worded differently; new nuance or context passes through | **Yes** |
| `aggressive` | Filter when the raw item addresses the same topic as a distilled entry, even if it adds some peripheral detail; only genuinely new knowledge passes through | No |

The `moderate` default is chosen to balance recall (not missing new knowledge) against precision (not burdening the subagent with paraphrased items). Domain owners who have already established a dense, mature knowledge base can raise to `aggressive`; owners of sparse new domains should use `conservative`.

**Alternatives considered**:
- Numerical 0.0–1.0 scale: Rejected — not meaningful for in-context LLM reasoning.
- Boolean on/off: Too blunt; removes ability to tune false-positive rate.

---

## Decision 3: Minimum Content Length

**Decision**: Items shorter than 20 words (approximately 100 characters) are passed through without semantic comparison.

**Rationale**: Very short items (single phrases, names, or labels) are susceptible to false-positive matches — "deploy service" could superficially match many different distilled entries. The 20-word floor ensures the host has enough content to make a reliable similarity judgment. Items below the floor are passed to the subagent unchanged.

**Note**: The minimum applies only to semantic comparison (6.5c). Exact-duplicate detection (6.5a) continues to apply to all items regardless of length.

---

## Decision 4: Changelog Record Format

**Decision**: Extend the existing `pre_filter_results` structure with a new `filter_reason: "semantic_duplicate"` value. Semantic duplicate outcomes appear in a separate `### Semantic Duplicates` subsection of the session changelog entry.

**Rationale**: Consistent with Feature 003's pattern of recording pre-filter outcomes. Keeping semantic duplicates in a distinct subsection (rather than mixing with exact-duplicate records) makes it easy to audit the feature's behaviour and diagnose threshold problems. The subsection is omitted entirely when no semantic duplicates were found (FR-011), maintaining clean changelogs for unaffected sessions.

**Record fields added**:
- `filter_reason: "semantic_duplicate"` (new value in existing enum)
- `matched_entry: string` — the title or ID of the distilled entry that was matched
- `similarity_basis: string` — a brief phrase explaining why the host considered them semantically equivalent (e.g., "both describe the TCP-based path-finding algorithm")

---

## Decision 5: Integration Point in refine.md

**Decision**: Insert Step 6.5c between Step 6.5b (out-of-scope filter) and the existing "Empty batch after pre-filtering" handler. Step 6 is extended to optionally read `config/similarity.md`.

**Rationale**: Step 6.5 already functions as a sequential filter chain. Adding 6.5c as the last filter in that chain maintains the existing flow without restructuring. The empty-batch handler naturally follows all three filters. No other steps need modification except the changelog format in Steps 11/12.
