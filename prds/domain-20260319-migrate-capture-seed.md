# PRD: Migrate capture and seed from commands to project-local skills

## Intent

Convert the `capture` and `seed` verbs from `.claude/commands/` to `.claude/skills/` so
that Claude can proactively suggest their use when relevant content appears in normal
conversation. The user must confirm before any write occurs. All other verbs remain
commands.

## Background

- ADR-020 (decisions.md): governed verbs stay as commands; proactive verbs become skills
- Backlog item: domain-20260319-c4f1 / domain-20260319-e7b2
- This is the prerequisite groundwork for the future installer feature

## Tasks

- [ ] Create `.claude/skills/capture/` directory and move `capture.md` content into `SKILL.md` with the correct skill frontmatter (`name`, `description`)
- [ ] Create `.claude/skills/seed/` directory and move `seed.md` content into `SKILL.md` with the correct skill frontmatter
- [ ] Remove `.claude/commands/capture.md`
- [ ] Remove `.claude/commands/seed.md`
- [ ] Verify the skills appear correctly in Claude's system-reminder by checking frontmatter format matches existing installed skills (e.g. `~/.agents/skills/grill-me/SKILL.md`)
- [ ] Update `CLAUDE.md` if it references capture/seed as commands

## Acceptance criteria

- `capture` and `seed` no longer exist in `.claude/commands/`
- `capture` and `seed` exist in `.claude/skills/` with valid SKILL.md files
- Frontmatter matches the skill format used by existing skills in `~/.agents/skills/`
- No other commands are affected
