# Quickstart: Backlog Lifecycle Support

**Feature**: `004-backlog-lifecycle`
**Date**: 2026-03-12

This guide walks through the five core workflows introduced by this feature.

---

## Prerequisites

- `distilled/backlog.md` exists and contains at least one entry with `**Status**` and `**Priority**` fields (populated by `/refine` after this feature is deployed, or by migration of existing entries).
- The `/triage` command file is installed at `.claude/commands/triage.md`.

---

## Workflow 1: View and Prioritise the Backlog

```
/triage
```

The command displays all open items grouped by priority. Items are numbered for reference.

To change a priority directly:

```
set 3 to high
```

Item 3's `**Priority**` field updates immediately. No confirmation needed for direct assignment.

---

## Workflow 2: AI-Assisted Re-prioritisation

From a `/triage` session, give a natural language hint:

```
elevate anything related to enterprise integration
```

The system invokes a subagent that reads all open items plus your hint, then presents a proposal table:

```
Proposed priority changes (2 items):

  #  Title                                  Current → Proposed
  2  Enterprise API Integration for /seed   medium  → high
  7  Additional Specialist Subagents        medium  → high

Apply these changes? (yes / no)
```

Say "yes" to apply, "no" to cancel. Nothing is written until you confirm.

---

## Workflow 3: Start Work on an Item

From a `/triage` session:

```
start 2
```

The system marks item 2 `in-progress` and shows you what will be passed to the spec workflow:

```
Item 2 marked in-progress: "Enterprise API Integration for /seed"

Will start spec with:
  "Extend /seed to read directly from Confluence, Notion, Jira..."

Ready to start speccing? (yes / not yet)
```

Say "yes" and the spec workflow launches automatically with the item description pre-populated.

---

## Workflow 4: Close a Completed Item

From a `/triage` session:

```
close 2
```

The system asks for a brief rationale:

```
One-line rationale for closing "Enterprise API Integration for /seed"?
```

Provide it (e.g., "Spec started as feature 005, implementation complete"), and the item is marked `done`, moved to the `## Done` section, and a changelog entry is appended.

---

## Workflow 5: Set Up Priority Guidelines

From a `/triage` session:

```
update guidelines
```

If no guidelines exist, the system presents a template and asks you to fill it in one exchange:

```
No guidelines file found. Here's a starter template — describe what should be elevated,
kept at medium, or deferred to low:

## Elevate to High
- (your rules here)

## Keep at Medium
- (your rules here)

## Defer to Low
- (your rules here)
```

Once written, `config/priorities.md` persists and future `/refine` sessions use it to assign initial priorities to new task items automatically.

To apply updated guidelines to the existing backlog:

```
apply guidelines
```

The system proposes a full re-ranking for review before applying.

---

## Workflow 6: Query Backlog Without /triage

For read-only status checks, use `/query` directly:

```
/query what should we work on next?
/query what's in progress?
/query what's done?
```

The query engine classifies these as `task-management` mode and returns a prioritised view of `backlog.md` without launching a full triage session.

---

## Key Commands Reference

| What you want to do | How |
|---|---|
| See the full backlog | `/triage` |
| Change one item's priority | `/triage` → "set N to high/medium/low" |
| Re-rank by topic | `/triage` → "elevate <topic>" |
| Re-rank by guidelines | `/triage` → "apply guidelines" |
| Start work on an item | `/triage` → "start N" |
| Mark an item done | `/triage` → "close N" |
| Cancel an item | `/triage` → "drop N" |
| Edit priority guidelines | `/triage` → "update guidelines" |
| Quick status check | `/query "what's on the backlog?"` |
