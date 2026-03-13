# Contract: /refine Step 6.5c — Semantic Duplicate Pre-Filter

**Branch**: `005-semantic-dedup-refine` | **Phase**: 1 | **Date**: 2026-03-13

This document specifies the exact behaviour of the new Step 6.5c sub-step and the
modifications to Steps 6 and 11/12 in `refine.md`.

---

## Modified Step 6 — Load Distilled Context (addition)

After the existing Step 6 loads distilled context, identity, and priority config, add:

```
Additionally, attempt to read `<domain-root>/config/similarity.md`.
- If found: parse the **Level** value (conservative | moderate | aggressive).
  Store as `similarity_config = { level: <value>, source: "config/similarity.md" }`.
  If the value is not one of the three allowed values, treat as invalid: fall back to
  moderate, set source: "default", and note: "Invalid similarity level in config/similarity.md
  — using default: moderate."
- If not found: set `similarity_config = { level: "moderate", source: "default" }`.
  Note in session output: "No similarity config found — using default threshold: moderate."
```

---

## New Step 6.5c — Semantic Duplicate Detection

Insert this sub-step after Step 6.5b and before the "Empty batch after pre-filtering" block.

```
### 6.5c — Semantic duplicate detection

Prerequisites: Steps 6.5a and 6.5b complete. `similarity_config` loaded in Step 6.

For each remaining item in the active batch:

1. **Minimum length check**: Count the words in the item's body text. If the count is fewer
   than 20 words, skip this item (pass through without comparison). Record no result.

2. **Similarity comparison**: Using the distilled context already loaded in Step 6, reason
   about whether the item's meaning is substantively already captured in any existing distilled
   entry. Apply the current `similarity_config.level` as the confidence bar:

   | Level         | Filter when…                                                          |
   |---------------|-----------------------------------------------------------------------|
   | conservative  | The item is a near-verbatim restatement of a distilled entry. Paraphrase with different framing, or the same fact in a different context, passes through. |
   | moderate      | The item conveys the same core fact as a distilled entry, even if worded or framed differently. New nuance or additional context passes through. |
   | aggressive    | The item addresses the same topic as a distilled entry, even if it adds some peripheral detail. Only genuinely new knowledge (new claims, new entities, new constraints) passes through. |

3. **If a semantic duplicate is identified**:
   - Set the raw item's `status` field from `raw` to `refined` using the Edit tool.
   - Record in `pre_filter_results`:
     ```
     {
       item_id:          <item id>,
       filter_reason:    "semantic_duplicate",
       matched_entry:    <title or ID of the matched distilled entry>,
       similarity_basis: <brief phrase, e.g. "both describe the retry-on-failure policy">
     }
     ```
   - Remove the item from the active batch.

4. **If no match is found** (or item was below minimum length): leave item in active batch.
   Do not record a pre_filter_results entry for it.

5. **If the comparison is uncertain** (item might partially overlap but is not clearly a
   duplicate at the current level): leave item in active batch. Do not suppress uncertain items.
   The subagent handles these via its `merge_duplicate` autonomous action.
```

---

## Modified Steps 11/12 — Session Output and Changelog (addition)

### Session summary output

After the existing pre-filter summary (exact duplicates + out-of-scope), add:

```
If `pre_filter_results` contains any entries with `filter_reason: "semantic_duplicate"`:

  Semantic duplicates suppressed: <N>
    <item_id> → matched: <matched_entry>
    ...
```

### Changelog entry

After the existing `### Out of Scope` subsection in the session changelog entry, add:

```
If any semantic_duplicate entries exist in `pre_filter_results`:

  ### Semantic Duplicates
  - [semantic_duplicate]: <item_id> → archived
    Matched: <matched_entry>
    Basis: <similarity_basis>
  [repeat for each]
```

If no semantic duplicates were found, omit the `### Semantic Duplicates` subsection entirely.
Do not write an empty section.

---

## Invariants

- Steps 6.5a and 6.5b are unchanged. 6.5c runs after them on the remaining batch.
- A raw item can only be suppressed by one filter stage. Once removed by 6.5a or 6.5b, it does not reach 6.5c.
- 6.5c never escalates to a governed decision. Items that are uncertain at the current level simply pass through to the subagent.
- The empty-batch handler (existing) fires after all three sub-steps complete, as before.
