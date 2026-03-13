# Contract: /query Extension — task-management Mode

**Feature**: `004-backlog-lifecycle`
**File**: `.claude/commands/query.md` (modified)
**Date**: 2026-03-12

---

## Change Summary

Add a sixth reasoning mode `task-management` to the existing five-mode classification table in `/query`. No structural changes to Steps 1–2 or Steps 4–9. Two table rows added (Step 3a, Step 3b). One rule clarification added (no second-stage retrieval for this mode).

---

## Step 3a: Updated Mode Classification Table

Add the following row to the existing table:

| Mode | Trigger patterns |
|---|---|
| `task-management` | "what's on the backlog", "open tasks", "what's open", "in progress", "what should I work on", "what should we work on", "what's done", "backlog status", "what are we working on", "what's next" |

**Classification rule**: If the question contains any of these phrases, classify as `task-management`. This mode takes priority over `gap-analysis` (the default fallback) when backlog-specific language is used.

---

## Step 3b: Updated Candidate Files Table

Add the following row:

| Mode | Candidate files |
|---|---|
| `task-management` | `backlog.md` only |

**Important**: No other distilled files are loaded for this mode (FR-019). The `task-management` mode is narrowly scoped to backlog state — it does not surface requirements, interfaces, or decisions unless the user explicitly asks a compound question.

---

## Second-Stage Retrieval Rule

Add to Step 7 condition: `task-management` mode never triggers second-stage chunk retrieval (same rule as `gap-analysis` and `diagram`).

---

## Response Format for task-management Mode

The answer body for `task-management` responses follows this structure:

```
## Backlog Status

▶ In Progress (N):
  - <title> [in-progress]

## High Priority (N):
  - <title>
  - <title>

## Medium Priority (N):
  - <title>
  - <title>
  ... (M more)

## Low Priority (N):
  - <title>
```

If the question is specifically about in-progress work ("what are we working on?"), highlight only the in-progress section and omit the full priority listing.

If the question is specifically about done work ("what's done?"), return only the Done section entries.

---

## No Normative Change Required

This extension is additive — it adds a new mode to an existing dispatch table. No existing mode behavior changes. The `task-management` mode does not surface open ADRs (Step 6 behavior) — it is scoped purely to backlog state.
