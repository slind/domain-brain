# Implementation Plan: Additional Specialist Subagents in /refine

**Branch**: `006-specialist-subagents` | **Date**: 2026-03-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-specialist-subagents/spec.md`

## Summary

Extend the `/refine` command's type-cluster routing table to add two new specialist subagents — `codebase` and `responsibility` — following the identical pattern established by Feature 003. Each specialist receives a focused context window (its designated distilled file + `identity.md`), eliminating the full-distilled-files load currently triggered for these item types by the generalist fallback. The entire implementation is a targeted edit to `.claude/commands/refine.md` Step 7.

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files); no programming language required
**Primary Dependencies**: Claude AI (claude-sonnet-4-6+); Agent tool for subagent invocations (already in use)
**Storage**: `.claude/commands/refine.md` — the only file modified
**Testing**: Manual `/refine` invocations with test batches containing `codebase` and `responsibility` items; validated via session output showing correct specialist routing
**Target Platform**: Claude Code CLI / Claude AI assistant
**Project Type**: Extension (Claude command file modification)
**Performance Goals**: SC-002 (≥70% autonomous processing); SC-005 (no full-distilled-files load for `codebase`/`responsibility` items)
**Constraints**: No new commands introduced; no changes to `/capture`, `/seed`, or any distilled files; must not break the three existing Feature 003 specialists
**Scale/Scope**: Affects all `/refine` sessions containing `codebase` or `responsibility` items going forward

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | [x] |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | [x] |
| III. Human Authority | Is every normative change gated on explicit human approval and logged with rationale? | [x] |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control? | [x] |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | [x] |

All gates pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/006-specialist-subagents/
├── plan.md              # This file
├── research.md          # Phase 0 — all decisions resolved
├── spec.md              # Feature specification
├── checklists/
│   └── requirements.md  # Quality checklist (all pass)
└── tasks.md             # Phase 2 output (/speckit.tasks — not yet created)
```

### Source (repository root)

```text
.claude/commands/
└── refine.md            # The only file modified — Step 7 routing table update
```

No new files. No `src/`, `tests/`, `contracts/`, or `data-model.md` — this feature has no new entities and no external interface contracts. The change is entirely within the existing command file.

## Phase 0: Research

**Status**: Complete — see [research.md](research.md)

All design decisions resolved from existing codebase inspection:

| Question | Decision |
|----------|----------|
| Context files for `codebase` specialist | `codebases.md` + `identity.md` |
| Context files for `responsibility` specialist | `responsibilities.md` (if present) + `identity.md` |
| Instruction template for new specialists | Reuse existing `SUBAGENT INSTRUCTIONS — REFINE AGENT` verbatim |
| `stakeholder`, `task`, `mom` specialisation | Deferred — remain in generalist cluster |
| Concurrency behaviour | New specialists may be invoked concurrently, same as Feature 003 |

## Phase 1: Design

### Change Summary

**File**: `.claude/commands/refine.md`, Step 7 — Route batch to specialist subagents

**Current routing table** (lines ~195–200):

| Item type | Cluster | Context files to load |
|-----------|---------|----------------------|
| `requirement` | requirements | requirements.md, decisions.md, identity.md |
| `interface` | interfaces | interfaces.md, decisions.md, identity.md |
| `decision` | decisions | decisions.md, identity.md |
| `responsibility`, `codebase`, `stakeholder`, `task`, `mom`, `other`, unrecognised | generalist | all distilled files, identity.md |

**Updated routing table**:

| Item type | Cluster | Context files to load |
|-----------|---------|----------------------|
| `requirement` | requirements | requirements.md, decisions.md, identity.md |
| `interface` | interfaces | interfaces.md, decisions.md, identity.md |
| `decision` | decisions | decisions.md, identity.md |
| `codebase` | codebase | codebases.md (if present), identity.md |
| `responsibility` | responsibility | responsibilities.md (if present), identity.md |
| `stakeholder`, `task`, `mom`, `other`, unrecognised | generalist | all distilled files, identity.md |

**Behaviour for missing context files**: If `codebases.md` or `responsibilities.md` does not exist in the domain, the specialist is invoked with only `identity.md`. The specialist MUST NOT fall back to a full-context load.

### No data model or contract changes

This feature introduces no new entities, no new distilled file schemas, and no new user-facing commands. `data-model.md` and `contracts/` are not applicable.

### Post-design Constitution Re-check

All five principles remain satisfied after Phase 1 design. The change is additive to an existing command file with no structural side-effects.

## Implementation Notes

- Edit is a single, targeted replacement of the routing table row for `responsibility`, `codebase`, ... in Step 7 of `refine.md`.
- The specialist invocation paragraph ("For each non-empty cluster, invoke the refine subagent...") applies to all clusters without modification — no new invocation prose needed.
- The merge step ("After all specialist invocations complete, concatenate...") applies unchanged.
- No session output format changes — the per-cluster tracking already handles N clusters.
