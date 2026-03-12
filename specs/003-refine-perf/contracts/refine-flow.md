# Contract: /refine Session Flow (Updated)

**Feature**: 003-refine-perf | **Date**: 2026-03-12

Documents the updated step sequence for `/refine` after the P1 and P2 improvements.
Steps 1–6 and 8–13 are unchanged. The changes are: new Step 6.5 (pre-filter) and modified
Step 7 (specialist routing).

---

## Updated Step Sequence

```
Step 1   Locate domain brain root
Step 2   Parse arguments (--limit, --domain)
Step 3   Load type registry (types.yaml)
Step 4   Load raw queue; apply --limit cap
Step 5   Announce session (queue listing)
Step 6   Load distilled context + identity.md
Step 6.5 [NEW] Pre-filter batch                    ← inserted here
Step 7   [MODIFIED] Route to specialist subagents  ← modified
Step 8   Parse merged refine plan
Step 9   Execute autonomous actions (silent)
Step 10  Governed decision loop (one at a time)
Step 11  Session end
Step 12  Append changelog entry
Step 13  Session summary
```

---

## Step 6.5 — Pre-Filter Batch (new)

**Inputs**: raw batch (from Step 4), all distilled file content (from Step 6), identity.md
Out-of-scope list (from Step 6).

**Processing**:

1. **Exact-duplicate check**: For each raw item, compare its body text (whitespace-normalised)
   against the body content of all distilled entries. If a match is found:
   - Set item status to `refined`.
   - Record a `PreFilterResult { filter_reason: "duplicate", matched_file: <file> }`.
   - Remove item from the batch.

2. **Out-of-scope check**: For each remaining item, evaluate title + body against the
   Out-of-scope list using high-confidence semantic judgment (same bar as the subagent's
   `out_of_scope` autonomous action rule). If a high-confidence match is found:
   - Set item status to `refined`.
   - Record a `PreFilterResult { filter_reason: "out_of_scope", matched_term: <term> }`.
   - Remove item from the batch.

3. If the remaining batch is empty after pre-filtering: skip Steps 7–10, go directly to
   Step 11. Output a note explaining all items were filtered before subagent invocation.

**Outputs**: reduced batch (items not filtered), list of PreFilterResults.

---

## Step 7 — Route to Specialist Subagents (modified)

**Inputs**: reduced batch from Step 6.5, distilled context (from Step 6), type registry.

**Processing**:

1. **Group by cluster**: Assign each item to a TypeClusterBatch using the type routing table
   (see data-model.md). Items of unrecognised types → generalist cluster.

2. **Determine context per cluster**:
   - `requirements` cluster: load requirements.md + decisions.md + identity.md
   - `interfaces` cluster: load interfaces.md + decisions.md + identity.md
   - `decisions` cluster: load decisions.md + identity.md
   - `generalist` cluster: load all distilled files + identity.md (existing behaviour)

3. **Invoke specialists**: For each non-empty cluster, invoke the refine subagent (Agent tool,
   subagent_type=general) with that cluster's items and context. Multiple clusters may be
   invoked concurrently.

4. **Merge plans**: Concatenate the AUTONOMOUS_ACTIONS and GOVERNED_DECISIONS from all
   returned SpecialistPlans into a single MergedRefinePlan.

**Outputs**: MergedRefinePlan consumed by Step 8.

---

## Changelog Entry Additions

Step 12 must also record pre-filter results. Add a new subsection before "Autonomous actions":

```markdown
### Pre-filtered (host)
- [duplicate]: <item_id> → exact match in <distilled_file>
- [out_of_scope]: <item_id> → matched term "<term>"
...
```

Omit this subsection if no items were pre-filtered.

---

## Session Summary Additions

Step 13 must report pre-filtered items:

```
Autonomous: <N> items processed
  ✓ Pre-filtered <n> duplicates (host)
  ✓ Pre-filtered <n> out-of-scope (host)
  ✓ Merged <n> duplicates (subagent)
  ✓ Routed <n> items to distilled files
  ✓ Classified <n> 'other' items
  ✓ Split <n> multi-type items
```

---

## Invariants (unchanged)

- The subagent MUST NOT write files directly.
- Governed decisions are presented one at a time.
- Every governed decision includes option Z (flag as unresolved).
- All pre-filtered items have their status set to `refined` by the host (not the subagent).
- Pre-filtering never removes ambiguous items — only high-confidence matches.
