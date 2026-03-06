# Software Domain Brain — Design Specification

> An AI-powered extension for capturing, refining, and reasoning about knowledge within a software domain (Team Topology sense). This document reflects the v1 design — intentionally simple, with clear extension seams for future iterations.

---

## 1. Concept Overview

The Domain Brain is a persistent knowledge system per software domain. It operates across three sequential layers:

```
[Capture] → [Refine] → [Reason]
  Raw           Distilled        Insights
  Intake         Context           Q&A
```

- **Capture** — low-friction intake of raw information from any source
- **Refine** — AI-assisted distillation; reduces noise, surfaces ambiguity, governs normative decisions through a human
- **Reason** — context-scoped retrieval + structured prompting to answer design, decision, and planning queries

The core design principle: **the Refine step is the product**. A small, opinionated distilled knowledge base makes the Reason step reliable. A large, noisy one makes it useless.

---

## 2. Repository Structure

All knowledge lives as structured markdown in a git repository — human-readable, diffable, and LLM-friendly.

```
/domain-brain/
  /raw/                    ← all captured items, unprocessed
  /distilled/
    domain.md              ← vision, responsibilities, stakeholders
    codebases.md           ← repos, tech stack, ownership
    interfaces.md          ← APIs, contracts, events
    requirements.md        ← constraints and non-negotiables
    stakeholders.md        ← people, teams, external parties
    decisions.md           ← ADRs, open and resolved
    backlog.md             ← actionable tasks linked to requirements
    changelog.md           ← audit trail of all refine sessions
  /index/                  ← auto-generated chunk index for retrieval
```

---

## 3. Capture Layer

### 3.1 The Capture Envelope

Every captured item uses a thin mandatory envelope around free-form content. The human provides intent; the AI provides structure where possible.

```markdown
---
id: cap_20260304_143212
source: claude.ai-chat | vscode
type: responsibility | task | requirement | codebase | interface | stakeholder | decision | other
domain: payments-service
tags: [auth, onboarding]          # optional
captured_at: 2026-03-04T14:32:12Z
captured_by: alice
status: raw                       # raw → refined → archived
---

# [One-line title]

[Completely free-form content — paste anything]
```

The envelope is the structure. The body is intentionally unstructured to keep capture fast.

### 3.2 Capture Types

Each type routes the Refine agent to the correct distilled target and shapes how it interprets the content:

| Type | Refine agent asks… | Distilled target |
|---|---|---|
| `responsibility` | Is this already owned? Does it conflict? | `domain.md` |
| `interface` | Does this contradict an existing contract? | `interfaces.md` |
| `codebase` | Is this repo already known? What's new? | `codebases.md` |
| `requirement` | Is this a new constraint or a duplicate? | `requirements.md` |
| `stakeholder` | New person/team, or update to existing? | `stakeholders.md` |
| `decision` | Is this a new ADR or an update? | `decisions.md` |
| `task` | Is this actionable? Linked to a requirement? | `backlog.md` |
| `other` | Classify first, then route | Agent decides |

### 3.3 Enforcement Mechanisms

**VS Code / Cursor**
- A command (`Capture to Domain Brain`) presents a minimal input form: title, type (dropdown), optional tags
- The envelope is generated automatically and appended to `/raw/`
- A workspace linter (frontmatter regex) flags any `/raw/` file missing required envelope fields
- The user never hand-writes YAML

**Claude.ai (via Projects)**
- A persistent system prompt instructs Claude: *"When the user invokes /capture, extract a title, infer the type from context, and format as a capture envelope. Ask only if type is genuinely ambiguous."*
- The user pastes messy content; Claude wraps it
- Output is copy-pasted into the repo, or committed automatically via an MCP git connector

### 3.4 Large Document Handling

When a captured item links to or is a large document (threshold: > ~10 pages):

1. The capture pipeline fetches and parses the document (PDF, HTML, Confluence export)
2. The document is chunked at logical boundaries (headings, sections)
3. Each chunk is embedded and stored in a vector index (see Section 5.2)
4. Chunk IDs and source metadata are written back into the raw item

