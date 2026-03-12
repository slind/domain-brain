# Contract: /seed Type Inference (Updated Step 7)

**Feature**: 003-refine-perf | **Date**: 2026-03-12

Documents the explicit type inference logic added to `/seed` Step 7. Previously, the step
referenced capture.md's rules via a comment but provided no inline guidance. This contract
defines the self-contained inference rules for the seed context.

---

## Updated Step 7 — Type Assignment for Raw Items

The `type` field of each raw item created by `/seed` is determined by the following
two-phase inference. The seed command NEVER asks the user for type — it assigns silently
or defaults to `other`.

### Phase 1: Signal Scan

Scan the segment's title and body for the following high-confidence signals. The first
matching row determines the type. Assign silently.

| Signal (in title or body) | Inferred type |
|---------------------------|---------------|
| Normative modal verbs as constraints: MUST, SHALL, SHOULD, cannot, required, forbidden | `requirement` |
| Describes an API, event schema, endpoint, contract, integration protocol, or interface definition | `interface` |
| Records a why/because/rationale, trade-off analysis, or architectural decision | `decision` |
| Ownership assertion: "X owns", "X is responsible for", "X team handles" | `responsibility` |
| Describes a repository, service, library, tech stack, or deployment unit | `codebase` |
| Assigns a person to a role, team, or title | `stakeholder` |
| Actionable item: TODO, backlog, spike, implement, fix, migrate | `task` |
| Meeting record: call notes, standup, retro, decision log, minutes | `mom` |

### Phase 2: Description/Example Comparison (fallback)

If no signal fires, compare the segment content against each type's `description` and
`example` in types.yaml. Select the type whose description and example most closely match.

If a clear winner emerges: assign silently.

### Phase 3: `other` Assignment

If no signal fires AND no clear winner emerges from description comparison: assign
type `other` silently.

`other` items that are also classified as ambiguous scope (seed-note: Relevance uncertain)
will be handled by the `/refine` governed decision loop.

---

## Key Difference from /capture

`/seed` never asks the user for type at any stage. The prompt shown in `/capture` Step 5
when two types are "equally plausible" does not apply here — seed is a batch import and
user interaction per-item is not appropriate. If inference cannot resolve the type, `other`
is assigned silently and flagged for the refine agent.
