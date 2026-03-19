# domain — Domain Brain README

> An AI extension that turns implicit domain knowledge into a queryable, governed knowledge base.

**Steward**: Søren Lindstrøm
**Last generated**: 2026-03-19 by `/consistency-check`

---

## Domain Summary

Domain Brain is a software product enabling your favorite AI to assist in collecting, culling and reasoning about a specific domain. It captures domain knowledge wherever it is observed. It organizes and distills the captured information through a governed quality gate. And uses the distilled information to serve grounded, relevant context to the AI in order to answer questions and reason about the domain in a qualified manner.

---

## Exposed Interfaces

- /capture Interface Contract
- /refine Interface Contract
- /query Interface Contract
- /frame Interface Contract
- /seed Interface Contract
- config/similarity.md — Similarity Configuration
- /triage — Backlog Lifecycle Data Model
- /consistency-check Interface Contract
- /consolidate — Merged into /consistency-check
- SplitCandidate — in-memory entity for `/refine` Step 6.2 split-check
- SplitProposal — in-memory entity for `/refine` Step 6.2 split-check
- SubFileSpec — in-memory entity for `/refine` Step 6.2 split-check
- SplitResolution — in-memory entity for `/refine` Step 6.2 split-check
- ThresholdConfig — persistent config entity for `/refine` Step 6.2 split-check
- DomainReadme — Output Document Entity
- ConsolidateSession — In-Memory Session Entity
- BacklogItem — Read-Only View for Top Priorities
- InterfaceEntry — Read-Only View for Exposed Interfaces

---

## Intended Usage

Domain Brain is a structured knowledge companion for software teams. It captures, refines, and surfaces domain knowledge so that every decision, requirement, and interface is traceable and queryable.

Use `/frame` to define or update the domain identity — the one-line description, pitch, and scope boundaries that give the system its focus.

Use `/capture` or `/seed` to bring knowledge into the system. `/capture` takes a single item in natural language; `/seed` imports from an existing document, URL, or directory.

Use `/refine` to process the raw queue — the refine agent deduplicates, classifies, and routes each item into the appropriate distilled knowledge file, surfacing governed decisions one at a time.

Use `/query` to ask questions about the domain. The query agent classifies your question, retrieves only relevant distilled entries, and grounds every answer in the knowledge base — naming any gaps it cannot fill.

---

## Top Priorities

1. **Knowledge Staleness Detection** — Introduce a mechanism to surface distilled entries that may have become outdated, using the existing `last_updated` field on entries.
2. **Domain Brain Installation and Initialization Mechanism** — Define and implement a mechanism for installing Domain Brain into any project.
3. **Changelog / Trend Query Mode for /query** — Add a sixth reasoning mode to `/query` — `trend-analysis` or `changelog-query` — that reasons against `changelog.md`.
4. **Command Namespace Prefix for Domain Brain Extensions** — Commands, skills, and agents from this application should be prefixed with a namespace that clearly identifies them.
5. **Split Refine Subagent by Specialist Type** — Feature 001 Design Clarifications explicitly deferred creating separate instruction files per specialist type.

---

*Run `/consistency-check` to refresh this document.*