The distilled entry then holds a summary + chunk references:

```markdown
## REQ-014 — PSD2 Compliance
Summary: All payment callbacks must comply with PSD2 SCA requirements.
Detail-source: psd2-spec-v4.pdf § 4.2–4.5
Chunk-ids: [src_0042, src_0043, src_0044]
```

---

## 4. Refine Layer

### 4.1 Governing Principle

The refine agent operates on a **propose, don't commit** model for normative content. It acts autonomously on mechanical work and stops for human approval on anything that shapes what the domain is obligated to do or who owns what.

### 4.2 Autonomous vs. Governed Actions

**Autonomous — agent acts freely:**
- Deduplication (same fact captured twice)
- Summarising verbose raw content
- Normalising to distilled file structure
- Routing `type: other` to the correct file
- Extracting structured fields from free-form prose
- Archiving raw items after processing

**Governed — agent proposes, human decides:**
- Resolving conflicting responsibilities between teams
- Merging partially overlapping interface definitions
- Promoting a `task` to a `requirement`
- Creating a new ADR entry from a captured decision
- Deprecating or replacing an existing distilled entry
- Any inference the agent scores below ~80% confidence

### 4.3 Confidence-Gated Autonomy

```
For each raw item:
  1. Can I determine the type with >80% confidence?       → proceed
  2. Does the distilled target already contain this?       → deduplicate silently
  3. Does this contradict an existing distilled entry?     → STOP, governed
  4. Does this create a new normative fact?                → STOP, governed
  5. Otherwise                                             → summarise and merge
```

A false stop (asking unnecessarily) is far less harmful than a silent normative write.

### 4.4 Refine Session Model

Refinement is a conversation, not a batch job. The agent works through the `/raw/` queue and pauses at governed decisions, one at a time.

**Session pattern:**
```
Agent:  I've processed 7 of 11 raw items autonomously.
        4 items need your input. Ready?

User:   Yes.

Agent:  Item 1 — Conflict
        Two captures describe ownership of the checkout error-handling flow.
        [cap_0301] assigns it to Payments domain.
        [cap_0302] assigns it to Orders domain.
        These are contradictory. Options:
          A) Assign to Payments
          B) Assign to Orders
          C) Shared — I'll draft a split-responsibility entry
          D) Flag as unresolved — add to decisions.md as open question
        Which do you choose?

User:   D — add a note that this needs an architecture call.

Agent:  Done. Moving to item 2...
```

### 4.5 Human Interaction Contract

- **One decision per message** — never batches questions
- **Always offers an escape hatch** — "flag as unresolved" is always a valid answer
- **Accepts natural language** — "go with B but note that..." is valid, not just "B"
- **Can be interrupted** — "skip for today" pauses the session; raw items remain in queue
- **Summarises at the end** — what changed, what's pending, what's open

### 4.6 Ambiguity as First-Class State

Unresolved ambiguity is not discarded — it lives in `decisions.md` as an open ADR:

```markdown
## [OPEN] ADR-012: Checkout error-handling ownership
Status: open
Captured: 2026-03-04
Flagged by: refine agent
Context: Conflicting captures from Payments and Orders domains.
Options: [A] Payments, [B] Orders, [C] Shared, [D] Unresolved
Decision: pending architecture call
```

This makes open ambiguities **queryable** in the Reason step.

### 4.7 Changelog

Every refine session appends to `changelog.md`:

```markdown
## 2026-03-04 — Refine Session

### Autonomous
- Merged cap_0298 into codebases.md (duplicate entry for payments-api)
- Summarised cap_0299 → new stakeholder: "Risk & Compliance team"
- Routed cap_0300 (type: other) → classified as requirement

### Governed (human decisions)
- cap_0301/0302 conflict: checkout error ownership → flagged open (ADR-012)
  Decided by: alice | Rationale: "needs architecture call"
- cap_0303: task promoted to requirement (auth token TTL must be configurable)
  Decided by: alice | Rationale: "confirmed by product owner"
```

