# Contract: Split Threshold Configuration File

**Path**: `<domain-root>/config/split-thresholds.md`
**Required**: No — if absent, default threshold of 50 applies to all files.
**Describes**: `.claude/commands/refine.md` (Step 6.2)

---

## Format

```markdown
## Default

**Threshold**: <integer>

## Per-File Overrides

| File | Threshold |
|------|-----------|
| domain/distilled/<filename>.md | <integer> |
```

---

## Parsing Rules

| Field | Location | Rule |
|---|---|---|
| `default_threshold` | `## Default` section, `**Threshold**: <value>` line | Integer ≥ 1. If missing or unparseable, use built-in default of 50. |
| `per_file_overrides` | `## Per-File Overrides` table | Each row maps a file path to an integer threshold. Value `0` means "never split this file". |

---

## Special Values

| Value | Meaning |
|---|---|
| `0` | Never split this file (suppress all split proposals for this path) |
| Any positive integer | Split threshold; the check triggers when `entry_count > threshold` |

---

## Example

```markdown
## Default

**Threshold**: 50

## Per-File Overrides

| File | Threshold |
|------|-----------|
| domain/distilled/changelog.md | 0 |
| domain/distilled/requirements.md | 40 |
```

In this example:
- `changelog.md` is never split (value 0)
- `requirements.md` triggers a split proposal above 40 entries
- All other distilled files trigger above 50 entries

---

## Validation

- If the file exists but the `## Default` section is missing: use built-in default of 50; log warning in session output.
- If a per-file override value is not an integer or is negative: ignore that row; use default threshold for that file.
- Unrecognised sections are ignored.
