# Contract: Changelog Entry Format — File Split

Appended to `distilled/changelog.md` as a `### File Splits` subsection within the current refine session's changelog entry.

---

## Format (split confirmed)

```markdown
### File Splits
- [split]: <source-file> → <active-sub-file> (N entries), <archived-sub-file> (M entries)
  Rationale: "<steward's rationale or 'no rationale provided'>"
```

**Example**:
```markdown
### File Splits
- [split]: domain/distilled/requirements.md → requirements-active-1.md (28 entries), requirements-archived-1.md (27 entries)
  Rationale: "requirements.md was getting unwieldy; archiving pre-feature-004 entries"
```

---

## Format (split skipped)

Skipped proposals are NOT recorded in the changelog. The file is unchanged and no entry is written. The proposal will re-surface on the next `/refine` invocation.

---

## Format (split flagged as unresolved)

When the steward chooses "flag as unresolved" (option Z), the outcome is recorded as an open ADR in `decisions.md` (not in the file-splits subsection). The standard open ADR format applies:

```markdown
## [OPEN] ADR-<NNN>: Split <filename>
**Status**: open
**Captured**: YYYY-MM-DD
**Context**: <filename> has N entries (threshold: T). A split was proposed but deferred.
**Options**:
- A: Split into active/archived sub-files (recency axis)
- B: Raise threshold for this file in config/split-thresholds.md
**Flagged by**: refine agent (Step 6.2 split-check)
**Pending**: Steward decision on split strategy

---
```

---

## Placement in Full Changelog Entry

The `### File Splits` subsection is placed immediately after `### Autonomous actions` (if present) and before `### Governed decisions`:

```markdown
## YYYY-MM-DD — Refine Session

### File Splits
- [split]: ...
  Rationale: "..."

### Autonomous actions
- [route_and_summarise]: ...

### Governed decisions
- ...

---
```

If no splits were executed, the `### File Splits` subsection is omitted entirely.
