# /consistency-check — Interface Contract

**Feature**: 008-consistency-check | **Type**: Command interface

---

## Invocation Syntax

```
/consistency-check
/consistency-check --domain <path>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

## Session Flow

```
1. LOCATE     Domain brain root (same discovery logic as all other commands)
2. SCAN       Grep all distilled files for **Describes**: lines → build candidate list
3. DETECT     For each candidate: git-compare entry captured date vs. source file last-commit date
4. REPORT     List staleness candidates to steward (oldest-first by captured date)
5. RESOLVE    For each candidate: present dismiss / re-capture / archive options
6. RECORD     Append session summary to distilled/changelog.md
```

## Staleness Detection Logic

For each distilled entry with a `**Describes**: <path>` line:

1. Extract `captured_date` from `**Captured**: YYYY-MM-DD`
2. Run: `git log --format="%ai" -1 -- <describes_path> | cut -d' ' -f1` → `file_date`
3. If `file_date` is empty (file untracked or new): skip — not a candidate
4. If `<describes_path>` not found in working tree: surface as "source deleted"
5. If `captured_date < file_date`: surface as staleness candidate
6. Otherwise: skip silently

## Output Formats

**No candidates found**
```
Consistency check complete. No stale entries found.

All N tracked entries are current.
```

**Candidates found**
```
Consistency check — N stale entries found:

  [1] /refine Interface Contract   (interfaces.md)
      Describes: .claude/commands/refine.md
      Entry captured: 2026-03-06 | File last changed: 2026-03-16 (10 days)

  [2] ...

Review each entry? (yes / skip all / select N,M)
```

**Per-candidate resolution prompt**
```
Entry [1]: /refine Interface Contract

Options:
  A. Dismiss — not a material change (entry stays, flag cleared)
  B. Re-capture — I'll update the entry content now
  C. Archive — entry is no longer relevant (governed: requires rationale)

Your choice:
```

**Session complete**
```
Consistency check complete.

  Reviewed:    2
  Dismissed:   1
  Re-captured: 1
  Archived:    0

Changelog updated: distilled/changelog.md
```

**Source deleted**
```
Warning: 1 entry references a source file that no longer exists:
  - /refine Interface Contract → .claude/commands/refine.md (not found)

These entries need manual review. Include in session? (yes / skip)
```

## Governed Action: Archive

Archiving a distilled entry is a destructive governed action requiring explicit rationale:

```
Decision required: Archive "/refine Interface Contract"

This will remove the entry from interfaces.md. This action is logged and irreversible
without git revert.

One-line rationale:
```

No "flag as unresolved" option for archive decisions — the steward must provide a rationale or cancel.

## Files Written

- `distilled/*.md` — modified when entries are re-captured or archived (host only)
- `distilled/changelog.md` — appended with session summary

## Files Read

- All `distilled/*.md` files — scanned for `**Describes**` lines
- `config/identity.md` — soft-read for domain name in session header (non-blocking if absent)
