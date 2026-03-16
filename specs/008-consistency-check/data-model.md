# Data Model: Distilled Entry Consistency-Check (FR-024)

**Feature**: 008-consistency-check | **Date**: 2026-03-16

---

## Entity 1: Staleness Candidate

A distilled entry identified as potentially stale because its `**Captured**` date predates the last git commit to its source command file.

**Lifecycle**: Ephemeral — constructed during a `/consistency-check` run; never written to disk as a separate file.

**Fields**:

| Field | Type | Source |
|-------|------|--------|
| `entry_title` | string | Level-2 heading (`## Title`) of the distilled entry |
| `entry_file` | string | Path to the distilled file (e.g., `domain/distilled/interfaces.md`) |
| `captured_date` | YYYY-MM-DD | `**Captured**: YYYY-MM-DD` field in the distilled entry |
| `describes_file` | string | `**Describes**: <path>` line in the entry content; `null` if absent |
| `file_last_commit_date` | YYYY-MM-DD | Output of `git log --format="%ai" -1 -- <describes_file>`, date portion |
| `staleness_days` | integer | `file_last_commit_date - captured_date` in days (approximate, for display) |
| `status` | enum | `pending` (awaiting review) |

**Staleness condition**: `captured_date < file_last_commit_date` AND `describes_file` is non-null and the file exists in the repo.

**Not a staleness candidate**:
- Entry has no `**Describes**` field → skip (not tracked)
- `describes_file` not found in git history → surface as "source deleted" (distinct case)
- `captured_date >= file_last_commit_date` → not stale, skip silently

---

## Entity 2: Staleness Resolution

The outcome of a steward reviewing a Staleness Candidate. Written to `distilled/changelog.md`.

**Lifecycle**: Persisted to `distilled/changelog.md` at session end. Never a standalone file.

**Fields**:

| Field | Type | Values |
|-------|------|--------|
| `entry_title` | string | Title of the reviewed entry |
| `describes_file` | string | The source file path that triggered the staleness flag |
| `outcome` | enum | `reviewed` \| `re-captured` \| `archived` |
| `rationale` | string | Steward's stated reason; `"no rationale provided"` if empty |
| `resolved_by` | string | Git user name or session identity |
| `resolved_date` | YYYY-MM-DD | Date of resolution |

**Outcome semantics**:
- `reviewed` — steward dismissed the change as non-material; distilled entry unchanged
- `re-captured` — steward updated the entry content to reflect the source change; distilled entry modified
- `archived` — entry is no longer relevant; removed from distilled file (governed action requiring confirmation)

---

## Entity 3: Consistency-Check Session (Ephemeral)

In-memory record maintained during a single `/consistency-check` invocation. Never written to disk; the changelog entry is the durable record.

**Fields**:

| Field | Description |
|-------|-------------|
| `candidates_found` | Count of Staleness Candidates identified |
| `candidates_reviewed` | Count resolved by the steward during this session |
| `candidates_dismissed` | Count resolved as `reviewed` (non-material) |
| `candidates_recaptured` | Count resolved as `re-captured` |
| `candidates_archived` | Count resolved as `archived` |
| `source_deleted` | Count of entries where `describes_file` was not found |

---

## Describes-Link Convention

Entries opt in to consistency tracking by including a `**Describes**` line:

```markdown
## /refine Interface Contract
**Type**: interface
**Captured**: 2026-03-06
**Source**: domain-20260306-ab1c, ...
**Describes**: .claude/commands/refine.md

<entry content>

---
```

**Rules**:
- The `**Describes**` line is optional. Entries without it are never surfaced as staleness candidates.
- The path is relative to the repository root.
- If the described file is renamed or deleted, the entry is surfaced as "source deleted" rather than stale.
- Multiple `**Describes**` lines per entry are not supported in v1 — one source file per entry.

---

## Changelog Entry Format

Appended to `domain/distilled/changelog.md` at the end of every `/consistency-check` session:

```markdown
## YYYY-MM-DD — Consistency Check Session

### Candidates Found: N
- **<Entry Title>** (`<distilled-file>`) — describes `.claude/commands/<file>.md`, last updated YYYY-MM-DD (N days after capture)
- ...

### Resolutions
- [reviewed]: <Entry Title> — no material change
  Rationale: "<steward's words>"
- [re-captured]: <Entry Title> — content updated
  Rationale: "<steward's words>"
- [archived]: <Entry Title> — entry removed
  Rationale: "<steward's words>"

### Skipped (source deleted)
- <Entry Title> — `.claude/commands/<file>.md` no longer exists

---
```

Omit subsections that are empty. If no candidates were found, write:

```markdown
## YYYY-MM-DD — Consistency Check Session

No stale entries found. All tracked entries are current.

---
```
