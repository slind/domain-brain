# Contract: /capture Type Inference (Updated Step 5)

**Feature**: 003-refine-perf | **Date**: 2026-03-12

Documents the updated type inference logic for `/capture` Step 5. Replaces the current
open-ended "compare against descriptions and examples" approach with a structured signal
table that resolves the type at high confidence without asking the user.

---

## Updated Step 5 — Infer Type

**Input**: body text, title, type registry (types.yaml).

**Skip if**: `--type <name>` was provided by the user (Step 3 flag).

### Phase 1: Signal Scan (new)

Scan the title and body for the following high-confidence signals. The first matching row
determines the type. Assign silently — do not prompt the user.

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

If a signal fires: assign that type, proceed to Step 6. Do not prompt.

### Phase 2: Description/Example Comparison (existing, fallback)

If no signal fires, compare the body and title against each type's `description` and
`example` in types.yaml. Select the type whose description and example most closely match.

- **Clear winner** (one type scores clearly above all others): assign silently.
- **Genuine tie** (two or more types remain equally plausible after comparison): present
  the top candidates to the user (existing prompt behaviour). Ask once — do not ask again.

### Phase 3: `other` Assignment

Assign type `other` silently only when:
- No signal fired in Phase 1, AND
- No type scored clearly above the others in Phase 2, AND
- The user was presented the ambiguity prompt but replied with "other" or equivalent.

`other` MUST NOT be the first resort. It is a last resort after both phases fail to resolve
the type.

---

## Behaviour Change Summary

| Scenario | Before | After |
|----------|--------|-------|
| Body contains "MUST" as a constraint | May prompt (two plausible types) | Assigns `requirement` silently |
| Body describes an API contract | May prompt | Assigns `interface` silently |
| Body records architectural rationale | May prompt | Assigns `decision` silently |
| Genuinely ambiguous, no signals | Prompts | Prompts (unchanged) |
| No signals, clear winner on description | Assigns silently | Assigns silently (unchanged) |
