# Implementation Plan: Explicit Subagents — Move to Separate Files

**Branch**: `001-explicit-subagents` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-explicit-subagents/spec.md`

## Summary

Extract the `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block embedded in `.claude/commands/refine.md` into a dedicated file at `.claude/agents/refine-subagent.md`. Update the host command to load and reference the external file, preserving 100% behavioural parity. No logic changes — pure file reorganisation.

## Technical Context

**Language/Version**: Markdown (no programming language)
**Primary Dependencies**: Claude Agent tool (built-in to Claude Code); Read tool (built-in)
**Storage**: Markdown files in `.claude/commands/` (host commands) and `.claude/agents/` (subagent instructions)
**Testing**: Manual — run `/refine` against a representative batch; verify output matches pre-change baseline
**Target Platform**: Claude Code (claude-sonnet-4-6+)
**Project Type**: Claude command file extension
**Performance Goals**: Identical to current `/refine` — no new latency introduced
**Constraints**: FR-005 — observable behaviour must be byte-for-byte identical before and after
**Scale/Scope**: 2 files changed (1 modified, 1 created); ~175 lines moved

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | ✅ Pass — only `.claude/` files modified; no new commands or processes |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | ✅ Pass — feature is a structural refactor; principle is preserved in refine behaviour |
| III. Human Authority | Is every normative change gated on explicit human approval and logged with rationale? | ✅ Pass — no normative content changes; pure file reorganisation |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control? | ✅ Pass — new file is Markdown in git; no other formats introduced |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | ✅ Pass — capture pipeline unaffected |

**Post-Phase-1 re-check**: All gates still pass. No design decisions introduced violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-explicit-subagents/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
.claude/
├── commands/
│   └── refine.md              # MODIFIED — remove inline subagent block; add file load in Step 3
└── agents/
    └── refine-subagent.md     # NEW — extracted subagent instructions with prose header
```

**Structure Decision**: Single-directory layout. No new top-level directories. `.claude/agents/` is a new sibling to `.claude/commands/` within the existing `.claude/` project directory.

## Phase 0: Research

See [research.md](research.md). All unknowns resolved:

- **Instruction passing**: Host uses Read tool to load subagent file at session start; passes contents in Agent tool invocation. Same mechanism as loading distilled context files. No blockers.
- **Directory access**: `.claude/agents/` requires no special configuration. Read tool has no directory restrictions.
- **File format**: Plain Markdown (no frontmatter). Confirmed by spec clarification.

## Phase 1: Design

See [data-model.md](data-model.md) and [quickstart.md](quickstart.md).

### Change 1 — Create `.claude/agents/refine-subagent.md`

New file. Content:
1. Plain Markdown prose header (FR-006):
   ```markdown
   # Refine Subagent
   **Invoked by**: `/refine` (Step 7 — specialist subagent invocation)
   **Processes**: All item types (requirements, interfaces, decisions, codebase, responsibility, generalist)
   **Output contract**: REFINE_PLAN with AUTONOMOUS_ACTIONS and GOVERNED_DECISIONS sections
   ```
2. Body: verbatim copy of the current `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block from `refine.md` (starting "You are a refine subagent…", ending at the close of the block).

### Change 2 — Modify `.claude/commands/refine.md`

Two edits:

**Edit A — Add file load to Step 3 (Load distilled context)**

After the existing context-loading instructions, add:

```
Additionally, read `.claude/agents/refine-subagent.md` and store its contents as
`subagent_instructions`. If the file is absent or unreadable, output:
  Error: Subagent instruction file not found: .claude/agents/refine-subagent.md
  Ensure the file exists before running /refine.
Then stop.
```

**Edit B — Update Step 7 subagent invocation reference**

Replace:
> `- The full SUBAGENT INSTRUCTIONS — REFINE AGENT block below`

With:
> `- The subagent instruction text loaded from .claude/agents/refine-subagent.md in Step 3 (subagent_instructions)`

**Edit C — Remove the inline block**

Delete the entire `### SUBAGENT INSTRUCTIONS — REFINE AGENT` section and its contents from `refine.md`.

### Verification

After both changes:
- `SC-001`: grep `refine.md` for `SUBAGENT INSTRUCTIONS` → no matches.
- `SC-002`: run `/refine` → identical output to pre-change baseline.
- `SC-003`: list `.claude/agents/` → `refine-subagent.md` visible.
- `SC-004`: add a comment to `refine-subagent.md`, run `/refine` → comment appears in agent output.
