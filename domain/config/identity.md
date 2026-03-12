---
domain: domain
created: 2026-03-06
steward: Søren Lindstrøm
---

# Domain Brain

**One-line**: An AI extension that turns implicit domain knowledge into a queryable, governed knowledge base.

**Pitch**: Domain Brain is a software product enabling your favorite AI to assist in collecting, culling and reasoning about a specific domain. It captures domain knowledge wherever it is observed. It organizes and distills the captured information through a governed quality gate. And uses the distilled information to serve grounded, relevant context to the AI in order to answer questions and reason about the domain in a qualified manner.

**In scope**:
- Command design and behavior (/frame, /seed, /capture, /refine, /query)
- Knowledge workflow patterns (capture → raw → refine → distilled)
- Type system (types.yaml, type routing, governed decisions)
- Data models (Raw Item, Domain Identity, Seeded Raw Item, Seed Session)
- User stories, functional requirements, and acceptance criteria from feature specs
- Architectural decisions and design rationale from research documents
- Interface contracts for all commands
- Constitution and design principles

**Out of scope**:
- Individual team domain content (example Payments data is illustrative, not owned here)
- Enterprise API integrations (Confluence REST, Notion API — future feature)
- Deployment infrastructure and hosting
- Claude model internals or training