---

## 5. Reason Layer

### 5.1 Query Classification

Before retrieving anything, the agent classifies the query along two dimensions:

**Topic scope** — which distilled files are likely relevant?
**Reasoning mode** — what kind of answer is expected?

| Reasoning Mode | Example Query | Candidate Files |
|---|---|---|
| `gap-analysis` | "What is the next thing to improve to pursue our vision?" | `domain.md`, `requirements.md`, `decisions.md` (open only) |
| `design-proposal` | "How should the new payment callback interface look?" | `interfaces.md`, `requirements.md`, `codebases.md`, `decisions.md` |
| `diagram` | "Provide a component diagram of the checkout flow" | `codebases.md`, `interfaces.md` |
| `stakeholder-query` | "Who owns the onboarding flow?" | `stakeholders.md`, `domain.md` |
| `decision-recall` | "Why was the retry strategy decided this way?" | `decisions.md`, `changelog.md` |

Files outside the candidate set are never loaded.

### 5.2 Two-Stage Retrieval

**Stage 1 — File-level routing (coarse)**
Based on query classification, a fixed mapping pre-selects candidate distilled files. This eliminates most irrelevant content before any fine-grained retrieval.

**Stage 2 — Chunk-level retrieval (fine)**
Within candidate files, each distilled entry is treated as a chunk. Retrieval is embedding-based similarity search over these chunks. Result: 3–8 highly relevant chunks, not entire files.

For large source documents (Section 3.4), a **Tier 2 retrieval** step runs similarity search against the source vector index when the query warrants detail beyond the distilled summary:

```
Tier 1 — Distilled chunk index    (always queried, high signal)
Tier 2 — Source document index    (queried when detail is needed)
```

Tier 2 is triggered by reasoning modes that require precision (`design-proposal`, compliance queries) and suppressed for structural overview modes (`diagram`, `gap-analysis`).

### 5.3 Retrieval Guardrails

- **Confidence threshold** — chunks below a similarity cutoff are excluded even from candidate files
- **Chunk count cap** — hard ceiling of 8 chunks forces selectivity; if exceeded, the agent notes that a more specific query may yield better results

### 5.4 Context Assembly

Retrieved chunks are assembled into a labelled context block injected ahead of the user query:

```
[DOMAIN CONTEXT — retrieved for this query]

From domain.md / Vision:
  "The Payments domain owns the full lifecycle of payment execution..."

From requirements.md / REQ-014:
  "All payment callbacks must be idempotent..."

From decisions.md / ADR-012 [OPEN]:
  "Error handling ownership unresolved between Payments and Orders..."

[END CONTEXT]

User query: "How should the new payment callback interface look?"
```

Labels tell the model where each piece of knowledge came from, enabling cited reasoning.

### 5.5 Reasoning Mode Templates

Each mode has a prompt template that governs how the model uses retrieved context:

**`gap-analysis`**
> Given the domain vision and current state of requirements and open decisions, identify the highest-leverage gap between where the domain is and where it should be. Name the specific requirement, interface, or decision most blocking progress. Do not speculate beyond the provided context.

**`design-proposal`**
> Given the existing interfaces, requirements, and relevant decisions, propose a design for [X]. Explicitly state: what you are preserving from current state, what you are changing and why, and any open questions requiring human resolution before adoption.

**`diagram`**
> Given the codebase and interface entries, produce a C4 component or sequence diagram in Mermaid. Include only components and relationships present in the context. Mark inferred relationships with a comment. Do not invent components.

### 5.6 Insufficient Context Handling

When retrieval doesn't find enough signal, the agent surfaces the gap rather than hallucinating:

```
Agent: I found the vision statement and two relevant requirements,
       but no interface definition for the current callback contract.

       To answer well, I'd need one of:
         - The current interface definition in interfaces.md
         - The relevant ADR if a design decision was already made

       Shall I capture that now, or proceed with what's available
       and flag the gaps explicitly?
```

This creates a feedback loop back to the Capture step — Reason surfaces what the knowledge base is missing.

