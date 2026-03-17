# Implementation Plan: Distilled File Auto-Splitting

**Branch**: `009-distilled-auto-split` | **Date**: 2026-03-16 | **Spec**: [spec.md](spec.md)

## Summary

Add a split-check pre-processing phase (Step 6.2) to `.claude/commands/refine.md` that counts entries in each distilled file, compares against a configurable threshold, and surfaces oversized files as governed decisions before raw items are processed. When the steward confirms, the system splits the file by recency into named sub-files (`{base}-{group-label}-{n}.md`), retires the original with a redirect notice, and records the action in the changelog. No new commands, no new storage formats — a single command file change plus an optional new config file.

---

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files) — no programming language
**Primary Dependencies**: Claude (claude-sonnet-4-6+); built-in tools: Read, Write, Edit, Glob, Bash (for git)
**Storage**: Markdown files with YAML frontmatter in git repository; new optional `config/split-thresholds.md`
**Testing**: Manual test via representative `/refine` sessions with a seeded-oversized distilled file
**Target Platform**: Claude Code IDE extension (primary), Claude chat (secondary)
**Project Type**: Claude command file extension
**Performance Goals**: Split-check adds <5 seconds to `/refine` startup (entry counting is a line-scan, no external calls)
**Constraints**: No external services; no new commands; no new storage formats beyond the optional config file
**Scale/Scope**: ~10 distilled files per domain brain; at most 2–3 oversized at once in practice

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | ✅ Integrated into `/refine` command; no new process |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | ✅ System proposes split automatically; defers only on confirm/dismiss |
| III. Human Authority | Is every normative change (responsibilities, ADRs, conflict resolution, deprecation) gated on explicit human approval and logged with rationale? | ✅ Split is a governed decision; logged with rationale to changelog |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control — no opaque DB, no binary formats? | ✅ Sub-files are Markdown; original retired with redirect notice |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | ✅ N/A — this feature does not modify the capture path |

**Post-Phase-1 re-check**: All gates still pass. The retirement redirect notice and the optional threshold config file are both plain Markdown — fully human-readable and version-controlled.

---

## Project Structure

### Documentation (this feature)

```text
specs/009-distilled-auto-split/
├── plan.md                              # This file
├── spec.md                              # Feature specification
├── research.md                          # Phase 0 decisions
├── data-model.md                        # Entity definitions
├── contracts/
│   ├── threshold-config.md              # config/split-thresholds.md format
│   └── split-changelog-entry.md         # Changelog entry format for splits
├── checklists/
│   └── requirements.md                  # Spec quality checklist
└── tasks.md                             # Phase 2 output (tasks command)
```

### Source Code (repository root)

```text
.claude/commands/
└── refine.md                            # MODIFIED — single file change

domain/config/
└── split-thresholds.md                  # NEW (optional) — threshold configuration
```

No new commands, no new directories in `domain/distilled/`.

**Structure Decision**: Single-file command modification. All logic lives inside `refine.md` as new prose in a new Step 6.2. The optional config file follows the existing `config/similarity.md` pattern.

---

## Implementation Design

### Step 6.2 — Split-Check Pre-Processing Phase

Insert as a new numbered step between existing Step 6 (Load distilled context) and Step 6.5 (Pre-filter batch).

**Algorithm**:

1. Attempt to read `config/split-thresholds.md`. Parse `default_threshold` and `per_file_overrides`. If absent, use `default_threshold = 50`.
2. For each distilled file loaded in Step 6:
   a. Count level-2 headings (`## `) in the file. Exclude: the file-level `# Title` h1; section markers like `## Done`; any `## ` heading that is the first heading in the file (file header). Only count headings that represent distilled entries (i.e., those followed by `**Type**:` metadata).
   b. Look up the threshold for this file (per-file override → default).
   c. If threshold is 0: skip (never split).
   d. If `entry_count > threshold`: add to `split_candidates` list.
3. If `split_candidates` is empty: proceed to Step 6.5 with no output.
4. For each candidate in `split_candidates` (one at a time):
   a. Generate a `SplitProposal`:
      - Parse all entries from the file (by `## ` heading + `---` separator).
      - Sort by `**Captured**: YYYY-MM-DD` descending. If all captured dates are equal, fall back to type-based grouping.
      - First ⌈N/2⌉ entries → active sub-file; remaining → archived sub-file.
      - Generate sub-file names: `{base}-active-1.md`, `{base}-archived-1.md` (increment suffix if names already exist).
   b. Present as a governed decision:
      ```
      File split required (1 of N):

      <filename> has <entry_count> entries (threshold: <T>).
      Proposed split by recency:
        Active:   <active-sub-file>   (<n> entries, captured <oldest-active-date> – <newest-date>)
        Archived: <archived-sub-file> (<m> entries, captured <oldest-date> – <newest-archived-date>)

      Options:
        A. Confirm split as proposed
        B. Skip for now (will be flagged again next session)
        C. Provide different grouping (describe your preferred partition)
        Z. Flag as unresolved (create open ADR in decisions.md)

      You can reply with an option letter or describe your intent.
      ```
   c. Wait for steward response:
      - **A (confirm)**: Ask for optional rationale. Execute split (see below). Record `SplitResolution` with outcome `confirmed`.
      - **B (skip)**: No file writes. Record `SplitResolution` with outcome `skipped` (not logged to changelog). Continue.
      - **C (redirect)**: Accept natural language grouping description. Re-generate `SplitProposal` with `grouping_axis = steward_directed`. Re-present for confirmation (counts as same governed decision, not a new one). On confirm, execute split.
      - **Z (flag)**: Append open ADR to `decisions.md`. Record `SplitResolution` with outcome `flagged_unresolved`. Continue.

**Split execution** (when outcome = confirmed):
1. Write active sub-file: entries assigned to active group, preserving original Markdown.
2. Write archived sub-file: entries assigned to archived group, preserving original Markdown.
3. Overwrite original file with retirement redirect notice (see `contracts/split-changelog-entry.md`).
4. Reload distilled context to include sub-files and exclude the retired original (needed for Step 6.5 semantic duplicate detection).

**Changelog**: Step 12 changelog format is extended with a `### File Splits` subsection (see `contracts/split-changelog-entry.md`). This subsection is written even if splits occur alongside regular raw-item processing. Skipped proposals are NOT logged.

---

## Key Rules (additions to refine.md)

- **Split-check runs on every `/refine` invocation** — no flag to disable it (except per-file threshold override of 0).
- **Split governed decisions are presented before raw-item governed decisions** — file integrity takes priority.
- **Pause compatibility**: If the steward says "stop" or "skip for today" during the split-check governed decision loop, the session pauses cleanly. Partially-resolved split proposals (some confirmed, some not yet presented) do not cause inconsistency — the remaining candidates are simply re-presented on the next session.
- **No partial splits**: A split is either fully executed (both sub-files written, original retired, changelog updated) or not started. If a write fails mid-execution, report the error and leave the original file unchanged.

---

## Complexity Tracking

No constitution violations — no entry required.
