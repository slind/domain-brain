# Research: Additional Specialist Subagents in /refine

**Branch**: `006-specialist-subagents` | **Date**: 2026-03-13

## Summary

No external research required. All design decisions are resolved by the existing codebase (Feature 003 pattern) and the spec. This document records the decisions and their basis.

---

## Decision 1: Context files for the `codebase` specialist

**Decision**: `codebases.md` + `identity.md`

**Rationale**: Codebase items describe repositories, services, and tech-stack entries. The only distilled file that provides deduplication context for a codebase item is `codebases.md`. `identity.md` provides scope context (In-scope/Out-of-scope lists) needed for all specialists. No cross-file lookup is needed to merge or update a codebase entry.

**Alternatives considered**:
- Include `interfaces.md` — rejected. Interface ownership is referenced in codebase entries but the specialist does not need to resolve interface contracts; escalate if cross-file reasoning is needed.
- Include `responsibilities.md` — rejected. Team ownership is a responsibility concern; keep clusters independent.

---

## Decision 2: Context files for the `responsibility` specialist

**Decision**: `responsibilities.md` (if present) + `identity.md`

**Rationale**: Responsibility items describe team ownership, role definitions, and accountability mappings. The only distilled file needed for deduplication and merge decisions is `responsibilities.md`. If the file does not yet exist in the domain, the specialist proceeds with `identity.md` only — this is consistent with the existing pattern where a specialist's designated context file may be absent in early-stage domains.

**Alternatives considered**:
- Include `decisions.md` — rejected. ADRs occasionally reference ownership but responsibility routing decisions do not require ADR context; escalate as governed decision if needed.

---

## Decision 3: Should `stakeholder`, `task`, or `mom` types get specialists?

**Decision**: Deferred. All three remain in the generalist cluster.

**Rationale**: The spec explicitly defers these. `task` items go to `backlog.md` (a single destination, low routing complexity). `stakeholder` and `mom` (minutes of meeting) items are low-volume in typical domains and have variable context needs. No evidence from existing refine sessions that these types account for meaningful generalist load.

---

## Decision 4: Instruction template for new specialists

**Decision**: Reuse the existing `SUBAGENT INSTRUCTIONS — REFINE AGENT` block verbatim for both new specialists.

**Rationale**: The instruction block is type-agnostic — it reasons against whatever context files it receives and the type registry. No new instruction variant is needed. This was verified by reviewing the current `refine.md` Step 7 implementation.

---

## Decision 5: Concurrency behaviour

**Decision**: New specialists may be invoked concurrently with existing specialists and each other, consistent with the Feature 003 statement "Multiple clusters may be invoked concurrently."

**Rationale**: No ordering dependency exists between `codebase`, `responsibility`, and other clusters. Merging happens after all invocations complete (Step 7 merge step).

---

## Conclusion

The implementation is a targeted, additive change to the routing table in `refine.md` Step 7. Two new rows are added; two new specialist invocation paths are described. No other files require changes.
