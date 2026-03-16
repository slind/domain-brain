# Implementation Plan: Distilled Entry Consistency-Check Mechanism (FR-024)

**Branch**: `008-consistency-check` | **Date**: 2026-03-16 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-consistency-check/spec.md`

## Summary

Implement a mechanism that detects distilled entries whose source artefacts (command files, spec files) have changed since the entry was last updated, surfaces them to the steward for review, and records resolutions in the changelog. The first sub-step is resolving ADR-016 — the open architectural decision determining whether this ships as an integrated `/refine` phase, a standalone `/consistency-check` command, or a hook/git-diff-triggered approach.

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files) — no programming language required
**Primary Dependencies**: Claude AI (claude-sonnet-4-6+); built-in tools: Read, Glob, Grep, Bash (for git log/diff)
**Storage**: Markdown files with YAML frontmatter in version-controlled git repository
**Testing**: Manual invocation testing; no automated test framework (consistent with all prior features)
**Target Platform**: Claude Code (claude-code CLI), operating on a local git repository
**Project Type**: Claude command file / skill
**Performance Goals**: Full consistency-check run completes in under 3 minutes for a typical domain (≤30 source-linked entries) — per SC-003
**Constraints**: No external services; fully offline; git must be available locally for change detection
**Scale/Scope**: 10–30 distilled entries with trackable `**Source**` fields at any given time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | ✅ Pass — delivered as a command file (standalone `/consistency-check`) or a phase integrated into `/refine`; both are extension patterns. No server or daemon. |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | ✅ Pass — change detection and candidate listing are fully autonomous; dismiss/re-capture/archive require explicit steward action. |
| III. Human Authority | Is every normative change gated on explicit human approval and logged with rationale? | ✅ Pass — all resolutions require explicit steward action (FR-004, FR-005); every run appends to changelog (FR-008). |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML files in version control? | ✅ Pass — outputs only to `distilled/changelog.md`; no new file formats or databases introduced. |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | ✅ Pass — not applicable to this feature (detection/review, not capture); no friction added to the capture path. |

All gates pass. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/008-consistency-check/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
# If ADR-016 → Option B (standalone command):
.claude/commands/
└── consistency-check.md   # New command file

# If ADR-016 → Option A (integrated phase):
.claude/commands/
└── refine.md              # Modified: consistency-check phase added to Step 1

domain/distilled/
└── changelog.md           # Appended on every run (no new files created)
```

**Structure Decision**: New `.claude/commands/consistency-check.md` command file (ADR-016 resolved: Option B). No new directories, no source code, no build step.

## Phase 1 Artifacts — Complete

| Artifact | Path | Status |
|----------|------|--------|
| Research | [research.md](research.md) | ✅ |
| Data model | [data-model.md](data-model.md) | ✅ |
| Command contract | [contracts/consistency-check-command.md](contracts/consistency-check-command.md) | ✅ |

**Key decisions** (from research.md):
- ADR-016 → **Option B**: standalone `/consistency-check` command
- Change detection: `git log --format="%ai" -1` date comparison (5 lines of bash)
- Source-link: opt-in `**Describes**: <path>` line in entry content (no schema change)
- Staleness threshold: `entry Captured date < source file last-commit date`

## Phase 0 Research Questions — Resolved

1. **ADR-016 Option Analysis** — concrete tradeoffs between options A (integrated phase in `/refine`), B (standalone `/consistency-check` command), and C (hook/git-diff-based). Which best fits Extension-First and Eager Junior Architect principles?

2. **Git-based change detection** — what `git` commands (available via the Bash tool) can reliably determine whether a file has changed since a given date or commit? Edge cases: new repo, shallow clone, untracked files, renamed files.

3. **Source-link convention** — how are source artefacts currently referenced in distilled entries? Is `**Source**` sufficient to derive a file path, or does a new `**Source-file**` field need to be introduced?

4. **Staleness threshold approach** — date-based (entry's `**Captured**` date vs. file's last commit date) vs. commit-based (does the file appear in any commit after the entry was captured). Which is more reliable and easier to implement?

See [research.md](research.md) for findings.
