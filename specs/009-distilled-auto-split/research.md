# Research: Distilled File Auto-Splitting (Feature 009)

## Decision 1 — Insertion Point in /refine

**Decision**: Insert the split-check as Step 6.2 — after distilled files are loaded (Step 6) and before the pre-filter batch (Step 6.5).

**Rationale**: Distilled files are fully loaded in Step 6. The split-check needs only the file contents (to count entries) and nothing from the raw queue. Running it before 6.5 ensures the raw-item pre-filter has access to already-split sub-files if the steward confirms a split. If the steward dismisses all proposals, the session proceeds identically to today.

**Alternatives considered**:
- Before Step 6 (before loading distilled context): Rejected — files must be loaded to count entries; loading them twice wastes context.
- After Step 6.5 (after pre-filtering): Rejected — the pre-filter references distilled files; split sub-files should be available by then.
- As a separate Step 0 before the raw queue check: Rejected — unnecessarily delays the session announcement even when no oversized files exist.

---

## Decision 2 — Entry Count Method

**Decision**: Count level-2 headings (`## `) in each distilled file as a proxy for entry count. Each distilled entry begins with `## <Title>`.

**Rationale**: The distilled file format uses `## <Title>` as the canonical entry delimiter, followed by a `---` separator. Counting `## ` occurrences is O(1) per line with zero false positives for the current format (no nested `##` headings inside entries).

**Alternatives considered**:
- Count `---` separators: Prone to false positives (some entries may contain horizontal rules in body text).
- Count `**Source**:` fields: Fragile — not all entries have a Source field (e.g., the `## Done` header in backlog.md).
- File size in bytes: Less meaningful; a single large entry is not the same retrieval problem as 60 small entries.

**Edge case**: The `## Done` heading in `backlog.md` and the `# Title` h1 header of each file must be excluded from the entry count. The check must count only headings that represent individual distilled entries (h2-level, below the file-level h1 heading).

---

## Decision 3 — Threshold Configuration Format

**Decision**: New optional file `config/split-thresholds.md` with a `## Default` section and optional per-file overrides. Pattern mirrors `config/similarity.md`.

**Format**:
```markdown
## Default

**Threshold**: 50

## Per-File Overrides

| File | Threshold |
|------|-----------|
| domain/distilled/changelog.md | 0 (never split) |
| domain/distilled/requirements.md | 40 |
```

**Rationale**: Consistent with the existing config extension pattern (`similarity.md`). Makes threshold discoverable and human-editable without touching the command file. `0` means "never trigger for this file" — useful for `changelog.md` which is intentionally append-only and unbounded.

**Alternatives considered**:
- Hardcoded constant in `refine.md`: Not configurable without editing the command file; rejected.
- Frontmatter in each distilled file: Decentralised and hard to audit; rejected.
- New YAML config file: Would require a YAML parser; Markdown with a table is consistent with the project's existing config approach.

---

## Decision 4 — Recency Determination

**Decision**: Use the `**Captured**: YYYY-MM-DD` field in each entry to determine recency. Entries with a `**Captured**` date in the most recent half (by count, not date range) go to the active sub-file; the rest go to archived.

**Rationale**: `**Captured**` is mandatory for all distilled entries. Splitting by count rather than a fixed date boundary ensures both sub-files have roughly equal sizes (no empty sub-files due to a date gap).

**Fallback** (when all entries have identical captured dates): Group by `**Type**` field instead. If types are also uniform, present the steward with a free-form grouping request rather than an auto-proposal.

---

## Decision 5 — Original File Retirement

**Decision**: Overwrite the original oversized file with a short redirect notice rather than deleting it.

**Content after retirement**:
```markdown
# <Original Title>

> This file was split on YYYY-MM-DD.
> Active entries: `<active-sub-file>`
> Archived entries: `<archived-sub-file>`
>
> This file is retained for git history continuity.
```

**Rationale**: Preserves git history and makes the split discoverable to anyone who navigates to the original path. Prevents 404-style confusion when editors have the old path open. Hard deletion would require all references in other files to be updated immediately (fragile).

**Alternatives considered**:
- Delete the file: Loses the path as a reference point; requires reference-update sweep; rejected.
- Leave the file unchanged alongside sub-files: Creates confusion about which is authoritative; rejected.

---

## Decision 6 — Changelog Section for File Splits

**Decision**: Extend the refine session changelog entry with a new `### File Splits` subsection, appended after `### Autonomous actions`.

**Format**:
```markdown
### File Splits
- [split]: domain/distilled/requirements.md → requirements-active-1.md (N entries), requirements-archived-1.md (M entries)
  Rationale: "<steward's stated reason or 'no rationale provided'>"
```

**Rationale**: Consistent with the existing changelog subsection pattern. File splits are a distinct category from raw-item autonomous actions; mixing them would obscure the audit trail.

---

## Decision 7 — Governed Decision Format for Split Proposal

**Decision**: Use the standard governed decision template with these fields:

- **trigger**: `file_split_required`
- **summary**: `"<filename> has N entries (threshold: T). Proposed split by recency: <N/2 recent entries> → <active-sub-file>, <N/2 older entries> → <archived-sub-file>."`
- **Options**:
  - A. Confirm split as proposed
  - B. Skip for now (file will be flagged again next session)
  - C. Provide different grouping (free-form: steward describes desired partition)
  - Z. Flag as unresolved (create open ADR in decisions.md)

After option A or C confirmation, the system asks a one-line rationale (optional; default "no rationale provided").

---

## Summary Table

| Decision | Outcome |
|---|---|
| Insertion point | Step 6.2 (after Step 6, before Step 6.5) |
| Entry count method | Count `## ` level-2 headings, exclude file-level h1 and `## Done` headers |
| Threshold config | Optional `config/split-thresholds.md`; default 50 |
| Recency split | By `**Captured**` date, equal halves by count |
| Original file | Retired with redirect notice (not deleted) |
| Changelog | New `### File Splits` subsection |
| Governed decision trigger | `file_split_required` |
