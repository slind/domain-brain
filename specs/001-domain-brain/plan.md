# Implementation Plan: Software Domain Brain

**Branch**: `001-domain-brain` | **Date**: 2026-03-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-domain-brain/spec.md`

## Summary

Domain Brain is a Claude AI assistant extension that lets a software team maintain a structured,
queryable knowledge base about their domain. It is delivered as three Claude commands (`/capture`,
`/refine`, `/query`) backed by a per-domain directory of Markdown+YAML files in version control.
The `/refine` command orchestrates a governed subagent that autonomously processes raw captures and
escalates normative decisions to the human one at a time. No server, no database, no build step.

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files); no programming language required
**Primary Dependencies**: Claude AI (claude-sonnet-4-6+); built-in tools: Read, Write, Edit, Glob, Grep, Bash (for git)
**Storage**: Markdown files with YAML frontmatter in a git repository (per-domain directory)
**Testing**: Manual acceptance testing via Claude CLI; acceptance scenarios from spec.md User Stories 1–5
**Target Platform**: Claude Code CLI (v1 primary); Claude.ai Projects chat surface (v1 secondary)
**Project Type**: Claude AI assistant extension (commands + subagent)
**Performance Goals**: Capture ≤30s (SC-001); query ≤60s for small domains (SC-004); ≥70% autonomous refine rate (SC-002)
**Constraints**: In-context retrieval for ≤50 distilled entries; Grep-based local index for 51–500; hosted index for >500 (v1 targets small/medium only)
**Scale/Scope**: Single-domain brain instance per team; v1 scoped to ≤500 distilled entries

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|---|---|---|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | ✅ All three capabilities are Claude commands; refine subagent uses the Agent tool |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | ✅ Capture auto-populates all envelope fields; refine processes autonomously and stops only for normative changes |
| III. Human Authority | Is every normative change (responsibilities, ADRs, conflict resolution, deprecation) gated on explicit human approval and logged with rationale? | ✅ Governed decision loop in /refine; all decisions recorded in changelog.md |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control — no opaque DB, no binary formats? | ✅ Every file is human-readable .md with YAML frontmatter; even chunk index is plain files |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | ✅ /capture accepts a single description; all envelope fields auto-populated |

**All gates pass. Phase 0 proceeds.**

## Project Structure

### Documentation (this feature)

```text
specs/001-domain-brain/
├── plan.md              # This file
├── research.md          # Phase 0: technology and pattern decisions
├── data-model.md        # Phase 1: YAML schemas for all file types
├── quickstart.md        # Phase 1: how to initialize and use a domain brain
├── contracts/
│   ├── capture.md       # /capture command input/output contract
│   ├── refine.md        # /refine session flow contract
│   └── query.md         # /query input/output contract
└── tasks.md             # Phase 2: task list (created by /speckit.tasks)
```

### Source Code (repository root)

```text
.claude/commands/
├── capture.md           # /capture command (FR-001–FR-007)
├── refine.md            # /refine command (FR-008–FR-015) + subagent orchestration
└── query.md             # /query command (FR-016–FR-023)

domain/                  # Template domain brain instance — teams copy and rename
├── config/
│   └── types.yaml       # Type registry (FR-003, FR-003a, FR-003b)
├── raw/                 # Raw item queue (one .md file per capture)
│   └── .gitkeep
├── distilled/           # Distilled knowledge files
│   ├── domain.md        # Vision, responsibilities
│   ├── codebases.md     # Repos, tech stack, ownership
│   ├── interfaces.md    # API contracts, events
│   ├── requirements.md  # Constraints, non-negotiables
│   ├── stakeholders.md  # People, teams, external parties
│   ├── decisions.md     # ADRs (open and resolved)
│   ├── backlog.md       # Actionable tasks
│   └── changelog.md     # Audit trail of all refine sessions
└── index/               # Large document chunk index (auto-populated)
    └── .gitkeep
```

**Structure Decision**: Single Claude extension project. No backend/frontend split. All
intelligence lives in Claude command prompts; all persistence lives in git-tracked Markdown
files. The `domain/` directory is a copyable template that teams rename for their domain.

## Complexity Tracking

> No constitution violations detected. All five gates pass. No complexity justification required.
