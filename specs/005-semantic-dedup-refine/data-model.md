# Data Model: Semantic Duplicate Detection in /refine

**Branch**: `005-semantic-dedup-refine` | **Phase**: 1 | **Date**: 2026-03-13

This feature introduces one new optional config file and extends two existing in-memory
entities from Feature 003. No new distilled file types are introduced; no existing distilled
file schemas change.

---

## New Persistent Entity

### `config/similarity.md` (optional)

Per-domain configuration for semantic duplicate detection. If absent, the host applies the
`moderate` default and surfaces a notice in the session output.

```markdown
# Similarity Configuration

## Threshold

**Level**: moderate

<!-- Allowed values: conservative | moderate | aggressive
     conservative — filter only near-verbatim restatements
     moderate     — filter same core fact, different wording (DEFAULT)
     aggressive   — filter same topic, even with peripheral additions -->
```

**Governance**: This is a non-normative config file. Domain owners may edit it directly
without a governed decision. Changes take effect on the next `/refine` invocation.

---

## Extended In-Memory Entities (Feature 003 entities, extended)

### PreFilterResult (extended)

Feature 003 definition gains a new `filter_reason` value and two new optional fields.

```
PreFilterResult {
  item_id:          string          // raw item id
  filter_reason:    "duplicate"
                  | "out_of_scope"
                  | "semantic_duplicate"   // NEW in Feature 005
  matched_file:     string | null   // distilled file where duplicate was found (exact dupe)
  matched_term:     string | null   // out-of-scope term matched
  matched_entry:    string | null   // NEW — title/ID of distilled entry for semantic match
  similarity_basis: string | null   // NEW — brief phrase explaining the semantic overlap
}
```

No changes to the on-disk raw item or distilled entry schemas. PreFilterResult is session-scoped
in-memory state, not persisted.

---

## Changelog Format Extension

The session changelog entry in `distilled/changelog.md` gains a new optional subsection.
Existing subsections (`### Exact Duplicates`, `### Out of Scope`) are unchanged.

```markdown
## YYYY-MM-DD — Refine Session

### Exact Duplicates
- [duplicate]: <item_id> → archived (matched: <distilled_file>)

### Out of Scope
- [out_of_scope]: <item_id> → archived (matched term: <term>)

### Semantic Duplicates       ← NEW — omit entirely if count is zero
- [semantic_duplicate]: <item_id> → archived
  Matched: <matched_entry>
  Basis: <similarity_basis>

### Governed Decisions
...

---
```

The `### Semantic Duplicates` subsection MUST be omitted when no semantic duplicates were
found in the session (FR-011). When present, it appears after `### Out of Scope` and before
`### Governed Decisions`.

---

## SimilarityConfig (new in-memory entity)

Loaded by the host in Step 6. Session-scoped.

```
SimilarityConfig {
  level:    "conservative" | "moderate" | "aggressive"
  source:   "config/similarity.md" | "default"
}
```

`source: "default"` triggers the session-output notice: "No similarity config found —
using default threshold: moderate."
