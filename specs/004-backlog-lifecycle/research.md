# Research: Backlog Lifecycle Support

**Feature**: `004-backlog-lifecycle`
**Date**: 2026-03-12
**Status**: Complete — all NEEDS CLARIFICATION resolved

## Research Questions

This feature has no external technology unknowns — it is implemented entirely in Claude command files using built-in tools. Research focused on integration patterns with existing commands and design decisions with multiple valid approaches.

---

## RQ-1: How to extend /query with a new reasoning mode without breaking existing modes

**Decision**: Add `task-management` as a sixth row in the Step 3a mode-classification table; add `backlog.md` as the sole candidate file in the Step 3b table. Follow the exact same pattern as the five existing modes.

**Rationale**: The existing `/query` mode-dispatch is a simple table lookup — trigger patterns matched against the question. Adding a sixth mode requires: (1) new trigger patterns row, (2) new candidate files row, and (3) a second-stage rule clarification (no second-stage retrieval for `task-management` — same as `gap-analysis`). No structural changes to Steps 4–9 are needed. The mode is additive, not substitutive.

**Trigger patterns chosen**:
- "what's on the backlog", "open tasks", "what's open", "in progress", "what should I work on", "what's done", "backlog status", "what are we working on"

**Alternatives considered**:
- Creating a separate `/backlog` command: Rejected — adds a new command to remember. The spec explicitly requires using the existing `/query` surface for read-only questions.
- Extending `gap-analysis` to include backlog: Rejected — gap-analysis loads all distilled files; task-management mode must load only `backlog.md` (FR-019).

---

## RQ-2: Priority guidelines document format

**Decision**: A plain Markdown document at `domain/config/priorities.md` with three conventional sections: `## Elevate to High`, `## Keep at Medium`, `## Defer to Low`. Each section contains free-form bullet rules in plain English.

**Rationale**: The subagent that reads guidelines needs to reason over them, not parse them mechanically. Free-form English rules are more expressive and easier to write/update than a structured YAML schema. The section headings provide enough structure for reliable parsing. The file lives in `config/` alongside `types.yaml` and `identity.md`, keeping configuration co-located.

**Example structure**:
```markdown
# Priority Guidelines

## Elevate to High
- Items that directly unblock other backlog items
- Items linked to an active /speckit.specify session

## Keep at Medium
- Quality improvements to existing features
- New capabilities that are well-understood

## Defer to Low
- Platform-level vision items (multi-AI host, federation)
- Items with no current requirement coverage
```

**Alternatives considered**:
- YAML frontmatter schema with structured priority rules: Rejected — harder to write and read for non-technical stewards; AI reasoning works better on natural language rules.
- Embedding priorities as comments in `config/types.yaml`: Rejected — mixes type definitions with strategic focus, making both harder to maintain.

---

## RQ-3: Hint-driven AI subagent invocation pattern

**Decision**: The `/triage` host invokes a general-purpose subagent (Agent tool) when hint-driven or guidelines-driven re-ranking is requested. The subagent receives: (1) all open backlog entries as text, (2) the user's hint or the full guidelines document, (3) instructions to return a structured proposal table. The host presents the proposal table, awaits confirmation, then executes writes.

**Rationale**: Matches the established refine pipeline pattern exactly — subagent returns a plan, host executes it. This keeps all file writes in the host (consistent with FR-008 of the refine spec pattern), and allows the proposal step to be a pure reasoning step without side effects.

**Subagent output format** (from hint-driven re-ranking):
```
PRIORITY_PROPOSAL:
[
  { "item_num": 2, "title": "Enterprise API Integration", "current": "medium", "proposed": "high", "reason": "matches 'enterprise integration' hint", "was_manual": false },
  ...
]
```

**Proposal display format** (shown to user before confirmation):
```
Proposed priority changes (4 items):

  #  Title                                       Current  →  Proposed  Note
  2  Enterprise API Integration for /seed        medium   →  high
  5  Semantic Duplicate Detection in /refine      medium   →  high
  8  Knowledge Staleness Detection                medium   →  low
 10  Multi-AI Host Support                        medium   →  low       ⚠ previously manual

Apply these changes? (yes / no / select N,M to apply only some)
```

