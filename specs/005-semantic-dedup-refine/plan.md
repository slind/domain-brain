# Implementation Plan: Semantic Duplicate Detection in /refine

**Branch**: `005-semantic-dedup-refine` | **Date**: 2026-03-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-semantic-dedup-refine/spec.md`

## Summary

Extend the existing `/refine` host pre-filter stage (Step 6.5) with a new sub-step 6.5c that
uses the AI host's in-context reasoning to detect semantic duplicates — raw items whose meaning
is already captured in the distilled knowledge base, even if phrased differently. Items above
a configurable similarity level are suppressed before the subagent is invoked; outcomes are
logged to the session changelog. All delivery is a single command-file edit to `refine.md` plus
an optional new config template.

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files); no programming language required
**Primary Dependencies**: Claude AI (claude-sonnet-4-6+); built-in tools: Read, Write, Edit, Glob, Grep
**Storage**: Markdown files in git; new optional `config/similarity.md` for threshold config
**Testing**: Manual verification via quickstart scenarios
**Target Platform**: Claude Code (AI assistant extension)
**Project Type**: AI assistant extension — single command file edit, no build, no binary
**Performance Goals**: ≥15pp increase in autonomy rate above Feature 003 baseline; 0% of semantic duplicates reach subagent when threshold is correctly configured
**Constraints**: AI host in-context reasoning only — no external embedding APIs (FR-006). Must not increase false-negative rate for genuinely new knowledge (FR-004). Must not add user-facing friction. Must preserve all existing Step 6.5a/6.5b behaviour.
**Scale/Scope**: One command file modified (`refine.md`); one new optional config file template; ~30–50 lines of instruction text added to Step 6.5

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | ✅ PASS — single edit to `.claude/commands/refine.md`; no new command surfaces |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | ✅ PASS — semantic dedup is a non-normative, high-confidence autonomous action (same class as exact-duplicate filtering); items below threshold still reach subagent unchanged |
| III. Human Authority | Is every normative change gated on explicit human approval and logged with rationale? | ✅ PASS — semantic duplicate suppression is non-normative (same bar as exact-duplicate archiving); all suppressions are logged to changelog; uncertain items pass through to subagent |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control? | ✅ PASS — threshold stored in `config/similarity.md` (Markdown); no opaque state |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | ✅ PASS — feature modifies `/refine` only; `/capture` is unchanged |

**Post-Phase-1 Re-check**: All five principles continue to pass. The semantic comparison is
performed by the host in-context (no external calls); the threshold config file is optional
(has a documented default); no new user-facing prompts are introduced.

## Project Structure

### Documentation (this feature)

```text
specs/005-semantic-dedup-refine/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── refine-step-6.5c.md    # Step 6.5c behaviour contract
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Files (modified by this feature)

```text
.claude/commands/
└── refine.md    # Insert Step 6.5c between 6.5b and "Empty batch" handling;
                 #   extend Step 6 to read config/similarity.md;
                 #   extend Step 11/12 changelog format for semantic-duplicate outcomes

domain/config/
└── similarity.md   # NEW — optional per-domain similarity threshold config
                    # (created from template; hosts use default if absent)
```
