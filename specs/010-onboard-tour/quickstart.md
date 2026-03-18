# Quickstart: Domain README — Consolidate Command

**Feature**: 010-onboard-tour
**For**: Implementors and testers

## What Gets Built

A single command file: `.claude/commands/consolidate.md`

This command reads three source files and writes one output file:

```
READS:
  config/identity.md          → Domain Summary section
  distilled/interfaces.md     → Exposed Interfaces section
  distilled/backlog.md        → Top Priorities section

WRITES:
  domain/README.md            → the generated README (created or overwritten)
  distilled/changelog.md      → append-only session entry
```

## Testing the Command

### Scenario A — First run (README does not exist)

1. Ensure the domain brain has a populated `config/identity.md` (run `/frame` if needed)
2. Run `/consolidate`
3. Expected: `domain/README.md` is created; terminal shows "created" confirmation
4. Verify: Open `domain/README.md` and confirm all four sections are present

### Scenario B — Re-run (README already exists)

1. Run `/consolidate` a second time
2. Expected: `domain/README.md` is overwritten (not appended); terminal shows "updated" confirmation
3. Verify: File content is identical to a fresh run; no duplicate sections

### Scenario C — Missing identity (error path)

1. Temporarily rename `config/identity.md` to `config/identity.md.bak`
2. Run `/consolidate`
3. Expected: Error message directing user to run `/frame`; no README created or modified
4. Restore: Rename `config/identity.md.bak` back

### Scenario D — Missing optional files

1. Run `/consolidate` in a domain where `distilled/interfaces.md` does not exist
2. Expected: README is generated; Exposed Interfaces section shows "No interfaces defined yet."
3. Verify: No error is thrown

### Scenario E — Changelog entry

1. Run `/consolidate`
2. Open `distilled/changelog.md`
3. Expected: A new entry at the top (or bottom, per append behavior) with today's date and a "Consolidate Session" heading

## Acceptance Checklist

- [ ] `domain/README.md` created on first run
- [ ] `domain/README.md` overwritten (not appended) on subsequent run
- [ ] Domain Summary section matches `config/identity.md` content
- [ ] Exposed Interfaces section lists all `## ` headings from `distilled/interfaces.md`
- [ ] Top Priorities section lists up to 5 open/in-progress items, high priority first
- [ ] Footer line shows "Generated: YYYY-MM-DD by /consolidate"
- [ ] Changelog entry appended to `distilled/changelog.md`
- [ ] Missing `config/identity.md` → hard error, no file writes
- [ ] Missing `distilled/interfaces.md` → "No interfaces defined yet." (no error)
- [ ] Missing `distilled/backlog.md` → "No open items." (no error)
- [ ] README renders correctly in GitHub/GitLab Markdown preview