**Alternatives considered**:
- Running priority re-ranking entirely within the host (no subagent): Rejected — the host AI has limited context bandwidth when also managing conversation; a dedicated subagent with just the backlog data and hint produces better quality proposals.
- Making priority proposals instant (no confirmation): Rejected explicitly by spec FR-004 and SC-002.

---

## RQ-4: Changelog entry format for triage sessions

**Decision**: Triage sessions append to `distilled/changelog.md` using the same section-header convention as refine sessions, but with a `## YYYY-MM-DD — Triage Session` heading and subsections for Closed and Dropped items only. Priority-only sessions (no closes/drops) do not append to the changelog (no audit-worthy normative changes).

**Rationale**: The changelog is an audit trail for normative changes. Priority changes (even AI-proposed with confirmation) are strategic preferences, not normative knowledge changes. Only close and drop actions produce durable knowledge removal that requires an audit record. This keeps the changelog focused and avoids polluting it with routine prioritisation noise.

**Format**:
```markdown
## 2026-03-12 — Triage Session

### Closed
- [close]: domain-20260312-c001 → Enterprise API Integration for /seed
  Rationale: "Spec started as feature 005"

### Dropped
- [drop]: domain-20260312-c003 → Cross-Domain Federation
  Decision: de-prioritised to low (kept open)
  Rationale: "No concrete requirement yet"

---
```

**Alternatives considered**:
- Logging all triage operations including priority changes: Rejected — bloats the changelog; priority changes are preferences, not normative decisions.
- Separate `triage-log.md` file: Rejected — adds a new file to learn. The changelog is the right audit location.

---

## RQ-5: backlog.md Done section structure

**Decision**: Done items are moved to a `## Done` section at the bottom of `backlog.md`. The section heading is a conventional Markdown heading — not a separate file. Open items appear above `## Done`; done items appear below it. The section is created on first close if it doesn't exist.

**Rationale**: Keeps the backlog as one human-readable document (FR-009, spec Assumption 5). Done items are visible for reference without searching a separate file. The `## Done` heading is easy for the command to detect and manipulate with the Edit tool.

**backlog.md structure**:
```markdown
# Backlog

<!-- comment -->

## Enterprise API Integration for /seed   ← open items (priority-sorted in /triage display)
**Status**: open
**Priority**: high
...

---

## Done

## Semantic Duplicate Detection in /refine   ← done items
**Status**: done
**Priority**: medium
...
```

**Alternatives considered**:
- Separate `backlog-done.md` file: Rejected (spec Assumption 5 — keep as one document).
- Deleting done items: Rejected (FR-009 — must retain for audit trail).
- Archive to raw/ with `status: archived`: Rejected — raw/ is the input queue, not an archive; backlog entries are distilled knowledge.

---

## RQ-6: Backfilling existing 12 entries

**Decision**: Mechanical Edit-tool addition of `**Status**: open` and `**Priority**: medium` after every `**Type**: task` line in `backlog.md`. Default priority `medium` — user applies guidelines via `/triage → "reprioritise everything"` afterward.

**Rationale**: No normative judgment required; every existing entry starts at the same neutral defaults. This is an autonomous action (not a governed decision) because there is no conflict to resolve and no human choice implied by the default values.

**Implementation**: 12 sequential Edit operations, one per entry. Alternatively, a single Write of the entire file with all insertions (more efficient, less error-prone given the mechanical nature of the change).

---

## Summary: No Unresolved Clarifications

All NEEDS CLARIFICATION items from Technical Context were resolved by design inference:
- Storage format: established (Markdown in git, same as all domain artifacts)
- Testing approach: established (manual acceptance scenarios against file state)
- Subagent invocation pattern: confirmed (Agent tool, general-purpose, returns plan, host executes)
- Changelog scope: confirmed (close/drop only, not priority changes)
- Done section location: confirmed (## Done heading in same file)
