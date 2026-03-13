# Priority Guidelines

Guidelines used by the domain brain to assign and adjust task priorities.
Update these to reflect current team focus and strategic direction.

Run `/triage` → "apply guidelines" to re-rank the current backlog against these rules.
Run `/triage` → "update guidelines" to edit this file in a guided exchange.

---

## Elevate to High

- Items that directly unblock other backlog items
- Items linked to an active `/speckit.specify` session
- Items required to close a known gap in the current feature set
- Items that reduce token spend or improve the quality of the refinement pipeline

## Keep at Medium

- Quality improvements to existing commands (/refine, /query, /capture)
- New capabilities that are well-understood and have clear requirements
- Items that improve developer experience without changing core behaviour

## Defer to Low

- Platform-level vision items with no current requirement coverage (e.g., multi-AI host, federation)
- Items with no linked spec, no linked ADR, and no active user request
- Nice-to-have optimisations with no measurable user impact in the near term
