# Research: Explicit Subagents — Move to Separate Files

**Date**: 2026-03-17
**Feature**: 001-explicit-subagents

## Q1: How does the host command pass subagent instructions to the Agent tool?

**Decision**: Load the subagent file with the Read tool at session start; pass the file contents as instruction text when invoking the Agent tool — identical to how distilled context files are loaded and passed today.

**Rationale**: The current `/refine` Step 7 instructs Claude to invoke the Agent tool "with the full SUBAGENT INSTRUCTIONS block below." Claude fulfils this by reading the inline block from the same document. After extraction, Step 3 (load context) gains one additional Read call for `.claude/agents/refine-subagent.md`; Step 7 replaces "the block below" with "the subagent instruction text loaded in Step 3." The Agent tool invocation is structurally unchanged — only the source of the instruction text changes from inline to file-loaded. This is the same mechanism already used for loading `identity.md`, `types.yaml`, and all distilled files.

**Alternatives considered**:
- Embedding a file path reference in Step 7 and relying on Claude to read it at invocation time: rejected — less explicit, no single point of failure detection before the session starts.
- Using a `subagent_type` that points to a named agent definition (if the platform supported it): not available in the current Claude Code tool surface.

## Q2: Does loading from `.claude/agents/` work without special configuration?

**Decision**: Yes. The Read tool has no directory restrictions. `.claude/agents/` is a new directory; creating it and placing Markdown files there requires no configuration changes.

**Rationale**: The `.claude/` directory already contains `commands/` and is treated as part of the project by Claude Code. A sibling `agents/` directory follows the same convention. No CLAUDE.md updates are needed for the directory to be accessible.

**Alternatives considered**:
- Placing agent files in `.claude/commands/subagents/`: technically valid, but mixes user-invocable commands with internal implementation files. The `.claude/agents/` convention is cleaner.

## Q3: Does the subagent file need frontmatter to be usable?

**Decision**: No. The Agent tool `prompt` parameter accepts plain text. YAML frontmatter is a convention for user-invocable command files; subagent instruction files are never invoked directly by the user and have no need for frontmatter.

**Rationale**: Confirmed by spec clarification Q2. A plain Markdown prose header is sufficient and keeps the file format consistent with the instruction body that follows.

## Summary

No blockers. The implementation is a straightforward file split and a one-line update to the context-loading step and one-line update to the subagent invocation step. All NEEDS CLARIFICATION items are resolved.