### 5.7 Retrieval Stack Sizing

| Domain size | Approach |
|---|---|
| < 50 distilled chunks | Full candidate files fit in context — skip embedding search |
| 50–500 chunks | Local embedding index (sqlite-vec or single FAISS file) — no infrastructure needed |
| 500+ chunks | Hosted vector store (Pinecone, pgvector) — but this signals Refine needs to be more aggressive |

A growing distilled set is a smell. The Reason layer's retrieval cost is an indirect quality metric for the Refine step.

---

## 6. Integration Surfaces (v1)

### 6.1 VS Code / Cursor
- Capture command with minimal input form (title, type dropdown, optional tags)
- Frontmatter linter flags malformed raw items
- MCP connector to git repo for automatic commit (optional)

### 6.2 Claude.ai Projects
- System prompt configures capture, refine session, and reason behaviours
- `/capture`, `/refine`, and free-form queries all work in the same conversation
- MCP git connector enables automatic read/write to the domain repository

---

## 7. Technology Stack (v1)

| Concern | Choice | Rationale |
|---|---|---|
| Knowledge storage | Git repo (markdown) | Human-readable, diffable, no infrastructure |
| Retrieval (small domains) | In-context loading | Distilled set fits in Claude's context window |
| Retrieval (medium domains) | Local FAISS or sqlite-vec | No hosted infrastructure needed |
| Large document indexing | Local embedding + vector file | Added only when large docs are captured |
| Diagram output | Mermaid (C4 component, sequence) | Claude generates natively |
| IDE integration | VS Code extension + MCP | Works alongside existing development workflow |
| Chat integration | Claude.ai Projects + MCP | Persistent system prompt, git read/write |

---

## 8. Extension Seams

The three-layer architecture is designed to accept future capabilities at well-defined seams without restructuring the core pipeline.

```
                ┌─────────────────────────────────┐
                │         CAPTURE LAYER            │
New MCP ───────►│  Jira · Confluence · GitHub      │
sources         │  ADO · Slack · Custom APIs       │
                └────────────────┬────────────────┘
                                 │ raw items
                ┌────────────────▼────────────────┐
                │          REFINE LAYER            │
Specialist ────►│  Security Agent · Compliance     │
subagents       │  Consistency Checker · Linker    │
                └────────────────┬────────────────┘
                                 │ distilled knowledge
                ┌────────────────▼────────────────┐
                │          REASON LAYER            │
New query ─────►│  Roadmap Planner · Risk Assessor │
modes           │  Resource Estimator · Cross-domain│
                └─────────────────────────────────┘
```

**Capture extensions** — any new source just needs to produce a valid capture envelope. Zero impact on Refine or Reason.

**Refine extensions** — specialist subagents run in sequence over the raw queue, each with a narrow responsibility (security, compliance, cross-domain consistency). All operate on the same distilled files and respect the same human interaction contract.

**Reason extensions** — new reasoning capabilities are new prompt templates with their own retrieval routing rules. Cross-domain queries federate retrieval across multiple domain brains.

---

## 9. Suggested Iteration Path

```
v1 — Manual capture (VS Code + Claude.ai), single generalist refine agent,
     file-based retrieval for reason queries

v2 — MCP git connector for automatic capture commit,
     vector DB for large linked documents

v3 — Jira / Confluence MCP sources, automated capture triggers from CI/CD

v4 — Specialist refine subagents (security assessment, compliance checking)

v5 — Cross-domain federation, roadmap and resource planning reasoning modes
```

Each version is a working system. No version requires rearchitecting the previous one.

---

## 10. Self-Correcting Feedback Loop

The three layers form a coherent system with a natural quality signal flowing backwards:

```
Reason struggles to answer precisely
  → Refine was not aggressive enough in distilling
    → Capture was too noisy or missing key types

Reason surfaces "insufficient context"
  → A specific knowledge gap is identified
    → Capture is directed at the missing information
```

The system improves through use. Each Reason query that fails is a precise specification of what Capture and Refine should address next.
