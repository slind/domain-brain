# Implementation Plan: Domain Identity and Knowledge Seeding

**Branch**: `002-domain-identity-seed` | **Date**: 2026-03-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-domain-identity-seed/spec.md`

## Summary

Add domain identity framing (`/frame` command) and bulk knowledge seeding (`/seed` command)
to the Domain Brain system. The domain identity document (`config/identity.md`) provides a
one-line headline, a 3–5 sentence pitch, and explicit in-scope / out-of-scope lists. This
identity is used as a pre-filter when importing existing knowledge via `/seed`, and as context
by both `/refine` (to archive off-domain items autonomously) and `/query` (to frame answers).

All deliverables are Claude command files (`.claude/commands/*.md`) and Markdown template
files. No compilation, no build step, no external services.

---

## Technical Context

**Language/Version**: Markdown + YAML (Claude command files) — no programming language required
**Primary Dependencies**: Claude AI (claude-sonnet-4-6+); built-in tools: Read, Write, Edit, Glob, Grep, Bash (for git)
**Storage**: Markdown files with YAML frontmatter in a git repository
**Testing**: Manual acceptance testing — invoke commands via Claude CLI, inspect created files
**Target Platform**: Claude Code CLI (local workstation)
**Project Type**: Claude AI assistant extension — command files only
**Performance Goals**: `/frame` produces `config/identity.md` in ≤3 min; `/seed` processes a 50-page source in ≤2 min per 100-item session
**Constraints**: Extension-First (no external services, no compilation); Knowledge as Code (Markdown + YAML only, no opaque DB)
**Scale/Scope**: 2 new command files, 2 modified command files, 1 new template config file

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate Question | Status |
|-----------|---------------|--------|
| I. Extension-First | Is every user-facing capability delivered as a command, skill, or subagent invocation — with no standalone app or server process? | [x] |
| II. Eager Junior Architect | Does the design take initiative on all routine/high-confidence tasks and defer only on normative decisions? | [x] |
| III. Human Authority | Is every normative change (responsibilities, ADRs, conflict resolution, deprecation) gated on explicit human approval and logged with rationale? | [x] |
| IV. Knowledge as Code | Do all knowledge artefacts persist as Markdown+YAML frontmatter files in version control — no opaque DB, no binary formats? | [x] |
| V. Minimal Friction Capture | Can a capture be completed in ≤30 seconds without hand-authoring any structured envelope? | [x] |

**All gates pass.**

Notes:
- **I**: `/frame` and `/seed` are `.claude/commands/*.md` files — no server, no binary, no external process.
- **II**: `/seed` auto-generates all envelope fields and autonomously classifies segment relevance; it defers only when confidence is genuinely insufficient (flags `seed-note: Relevance uncertain`).
- **III**: Out-of-scope archival is autonomous (non-normative — items never enter the distilled base). Items flagged as uncertain surface as governed decisions in `/refine`. The identity itself is authored by the human via `/frame`.
- **IV**: `config/identity.md` is Markdown + YAML frontmatter. All seeded items are standard `raw/*.md` files.
- **V**: `/seed` creates all raw items automatically; the human provides only the source path. Per-item time is well under 30 seconds of human effort.

---

## Project Structure

### Documentation (this feature)

```text
specs/002-domain-identity-seed/
├── plan.md           # This file
├── research.md       # Phase 0 output
├── data-model.md     # Phase 1 output
├── quickstart.md     # Phase 1 output
├── contracts/
│   ├── frame.md      # /frame command contract
│   └── seed.md       # /seed command contract
└── tasks.md          # Phase 2 output (/speckit.tasks — not created here)
```

### Source Code (repository root)

```text
.claude/commands/
├── frame.md          # NEW — /frame command
├── seed.md           # NEW — /seed command
├── capture.md        # UNCHANGED
├── refine.md         # ENHANCED — identity.md context + out_of_scope action + seed_relevance_uncertain trigger
└── query.md          # ENHANCED — reads identity.md; prefixes answers with domain framing

domain/
├── config/
│   ├── types.yaml    # UNCHANGED
│   └── identity.md   # NEW template placeholder (schema comment, empty fields)
└── README.md         # UPDATED — /frame added as first initialization step
```

**Structure Decision**: Flat command directory, consistent with feature 001. Two new files,
two edits to existing files, one new template file in `domain/config/`.

---

## Complexity Tracking

No Constitution Check violations. No complexity justifications required.
