# Contract: /refine Extension — Priority Assignment for Task Items

**Feature**: `004-backlog-lifecycle`
**File**: `.claude/commands/refine.md` (modified)
**Date**: 2026-03-12

---

## Change Summary

Two changes to `/refine`:

1. **Updated task entry format** in SUBAGENT INSTRUCTIONS — REFINE AGENT: add `**Status**: open` and `**Priority**: <guidelines-assigned>` to the distilled file entry format for task-typed items.
2. **Priority assignment step** in the generalist subagent instructions: when routing a task item, the subagent reads `config/priorities.md` (if available) and assigns an appropriate priority value; otherwise defaults to `medium`.

---

## Change 1: Updated Task Entry Format

In the SUBAGENT INSTRUCTIONS — REFINE AGENT section, under "Distilled file entry format", add a task-specific note:

**Current format**:
```markdown
## <Title>
**Type**: <type>
**Captured**: <YYYY-MM-DD from raw item>
**Source**: <raw item id>

<Body content, summarised if needed>

---
```

**Updated format for task items**:
```markdown
## <Title>
**Type**: task
**Status**: open
**Priority**: <high | medium | low>
**Captured**: <YYYY-MM-DD from raw item>
**Source**: <raw item id>

<Body content, summarised if needed>

---
```

The `**Status**` field is always `open` for new items. The `**Priority**` field is assigned by the subagent based on guidelines (or defaults to `medium`).

---

## Change 2: Priority Assignment in Generalist Subagent

Add the following instruction to the SUBAGENT INSTRUCTIONS block, in the section covering `route_and_summarise` actions for task items:

**When routing a task-typed item to `backlog.md`**:

1. Check whether the host has loaded `config/priorities.md` content into the context (the host should pass it alongside the distilled files).
2. If guidelines are present: evaluate the item's title and body against the guidelines. Assign the priority that best matches the applicable rule. Use `high` / `medium` / `low`.
3. If no guidelines are present, or if the item does not clearly match any rule: assign `medium`.
4. Record the assignment in the `content` field of the `route_and_summarise` action alongside the entry text.

**Host change (Step 6 — Load distilled context)**:

Add a step: after loading distilled files, attempt to read `<domain-root>/config/priorities.md`. If it exists, pass its content to the generalist subagent as `priority_guidelines`. If it does not exist, pass `priority_guidelines: null`.

---

## No Change to Governed Decision Flow

Priority assignment at refinement time is autonomous (not a governed decision) — it is equivalent to the subagent choosing a routing target. The assignment is immediately visible in the backlog entry and can be changed via `/triage` at any time. This is a classification decision, not a normative content decision.

---

## Impact on Existing Behavior

- Items of type other than `task` are unaffected.
- The generalist cluster routing for `task` items already handles `route_and_summarise` actions; this change only adds two fields to the output content and one priority-inference step.
- If the priorities file changes between refinement sessions, new items will get updated assignments, but previously refined items are unaffected (they must be re-ranked via `/triage`).
