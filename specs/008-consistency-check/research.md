# Research: Distilled Entry Consistency-Check (FR-024)

**Feature**: 008-consistency-check | **Date**: 2026-03-16

---

## Q1: ADR-016 Option Analysis

### Finding

**Option A (add a phase to `/refine`)** — Not recommended.
`refine.md` currently stands at 579 lines with 13 major steps, 3 pre-filter phases, 5 specialist subagents, and the full subagent instruction block. It is already at a complexity ceiling. Adding a consistency-check phase would increase cognitive load, expand the testing surface, and make future edits more error-prone.

**Option B (standalone `/consistency-check` command)** — Recommended.
A self-contained command with a single responsibility: scan distilled entries for staleness, surface candidates, and record resolutions. Estimated 100–150 lines. Pattern-consistent with `/frame` and `/query` in simplicity. Keeps `/refine` lean and separates concerns cleanly.

**Option C (hook/git-diff-based)** — Ruled out.
Requires either a git hook (external daemon) or a background/scheduled process — both violate the Extension-First principle (Principle I) and the no-external-services constraint. Not viable.

### Decision
**Choose Option B**: deliver FR-024 as a new `.claude/commands/consistency-check.md` command.

**Rationale**: `/refine` is at a complexity limit; consistency checking is a distinct scanning/discovery concern that fits a dedicated command; the Eager Junior Architect persona is better expressed as a focused tool than as another phase in an already-crowded orchestrator.

**Alternatives considered**: Option A (integrated phase) rejected due to maintainability; Option C (hooks) rejected due to architectural violation.

---

## Q2: Git-Based Change Detection

### Finding

The most reliable approach is extracting the last commit date for a source file:

```bash
git log --format="%ai" -1 -- <file-path>
# Returns: "YYYY-MM-DD HH:MM:SS +TZ"
# Extract date portion: | cut -d' ' -f1
# Returns: "YYYY-MM-DD"
```

Tested against `.claude/commands/refine.md` → returns `2026-03-16`.

Comparing this with a distilled entry's `**Captured**: YYYY-MM-DD` field uses lexicographic string comparison (`[[ "$entry_date" < "$file_last_commit_date" ]]`), which works correctly because ISO 8601 date format is lexicographically ordered.

**Edge cases handled**:
- Untracked file (never committed): `git log` returns empty → treat as "never changed" (no false positive)
- File not yet in repo: same as untracked
- Shallow clone: `git log` returns only the available history; may undercount changes but never overcounts

**Verdict**: Date-based via `git log --format="%ai" -1` is the recommended detection method. Requires 2 Bash invocations per candidate entry (one to extract entry date, one to extract file date — though file dates can be bulk-fetched once per session).

---

## Q3: Source-Link Convention

### Finding

Current distilled entries use `**Source**` or `**Source items**` to record raw item IDs only (e.g., `domain-20260306-ab1c`). No entry currently references a command file path in a structured field. Command file paths appear only in prose (e.g., "delivered as `.claude/commands/refine.md`").

**No schema change is needed.** The consistency-check command will identify trackable entries by scanning entry content for command file path mentions (e.g., grep for `.claude/commands/`), not by parsing a dedicated field.

For entries that *should* be tracked, the steward can add a lightweight convention to the entry content:

```
**Describes**: .claude/commands/refine.md
```

This is a purely informational line — no YAML frontmatter change, no spec amendment. The consistency-check command parses this line to determine the source file to compare against.

**Implementation note**: The command will Grep all distilled files for `**Describes**: .claude/commands/` to build its candidate list.

---

## Q4: Staleness Threshold

### Finding

Distilled entries use `**Captured**: YYYY-MM-DD` (date only, no time). Git commit dates can be extracted in the same format via `cut -d' ' -f1`. Direct string comparison works.

**Date-based comparison** (5–10 lines in a command):
- Extract entry's `Captured` date from Markdown
- Extract command file's last git commit date
- If `entry_date < file_last_commit_date` → mark as staleness candidate

**Commit-presence check** (30+ lines):
- Parse all raw item IDs from `Source` field
- Read each raw item's `captured_at` timestamp
- Compare against file's git history
- More accurate theoretically, but complexity is 3–6× higher and source fields contain raw item IDs (not timestamps directly usable for comparison)

**Winner: Date-based comparison.** Simpler, sufficiently accurate, and matches the data format already in use.

**Observed staleness in current knowledge base**:
The `/refine Interface Contract` in `interfaces.md` was captured `2026-03-06`; `.claude/commands/refine.md` was last committed `2026-03-16` (Feature 006 changes). This entry is a confirmed staleness candidate — validating that the mechanism would surface real issues immediately on first run.

---

## Summary of Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| ADR-016 option | **Option B** — standalone `/consistency-check` command | Keeps /refine lean; dedicated concern; pattern-consistent |
| Change detection mechanism | **Date-based** via `git log --format="%ai" -1` | 2 Bash invocations, lexicographic YYYY-MM-DD comparison |
| Source-link convention | **No schema change** — scan for `**Describes**: <path>` in entry content | Zero friction; backward compatible; opt-in per entry |
| Staleness threshold | **entry Captured date < file last-commit date** | Simplest, sufficient, format-compatible |
