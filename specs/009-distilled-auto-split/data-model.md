# Data Model: Distilled File Auto-Splitting (Feature 009)

## Entities

### SplitCandidate (ephemeral)

Constructed during Step 6.2 of `/refine` for each oversized distilled file. Never written to disk.

| Field | Type | Source |
|---|---|---|
| `file_path` | string | Path to the distilled file (e.g., `domain/distilled/requirements.md`) |
| `entry_count` | integer | Count of level-2 (`## `) headings in the file, excluding the file-level h1 and section separators (e.g., `## Done`) |
| `threshold` | integer | Value from `config/split-thresholds.md` for this file, or the default threshold if no override |
| `status` | enum | `pending` → awaiting steward review during the `/refine` governed decision loop |

**Eligibility condition**: `entry_count > threshold` AND `entry_count > 1` (single-entry files surface a warning, not a split proposal).

---

### SplitProposal (ephemeral)

The system's proposed partition for a SplitCandidate. Constructed when the candidate is presented as a governed decision. Never written to disk.

| Field | Type | Description |
|---|---|---|
| `source_file` | string | Path of the oversized file being split |
| `grouping_axis` | enum | `recency` (default) \| `type` (fallback) \| `steward_directed` (when override provided) |
| `sub_files` | array of SubFileSpec | Two or more proposed sub-files |
| `rationale` | string | Human-readable explanation of the proposed grouping |

---

### SubFileSpec (ephemeral, part of SplitProposal)

| Field | Type | Description |
|---|---|---|
| `name` | string | Proposed file name following `{base}-{group-label}-{n}.md` convention |
| `path` | string | Full path: `domain/distilled/{name}` |
| `entries` | array of EntryRef | References to the distilled entries assigned to this sub-file |
| `entry_count` | integer | Count of entries in this sub-file (must be ≥ 1) |
| `label` | string | Human-readable group label (e.g., `active`, `archived`) |

---

### SplitResolution (persisted to changelog)

The outcome of a steward reviewing a SplitCandidate. Written to `distilled/changelog.md` at session end.

| Field | Type | Values |
|---|---|---|
| `source_file` | string | Original oversized file path |
| `outcome` | enum | `confirmed` \| `skipped` \| `flagged_unresolved` |
| `sub_files_created` | array of string | Names of sub-files created (empty if outcome ≠ `confirmed`) |
| `entry_counts` | map string→integer | Entry count per sub-file created |
| `rationale` | string | Steward's stated reason; `"no rationale provided"` if empty |
| `resolved_date` | YYYY-MM-DD | Date of resolution |

---

### ThresholdConfig (persistent, optional)

Stored in `config/split-thresholds.md`. Read at the start of Step 6.2.

| Field | Type | Description |
|---|---|---|
| `default_threshold` | integer | Entry count above which any file is considered oversized. Default: 50 if file absent. |
| `per_file_overrides` | map string→integer | File-path-keyed threshold overrides. Value `0` means "never split this file". |

---

## State Transitions

```
SplitCandidate
  pending → (presented as governed decision)
    → confirmed   — split executed; sub-files created; original retired; changelog updated
    → skipped     — no files modified; file will be flagged again next session
    → flagged_unresolved — open ADR created in decisions.md; no files modified
    → warning     — entry_count == 1; no split proposal presented; steward notified
```

---

## Naming Convention

Sub-file names follow `{base}-{group-label}-{n}.md`:

| Component | Rule |
|---|---|
| `{base}` | Original filename without `.md` extension (e.g., `requirements`) |
| `{group-label}` | Derived from grouping label (`active`, `archived`) or steward-provided name |
| `{n}` | Sequential integer starting at 1; incremented if a file with that name already exists |

**Examples**:
- `requirements-active-1.md`, `requirements-archived-1.md`
- `interfaces-recent-1.md`, `interfaces-older-1.md`
- If steward names groups "core" and "legacy": `requirements-core-1.md`, `requirements-legacy-1.md`
