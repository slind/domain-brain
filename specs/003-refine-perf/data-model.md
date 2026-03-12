# Data Model: Refine Pipeline Performance Improvements

**Branch**: `003-refine-perf` | **Phase**: 1 | **Date**: 2026-03-12

This feature introduces no new persistent entities. All knowledge artefacts continue to use
the existing Raw Item and Distilled Entry formats. This document records the new in-memory
concepts introduced during a `/refine` session and the augmented fields added to existing
entities.

---

## Existing Entities (unchanged on disk)

### Raw Item

No schema change. Two new `status` transition paths are added:

| Transition | Trigger | Who sets it |
|------------|---------|-------------|
| `raw → refined` (duplicate) | Host pre-filter: exact body match in distilled files | Host Step 6.5 |
| `raw → refined` (out-of-scope) | Host pre-filter: high-confidence Out-of-scope match | Host Step 6.5 |

These are identical to the existing transitions set by Steps 9/10; the distinction is only
timing (before subagent vs. after).

### Distilled Entry

No schema change. Pre-filtered duplicates do not create new distilled entries — they are
simply archived.

---

## New In-Memory Concepts (session-scoped, not persisted)

### PreFilterResult

Produced by Step 6.5. Not written to disk — recorded only in the session log for the
changelog.

```
PreFilterResult {
  item_id:        string          // raw item id
  filter_reason:  "duplicate" | "out_of_scope"
  matched_term:   string | null   // out-of-scope term matched, or null for duplicates
  matched_file:   string | null   // distilled file where duplicate was found, or null
}
```

### TypeClusterBatch

Produced after pre-filtering, before specialist invocation. Not persisted.

```
TypeClusterBatch {
  cluster:        "requirements" | "interfaces" | "decisions" | "generalist"
  items:          RawItem[]       // items routed to this cluster
  context_files:  string[]        // distilled file paths to load for this cluster
}
```

### SpecialistPlan

The REFINE_PLAN returned by each specialist subagent. Not persisted directly — merged into
the session's MergedRefinePlan before execution.

```
SpecialistPlan {
  cluster:              string
  autonomous_actions:   AutonomousAction[]
  governed_decisions:   GovernedDecision[]
}
```

### MergedRefinePlan

The concatenation of all SpecialistPlans. Consumed by Steps 8–10.

```
MergedRefinePlan {
  autonomous_actions:   AutonomousAction[]   // union from all specialists
  governed_decisions:   GovernedDecision[]   // union from all specialists
}
```

---

## Type Routing Table (reference)

Derived from `types.yaml` and the P2 research decisions. Used by the host to route items
to the correct TypeClusterBatch.

| Item type | Cluster | Context files loaded |
|-----------|---------|---------------------|
| `requirement` | requirements | requirements.md, decisions.md, identity.md |
| `interface` | interfaces | interfaces.md, decisions.md, identity.md |
| `decision` | decisions | decisions.md, identity.md |
| `responsibility` | generalist | all distilled files, identity.md |
| `codebase` | generalist | all distilled files, identity.md |
| `stakeholder` | generalist | all distilled files, identity.md |
| `task` | generalist | all distilled files, identity.md |
| `mom` | generalist | all distilled files, identity.md |
| `other` | generalist | all distilled files, identity.md |

The generalist cluster's context is identical to the current (pre-feature) refine behaviour.
Specialist clusters receive a reduced, focused context.

---

## Type Inference Signal Table (reference)

Used by `/capture` Step 5 and `/seed` Step 7. Applied before the "compare against
descriptions and examples" fallback.

| Signal in title or body | Inferred type |
|-------------------------|---------------|
| MUST, SHALL, SHOULD, cannot, required, forbidden (as normative constraints) | `requirement` |
| API, event schema, endpoint, contract, integration protocol, interface definition | `interface` |
| why, because, rationale, trade-off, architectural decision, ADR | `decision` |
| "X owns", "X is responsible for", "X team handles" (ownership assertion) | `responsibility` |
| repository, service, library, tech stack, deployment, microservice | `codebase` |
| Person assigned to role, team, or title | `stakeholder` |
| TODO, backlog, spike, implement, fix, migrate (action item) | `task` |
| Meeting notes, call, standup, retro, decision log (meeting record) | `mom` |

When no signal fires → use description/example comparison. Ask user (capture) or assign
`other` silently (seed) only when no type scores clearly above the others after that step.
