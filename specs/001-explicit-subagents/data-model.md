# Data Model: Explicit Subagents

**Date**: 2026-03-17
**Feature**: 001-explicit-subagents

## File Structure Change

This feature introduces no new data entities. The change is purely structural: one section of `refine.md` is extracted to a new file.

### Before

```text
.claude/
└── commands/
    └── refine.md          # 724 lines — includes host pipeline AND subagent instructions
```

### After

```text
.claude/
├── commands/
│   └── refine.md          # ~550 lines — host pipeline only; references subagent file
└── agents/
    └── refine-subagent.md # ~175 lines — SUBAGENT INSTRUCTIONS block only
```

## File Descriptions

### `.claude/commands/refine.md` (modified)

The host command. Orchestrates the full refine pipeline.

**Change**: Step 3 gains one Read call for `.claude/agents/refine-subagent.md`. Step 7 replaces the inline instruction block reference with the loaded file contents. The `### SUBAGENT INSTRUCTIONS — REFINE AGENT` section is removed.

**Error handling addition**: At the point of loading the subagent file, if the Read call fails or returns empty, the command MUST output:
```
Error: Subagent instruction file not found: .claude/agents/refine-subagent.md
Ensure the file exists before running /refine.
```
Then stop (no processing begins).

### `.claude/agents/refine-subagent.md` (new)

The refine subagent instruction file.

**Format**: Plain Markdown — no YAML frontmatter.

**Opening header** (required by FR-006):
```markdown
# Refine Subagent

**Invoked by**: `/refine` (Step 7 — specialist subagent invocation)
**Processes**: All item types — requirements, interfaces, decisions, codebase, responsibility, and generalist cluster items
**Output contract**: REFINE_PLAN with AUTONOMOUS_ACTIONS and GOVERNED_DECISIONS sections (JSON-like structure)
```

**Body**: Verbatim copy of the current `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block content from `refine.md`, beginning at "You are a refine subagent…".

## Invariants

- The content of the subagent instructions MUST be byte-for-byte identical to the current inline block (no rewording, no additions) — this feature is a structural refactor only.
- The `.claude/agents/` directory MUST exist before `/refine` is invoked.
- No other files are created or modified by this feature.
