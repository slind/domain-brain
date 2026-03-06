# Data Model: Software Domain Brain

**Feature**: 001-domain-brain | **Date**: 2026-03-05

---

## Raw Item

**File location**: `<domain-root>/raw/<id>.md`
**Filename**: `<domain>-<YYYYMMDD>-<4-char-hex>.md` (matches `id` field)

### YAML Frontmatter

```yaml
---
id: payments-20260305-a3f2        # <domain>-<YYYYMMDD>-<4-char-hex>; auto-generated
source:
  tool: claude-code               # Capture tool: claude-code | chat | import; auto-populated
  location: /path/to/context      # Optional: file path, URL, or channel name; auto-populated
type: responsibility              # From types.yaml registry; required (inferred or user-provided)
domain: payments                  # Domain brain instance name; auto-populated
tags: []                          # Optional list of strings
captured_at: 2026-03-05T14:32:00Z # ISO 8601 timestamp; auto-generated
captured_by: alice                # Git user name or Claude session user; auto-populated
status: raw                       # raw | refined | archived
---
```

### Body

Completely free-form Markdown. May contain the original text, pasted content, a link to a
large document, or anything the user provides.

### State Transitions

```
raw → refined   (item processed in a refine session)
refined → archived  (cleaned up in subsequent refine pass)
```

---

## Type Registry

**File location**: `<domain-root>/config/types.yaml`
**Loaded**: at every `/capture` and `/refine` invocation (hot-reload by design)

### Schema

```yaml
types:
  - name: responsibility
    description: "Asserts which team, person, or service owns a domain area or capability."
    routes_to: distilled/domain.md
    example: "Payments owns checkout error handling end-to-end."

  - name: interface
    description: "Describes an API contract, event schema, or integration point between services."
    routes_to: distilled/interfaces.md
    example: "The checkout callback emits a payment.completed event with orderId and amount."

  - name: codebase
    description: "Describes a repository, service, or technical component and its ownership."
    routes_to: distilled/codebases.md
    example: "payments-api is owned by the Payments team, built in Node.js, deployed on AWS."

  - name: requirement
    description: "Captures a constraint, non-negotiable, or quality attribute the system must satisfy."
    routes_to: distilled/requirements.md
    example: "Checkout must complete in under 2 seconds at P99 under peak load."

  - name: stakeholder
    description: "Describes a person, team, or external party and their relationship to the domain."
    routes_to: distilled/stakeholders.md
    example: "Alice is the tech lead for the Payments team, responsible for architectural decisions."

  - name: decision
    description: "Records an architectural decision, its options, and its rationale (ADR)."
    routes_to: distilled/decisions.md
    example: "We chose Kafka over RabbitMQ for async events due to throughput requirements."

  - name: task
    description: "An actionable work item linked to a domain requirement or gap."
    routes_to: distilled/backlog.md
    example: "Add retry logic to the payment callback handler (linked to REQ-007)."

  - name: mom
    description: "Minutes of meeting — captures decisions, action items, and context from a discussion."
    routes_to: distilled/changelog.md
    example: "Architecture call 2026-03-04: agreed that Payments owns checkout error handling."

  - name: other
    description: "Unclassified item. The refine agent will attempt to classify it during refinement."
    routes_to: null   # Refine agent determines routing
    example: "The checkout flow behaves differently on mobile browsers."
```

### Field Definitions

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Type identifier used in raw item frontmatter |
| `description` | string | yes | Shown during capture alongside the type name (FR-003b) |
| `routes_to` | string or null | yes | Relative path from domain root to target distilled file; null for `other` |
| `example` | string | yes | One illustrative sentence; used by refine agent for classification inference |

---

## Distilled Entry

**File location**: `<domain-root>/distilled/<file>.md`

Each distilled file contains one or more entries. Entries are separated by `---` horizontal
rules. Each entry has a level-2 heading as its title.

### Standard Entry Format

```markdown
## [Entry Title]

[Entry content — structured prose, bullet lists, or tables as appropriate]

**Last updated**: 2026-03-05 | **Source items**: [payments-20260305-a3f2, payments-20260305-b1c3]

---
```

### ADR Entry Format (decisions.md)

```markdown
## [OPEN] ADR-012: Checkout error-handling ownership

**Status**: open
**Captured**: 2026-03-04
**Context**: Conflicting captures from Payments and Orders teams — both claim ownership.
**Options**:
- A: Payments team owns it
- B: Orders team owns it
- C: Shared responsibility with defined boundary
**Flagged by**: refine agent
**Pending**: architecture call

---

## [RESOLVED] ADR-011: Event bus selection

**Status**: resolved
**Decision**: Use Kafka for all async domain events.
**Rationale**: Higher throughput than RabbitMQ; team already has operational expertise.
**Decided by**: alice | **Date**: 2026-03-01

---
```

### Distilled Files and Their Purpose

| File | Types routed here | Content |
|---|---|---|
| `domain.md` | responsibility | Team ownership, domain vision, high-level responsibilities |
| `codebases.md` | codebase | Repos, services, tech stack, ownership |
| `interfaces.md` | interface | API contracts, event schemas, integration points |
| `requirements.md` | requirement | Constraints, NFRs, quality attributes |
| `stakeholders.md` | stakeholder | People, teams, external parties |
| `decisions.md` | decision | Open and resolved ADRs |
| `backlog.md` | task | Actionable work items |
| `changelog.md` | mom + audit | MoM content + refine session audit trail |

---

## Changelog Entry

**File location**: `<domain-root>/distilled/changelog.md`
**Appended**: at the end of every refine session (FR-014)

```markdown
## 2026-03-05 — Refine Session

### Autonomous actions
- Merged payments-20260305-a3f2 into domain.md (duplicate responsibility entry for checkout)
- Routed payments-20260305-b1c3 (type: other → classified as requirement, confidence: high)
- Archived payments-20260304-ff01 (refined in previous session, cleaned up)

### Governed decisions
- payments-20260305-c9d2: checkout error-handling ownership conflict → flagged open (ADR-012)
  Decided by: alice | Rationale: "needs architecture call — both teams have valid claims"
- payments-20260305-d4e5: task promoted to requirement (auth token TTL must be configurable)
  Decided by: alice | Rationale: "confirmed by product owner in today's sync"

---
```

---

## Large Document Index

**Directory**: `<domain-root>/index/<doc-id>/`

```text
index/
└── psd2-spec-v4/
    ├── summary.md          # ≤500 word summary; loaded by default retrieval
    └── chunks/
        ├── chunk-0001.md   # ~500-token chunk at logical boundary (heading or paragraph)
        ├── chunk-0002.md
        └── ...
```

### Distilled Entry Reference (when large document is the source)

```markdown
## REQ-014 — PSD2 Strong Customer Authentication

Summary: All payment callbacks must comply with PSD2 SCA requirements per EBA guidelines.
Detail-source: psd2-spec-v4
Chunk-ids: [chunk-0042, chunk-0043, chunk-0044]

**Last updated**: 2026-03-05 | **Source items**: [payments-20260305-e5f6]

---
```

---

## Knowledge Chunk

**File location**: `<domain-root>/index/<doc-id>/chunks/chunk-NNNN.md`

Each chunk is a standalone, self-contained passage from the source document with a brief
header indicating its origin.

```markdown
---
doc-id: psd2-spec-v4
chunk-id: chunk-0042
source-location: "§ 4.2 Authentication Methods"
---

[Chunk content — verbatim or lightly cleaned passage from source document]
```
