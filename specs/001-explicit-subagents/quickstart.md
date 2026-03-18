# Quickstart: Working With Subagent Files

**Feature**: 001-explicit-subagents

## Where to find subagent files

All subagent instruction files live in `.claude/agents/`:

```
.claude/agents/
└── refine-subagent.md   # Instructions for the /refine pipeline subagent
```

## Editing subagent instructions

1. Open `.claude/agents/refine-subagent.md` directly.
2. Make your changes (e.g., add a new autonomous action type, update the output format).
3. Run `/refine` against a small batch to verify the updated instructions are picked up.

You do NOT need to open or modify `.claude/commands/refine.md`.

## Adding a new subagent file

1. Create `.claude/agents/<name>-subagent.md`.
2. Start the file with the standard header:
   ```markdown
   # <Name> Subagent

   **Invoked by**: `/<command>` (Step N — <description>)
   **Processes**: <item types>
   **Output contract**: <output format description>
   ```
3. Add the instruction body below the header.
4. Update the invoking command file to Read this file at session start and pass its contents when invoking the Agent tool.

## Verifying behavioural parity after edits

Run `/refine` with a known batch and confirm:
- Autonomous actions and governed decisions match the expected baseline.
- Changelog output is identical in structure.
- No new error messages appear.

## If `.claude/agents/refine-subagent.md` is missing

`/refine` will stop immediately with:
```
Error: Subagent instruction file not found: .claude/agents/refine-subagent.md
Ensure the file exists before running /refine.
```
Restore the file from git history: `git checkout HEAD -- .claude/agents/refine-subagent.md`
