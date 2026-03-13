# Implementation Plan: Backlog Lifecycle Support

**Branch**: `004-backlog-lifecycle` | **Date**: 2026-03-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-backlog-lifecycle/spec.md`

## Summary

Activate the Domain Brain backlog as a full lifecycle workflow surface by adding a `/triage` command (single entry for all backlog operations), two new fields (`**Status**` and `**Priority**`) on every backlog entry, a `config/priorities.md` guidelines document, a `task-management` mode in `/query`, and priority-assignment integration in `/refine`. The design uses a conversational single-command model with AI-proposed changes gated on user confirmation and all closures logged to the changelog.

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files); no programming language required
**Primary Dependencies**: Claude AI (claude-sonnet-4-6+); built-in tools: Read, Write, Edit, Glob, Grep, Agent
**Storage**: Markdown files with YAML frontmatter in git repository (`domain/distilled/backlog.md`, `domain/config/priorities.md`)
**Testing**: Manual acceptance scenario verification — invoke commands, observe output, inspect file state
**Target Platform**: Claude Code extension (any IDE with Claude Code)
**Project Type**: Claude command file extension (`.claude/commands/` directory)
**Performance Goals**: View + single priority change in ≤2 minutes; spec handoff in 1 `/triage` interaction; 0 silent modifications
**Constraints**: No external services, no standalone app, no dependencies beyond built-in tools and Agent tool
**Scale/Scope**: Typically <100 backlog items per domain instance; all content human-readable without tooling

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | [x] `/triage` is a Claude command file; `/query` and `/refine` are extended command files. No app, no server. |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | [x] Display, routing, and direct priority changes execute immediately. AI-proposed changes use a subagent but require confirmation. Only close/drop/guidelines changes have extra gates. |
| III. Human Authority | Is every normative change (responsibilities, ADRs, conflict resolution, deprecation) gated on explicit human approval and logged with rationale? | [x] AI-proposed priority changes require explicit confirmation before write. Close requires rationale. Drop is a governed decision (3 options + flag-as-unresolved). All logged to changelog. |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control — no opaque DB, no binary formats? | [x] backlog.md, priorities.md, changelog.md, triage.md are all Markdown files in git. |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | [x] Capture flow is unchanged. This feature is about backlog management post-capture. N/A gate passes by scope non-interference. |

## Project Structure

### Documentation (this feature)

```text
specs/004-backlog-lifecycle/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
.claude/
└── commands/
    ├── triage.md            ← NEW: /triage command (all backlog lifecycle operations)
    ├── query.md             ← MODIFIED: add task-management reasoning mode
    └── refine.md            ← MODIFIED: update task entry format, add priority assignment

domain/
└── config/
    └── priorities.md        ← NEW: persistent priority guidelines (human-editable)

domain/distilled/
└── backlog.md               ← MODIFIED: backfill Status+Priority fields on 12 existing entries
```

No traditional `src/` or `tests/` directories — this is a command-file feature with no compiled code.

**Structure Decision**: Single-project commands-only layout. All deliverables are Claude command files (`.claude/commands/`) and domain knowledge files (`domain/`). No source tree required.

## Constitution Check — Post-Design Re-evaluation

*Re-checked after Phase 1 design. All gates remain clear.*

| Principle | Post-Design Verification | Status |
|-----------|--------------------------|--------|
| I. Extension-First | `/triage` is a single `.claude/commands/triage.md` file. `/query` and `/refine` are modified command files. `config/priorities.md` is a knowledge file. No app, no server, no binary. | [x] PASS |
| II. Eager Junior Architect | Display, routing, direct priority changes, status transitions, and speckit handoff (after one confirm) all execute without asking unnecessary questions. Subagent is invoked for hint/guidelines reasoning — returns a proposal, not a decision. Host executes. | [x] PASS |
| III. Human Authority | All AI-proposed priority changes (hint and guidelines) require explicit confirmation before any write (FR-004, SC-002). Close requires rationale (FR-008, SC-004). Drop is a 3-option governed decision (FR-010). All logged (FR-011). | [x] PASS |
| IV. Knowledge as Code | `backlog.md`, `priorities.md`, `changelog.md`, `triage.md` are Markdown in git. No shadow state. Done items retained in `## Done` section, not deleted. | [x] PASS |
| V. Minimal Friction Capture | Capture flow unchanged. This feature operates post-capture. No new friction introduced to the capture path. | [x] PASS (N/A) |

## Complexity Tracking

*(No Constitution violations — this section is omitted.)*
