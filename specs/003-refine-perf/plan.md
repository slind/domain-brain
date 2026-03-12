# Implementation Plan: Refine Pipeline Performance Improvements

**Branch**: `003-refine-perf` | **Date**: 2026-03-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-refine-perf/spec.md`

## Summary

Three targeted improvements to the `/refine` pipeline to reduce subagent batch size,
increase autonomy rate (SC-002 target: ≥70%), and reduce the `other`-type full-load
penalty. All changes are confined to three Claude command files: `refine.md`, `capture.md`,
and `seed.md`. No new commands, no new storage formats, no architectural changes.

1. **P1 — Host Pre-Filtering** (`refine.md`): Insert Step 6.5 between context load (Step 6)
   and subagent invocation (Step 7). The host eliminates exact duplicates and high-confidence
   out-of-scope items before the Agent tool call, reducing every subagent batch.

2. **P2 — Specialist Subagents** (`refine.md`): Modify Step 7 to group items by type cluster
   (`requirements`, `interfaces`, `decisions`, generalist) and invoke a focused Agent tool
   call per non-empty cluster. Each specialist receives only the distilled files relevant to
   its types. Plans are merged before Step 8.

3. **P3 — Type Inference** (`capture.md`, `seed.md`): Add a signal-table Phase 1 to the
   type inference logic in both commands. High-confidence signals (modal verbs, API keywords,
   rationale phrases, ownership assertions) resolve the type silently before falling back to
   description comparison or the user prompt. Reduces `other`-typed items at source.

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files); no programming language
**Primary Dependencies**: Claude AI (claude-sonnet-4-6+); built-in tools: Read, Write, Edit, Glob, Grep, Bash (git)
**Storage**: Markdown files with YAML frontmatter in a git repository
**Testing**: Manual verification via the quickstart scenarios in `quickstart.md`
**Target Platform**: Claude Code (AI assistant extension)
**Project Type**: AI assistant extension (command/skill files only — no build, no binary)
**Performance Goals**: ≥30% subagent batch reduction (SC-001); ≥70% autonomous processing rate (SC-002); <20% `other`-typed items post-inference (SC-004)
**Constraints**: All delivery via command file edits only. Must not add user-facing friction. Must preserve all existing refine/capture/seed behaviour for items that do not match the new optimisation paths.
**Scale/Scope**: Three command files modified; ~50–150 lines of instruction text changed or added across those files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | ✅ PASS — all changes are edits to `.claude/commands/` files |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | ✅ PASS — pre-filtering and specialist routing are fully autonomous; type inference reduces user prompts |
| III. Human Authority | Is every normative change (responsibilities, ADRs, conflict resolution, deprecation) gated on explicit human approval and logged with rationale? | ✅ PASS — pre-filtering only removes exact duplicates (non-normative) and high-confidence out-of-scope items (same bar as existing autonomous action); governed decision loop unchanged |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control — no opaque DB, no binary formats? | ✅ PASS — no new storage; all PreFilterResults are logged to `changelog.md` |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | ✅ PASS — type inference improvements reduce questions asked, making capture faster |

**Post-Phase-1 Re-check**: All five principles continue to pass. The specialist routing
design adds Agent tool calls inside the host but does not expose any new user-facing surface
or create any persistent state outside the existing file system.

## Project Structure

### Documentation (this feature)

```text
specs/003-refine-perf/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── refine-flow.md             # Updated /refine step sequence
│   ├── capture-type-inference.md  # Updated /capture Step 5 contract
│   └── seed-type-inference.md     # Updated /seed Step 7 contract
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Files (modified by this feature)

```text
.claude/commands/
├── refine.md    # Add Step 6.5 (pre-filter); modify Step 7 (specialist routing);
│                #   update Step 12 changelog format; update Step 13 summary format
├── capture.md   # Improve Step 5: add Phase 1 signal table; tighten ambiguity threshold
└── seed.md      # Improve Step 7: add inline Phase 1 signal table for type assignment
```

**Structure Decision**: Single-project layout. No `src/` or `tests/` directories — this
is a Claude command file project. All changes are prose instruction edits to three existing
files at `.claude/commands/`. The delivered changes are measured in instruction text added
or modified, not lines of code compiled.
