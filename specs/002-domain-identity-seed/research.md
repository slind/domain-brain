# Research: Domain Identity and Knowledge Seeding

**Feature**: 002-domain-identity-seed | **Branch**: 002-domain-identity-seed | **Date**: 2026-03-06

---

## Decision 1: /frame Collection UX — Template-Fill Pattern

**Decision**: `/frame` pre-fills all auto-derivable fields (domain name from directory,
steward from `git config user.name`, creation date from system clock), presents a Markdown
template with the remaining fields as labelled placeholders, and asks the user to fill in or
confirm the content in a single exchange. On re-run, current values replace the placeholders.

**Rationale**: The "eager junior architect" principle demands proactive pre-population. Asking
for each field sequentially (multi-turn) is friction-heavy for a one-time setup command. A
single template-fill exchange is the same pattern used by `/capture` for type confirmation —
one question maximum. The user can edit the resulting `config/identity.md` directly at any
time without re-running `/frame`.

**Alternatives considered**:
- Multi-turn field-by-field collection — rejected: high friction for a one-time setup; violates
  Eager Junior Architect (asks for things that can be inferred).
- Fully non-interactive with inline `--headline`, `--pitch`, `--in-scope`, `--out-of-scope`
  flags — rejected: awkward for multi-item scope lists; forces shell quoting for long strings.

---

## Decision 2: config/identity.md File Schema

**Decision**: The identity document uses YAML frontmatter for machine-readable fields and
Markdown body for human-readable content. Schema:

```yaml
---
domain: <name>          # auto-populated from directory name
created: <YYYY-MM-DD>   # auto-populated
steward: <git user>     # auto-populated from git config user.name
---

# <Domain Name>

**One-line**: <≤15-word description>

**Pitch**: <3–5 sentences describing what this domain owns and why it exists>

**In scope**:
- <item>
- <item>

**Out of scope**:
- <item>
- <item>
```

**Rationale**: Frontmatter holds auto-generated metadata (domain name, date, steward) that
commands read programmatically. The body uses the same `**Bold label**: content` pattern as
distilled file entries — familiar to anyone who has read the distilled base. Plain Markdown
means the file is directly readable and editable by any team member without tooling.

**Alternatives considered**:
- Pure YAML (no Markdown body) — rejected: harder to read and edit for non-technical users;
  violates IV Knowledge as Code (human-readable intent).
- Embedded in `config/types.yaml` — rejected: mixes domain identity (normative) with type
  registry (configuration); types.yaml should remain focused on the classification system.

---

## Decision 3: /seed Resume Logic — Implicit Offset via Existing Raw Items

**Decision**: When `/seed` is re-run on the same source and the 100-item cap was reached on
the prior run, it detects how many raw items with `source.location: <source>` already exist
in `raw/`, uses that count as the starting segment offset, and processes the next batch of
segments from that offset.

**Flow**:
1. At session start, Glob `raw/*.md` and count items with `source.location` matching the
   current source (file path or URL).
2. Use that count as the segment skip offset (e.g., if 100 items exist, skip segments 1–100
   and process segments 101–200).
3. Segmentation order is deterministic (document order), ensuring consistent offsets.
4. Report offset at session start: "Resuming from segment 101 (100 already seeded)."

**Rationale**: No persistent state file needed — the raw items themselves serve as the
progress log. Deterministic segmentation guarantees the same segment N always maps to the
same content, making the offset reliable. This is consistent with the Knowledge as Code
principle: the state lives in the files, not in a separate tracking artifact.

**Alternatives considered**:
- Explicit `--start N` flag — rejected: requires the user to track the offset manually; more
  friction than needed.
- Progress tracking file (`raw/.seed-progress/`) — rejected: opaque state file outside the
  normal raw item format; violates Knowledge as Code minimalism.

---

## Decision 4: Cap Applies to Raw Items Created, Not Segments Examined

**Decision**: The 100-item cap counts raw items *written* per session (in-scope +
flagged-as-uncertain). Out-of-scope segments that are skipped do NOT count toward the cap.

**Rationale**: The user's intent is to build up to 100 new raw items per session. An
out-of-scope segment that is discarded does not contribute to that goal, so counting it would
unfairly penalise sources with mixed content. A domain with 40% out-of-scope content would
otherwise produce only 60 useful raw items per session instead of the expected 100.

**Alternatives considered**:
- Cap on segments examined — rejected: unfair for mixed-content sources; penalises users for
  having well-defined out-of-scope lists (more filtering → fewer useful items per cap).

---

## Decision 5: /refine Identity Context Injection

**Decision**: In `/refine` Step 6 (Load distilled context), add an explicit read of
`config/identity.md` if it exists. The identity document is passed to the refine subagent
alongside the raw items and distilled files. The subagent instructions reference it as
"Domain Identity" and use the "Out of scope" list for `out_of_scope` classification.

**Rationale**: The refine subagent already receives all distilled files as context. Adding
`config/identity.md` to this context bundle is a minimal, non-breaking change — the subagent
already knows how to read structured Markdown. No new input format or schema is required;
the subagent simply has one additional context document.

**Alternatives considered**:
- Passing identity as a separate structured parameter to the subagent — rejected: over-engineered;
  the subagent reads prose context naturally.
- Having the host perform out_of_scope classification before invoking the subagent — rejected:
  moves classification logic out of the subagent, splitting concerns in a confusing way.

---

## Decision 6: /query Identity Framing — Step 1.5 (After Domain Root Discovery)

**Decision**: In `/query`, immediately after Step 1 (domain root discovery) and Step 2
(argument parsing), add Step 2.5: attempt to read `config/identity.md`. If found, store the
one-line description for use in the answer header. If absent, proceed normally with no error.

**Rationale**: The identity framing is a cosmetic enhancement to the answer header — it must
never block a query. Adding it as a soft-read step immediately after domain discovery keeps
the change localised and non-disruptive. The one-line description is the only field needed;
no full identity parse is required for this step.

**Alternatives considered**:
- Adding identity read inside Step 5 (context retrieval) — rejected: retrieval already has
  logic for candidate file selection; adding identity as a special non-candidate file there
  would complicate the retrieval logic.

---

## Resolved NEEDS CLARIFICATION Items

All technical context fields were derivable from the spec, the clarification session, and
patterns from feature 001-domain-brain. No external research required. All decisions resolved
above.
