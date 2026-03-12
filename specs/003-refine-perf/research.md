# Research: Refine Pipeline Performance Improvements

**Branch**: `003-refine-perf` | **Phase**: 0 | **Date**: 2026-03-12

No NEEDS CLARIFICATION markers were present in the spec. This document records the design
decisions and rationale derived from reading the current command implementations.

---

## P1 — Host-Level Pre-Filtering

### Decision: Insert as Step 6.5 in refine.md

**Rationale**: Steps 1–6 already give the host everything it needs for both filters:
- The raw batch is in memory (Step 4).
- All distilled file content is in memory (Step 6).
- `config/identity.md` is in memory (Step 6).

Inserting a new Step 6.5 — between the context load and the Agent tool call — requires no
architectural change and no additional I/O.

### Exact-Duplicate Detection Rule

Compare the full text body of each raw item against the body content of all distilled file
entries. Normalise whitespace only (strip leading/trailing whitespace per line, collapse
multiple blank lines). Do NOT use semantic similarity — the spec bounds this to exact
(byte-for-byte after normalisation) matches.

**Action**: `archive_only` — set raw item status to `refined`, record reason as
"exact duplicate of existing distilled entry", include matched target file in changelog.

### Out-of-Scope Pre-Filter Rule

Evaluate each raw item's title + body against the Out-of-scope list using the **same
semantic confidence bar** as the existing `out_of_scope` autonomous action in the subagent
instructions (Step 7). This is intentional: the spec says "items clearly matching the
Out-of-scope list" — ambiguous items must still pass through.

- **High confidence match** → `out_of_scope` action; archive item; record matched term.
- **Unclear match** → pass to subagent. The subagent may still produce an `out_of_scope`
  autonomous action or a `seed_relevance_uncertain` governed decision.

**Action**: Same as current `out_of_scope` autonomous action — set status to `refined`,
record matched out-of-scope term in changelog.

### What Pre-Filtering Does NOT Change

- Near-duplicates (semantically similar but not identical) → still handled by subagent.
- Items with no Out-of-scope list → pre-filtering skips scope elimination, passes all items.
- The subagent still receives identity context — it can still issue `out_of_scope` actions
  for items the host was not confident enough to filter.

---

## P2 — Specialist Subagents

### Decision: Three Specialists + Generalist Fallback

Type clusters mapped to specialists, derived from `types.yaml` routes_to values:

| Cluster | Item Types | Distilled Context Files |
|---------|-----------|------------------------|
| `requirements` | `requirement` | requirements.md + identity.md + decisions.md |
| `interfaces` | `interface` | interfaces.md + identity.md + decisions.md |
| `decisions` | `decision` | decisions.md + identity.md |
| generalist (fallback) | `responsibility`, `codebase`, `stakeholder`, `task`, `mom`, `other`, unrecognised | all distilled files (current behaviour) |

`decisions.md` is included in all specialist contexts because ADRs provide the governing
rationale for requirements and interfaces. `identity.md` is always included (ADR-013).

### Decision: Parallel Invocation via Multiple Agent Tool Calls

The host groups the pre-filtered batch by type cluster and invokes one Agent tool call per
non-empty cluster. All invocations can be concurrent — items are independent.

**Alternatives considered**:
- Sequential invocation: simpler but slower; rejected.
- Single subagent with cluster hints in the prompt: doesn't reduce context window size;
  defeats the purpose of specialisation. Rejected.

### Decision: Plan Merging by Concatenation

Each specialist returns a standard REFINE_PLAN (AUTONOMOUS_ACTIONS + GOVERNED_DECISIONS).
The host concatenates the AUTONOMOUS_ACTIONS lists and the GOVERNED_DECISIONS lists from all
specialists before proceeding to Step 8. No deduplication needed — each item appears in
exactly one specialist's batch.

### What Specialist Routing Does NOT Change

- The REFINE_PLAN output format is identical for all specialists.
- Steps 8–13 (execute, governed loop, changelog) are unchanged.
- The `other` type always falls through to the generalist — specialist routing does not
  attempt to reclassify `other` items (that is P3's job).

---

## P3 — Type Inference Improvements

### Root Cause Analysis

**capture.md Step 5** fires the user-facing ambiguity prompt whenever "two or more types
are plausible". In practice, most items have at least two vaguely plausible types (e.g., a
requirement can look like a task; an interface can look like a codebase entry). The threshold
is too permissive: it asks the user too early.

**seed.md Step 7** delegates to `/capture`'s inference rules via the comment
`type: <inferred type from types.yaml — same inference rules as /capture>` but provides no
inline signal guidance. The seeding context window does not include the step-by-step inference
logic from capture.md, so the AI must reconstruct it — inconsistently.

### Decision: Add Explicit Signal Rules to capture.md Step 5

Replace the open-ended "compare against descriptions and examples" instruction with a
structured signal table. High-confidence signals resolve the type without asking the user:

| Signal present in title or body | Infer type |
|---------------------------------|------------|
| Modal verbs: MUST, SHALL, SHOULD, cannot, required, forbidden | `requirement` |
| Describes an API, event schema, endpoint, contract, integration protocol | `interface` |
| Records a why, because, rationale, trade-off, ADR, or architectural choice | `decision` |
| Assigns ownership: "X owns", "X is responsible for", "X team handles" | `responsibility` |
| Describes a repository, service, library, tech stack, deployment | `codebase` |
| Assigns a person to a role, team, or title | `stakeholder` |
| Actionable item: TODO, backlog, spike, implement, fix, migrate | `task` |
| Records a meeting, call, standup, retro, decision log | `mom` |

**Low confidence** (ask the user) only when: no signal from the table applies AND two or
more types still score equally after comparing descriptions and examples.

**`other`** is assigned silently only when no signal fires and no type scores above the
others — not as a first resort.

### Decision: Add Inline Signal Rules to seed.md Step 7

Copy the signal table above into seed.md Step 7's type assignment instruction so that the
seeding context has the same inference logic available without depending on capture.md's
context. The seed command never asks the user for type — it assigns silently or defaults to
`other`, consistent with its bulk-import nature.

**Alternatives considered**:
- Reference capture.md's logic from seed.md: fragile (breaks if capture.md is refactored);
  the seed context window may not include capture.md. Rejected.
- Shared type-inference section in types.yaml: requires schema change; over-engineers for
  this scope. Rejected.

### What Type Inference Does NOT Change

- The user-facing ambiguity prompt in capture.md is NOT removed — it is only triggered less
  often (when no signal fires at all).
- seed.md never asks the user for type (unchanged).
- Existing raw items already typed as `other` are not retroactively reclassified (per spec
  assumption).
- The 9-type registry in types.yaml is unchanged.
