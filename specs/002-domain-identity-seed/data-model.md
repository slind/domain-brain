# Data Model: Domain Identity and Knowledge Seeding

**Feature**: 002-domain-identity-seed | **Date**: 2026-03-06

Extends the data model from feature 001-domain-brain. Only new and modified entities are
documented here. Unchanged entities (Raw Item, Type Registry, Distilled Entry, etc.) are
defined in `../001-domain-brain/data-model.md`.

---

## Domain Identity

**File location**: `<domain-root>/config/identity.md`
**Created by**: `/frame` command
**Read by**: `/seed` (relevance filter), `/refine` (scope-aware archival), `/query` (answer framing)

### YAML Frontmatter

```yaml
---
domain: payments         # Name of the domain brain root directory; auto-populated by /frame
created: 2026-03-06      # Date /frame was first run; auto-populated; not updated on re-run
steward: alice           # Git user name of the domain steward; auto-populated by /frame
---
```

### Markdown Body

```markdown
# Payments Domain

**One-line**: Owns all financial transaction flows from cart to settlement confirmation.

**Pitch**: The Payments domain is responsible for checkout initiation, payment processing,
fraud detection handoff, and settlement confirmation. It owns the contracts between the
storefront and external payment processors, and the retry and error-handling logic for
failed transactions.

**In scope**:
- Checkout error handling and retry logic
- Payment processor integration contracts
- Settlement and refund workflows
- Fraud detection API integration (contract only; fraud logic is owned by Risk)

**Out of scope**:
- Fraud scoring algorithms (Risk domain)
- Order management and fulfillment (Orders domain)
- Customer identity and authentication (Platform domain)
```

### Field Definitions

| Field | Location | Type | Required | Auto-populated | Description |
|-------|----------|------|----------|----------------|-------------|
| `domain` | frontmatter | string | yes | yes — from directory name | Machine-readable domain identifier |
| `created` | frontmatter | ISO date | yes | yes — first run only | Date identity was first authored |
| `steward` | frontmatter | string | yes | yes — from git config | Primary maintainer of the identity document |
| One-line | body | string ≤15 words | yes | no — user provides | Single sentence stating what the domain owns |
| Pitch | body | 3–5 sentences | yes | no — user provides | Paragraph describing the domain's purpose and scope |
| In scope | body | list ≥1 item | yes | no — user provides | Capabilities and areas this domain definitively owns |
| Out of scope | body | list ≥1 item | yes | no — user provides | Areas explicitly NOT owned by this domain |

### Constraints

- `config/identity.md` MUST be human-readable and directly editable without any tool.
- The "Out of scope" list MUST have at least one item for the relevance filter in `/seed` to
  perform out-of-scope classification. If the list is empty, `/seed` treats all segments as
  ambiguous and warns the user.
- `/frame` sets `created` on first write only. Re-runs update all body fields and frontmatter
  `steward` but preserve the original `created` date.

---

## Seeded Raw Item

A seeded raw item is a standard raw item (defined in `../001-domain-brain/data-model.md`)
with two additional frontmatter fields. All existing fields and constraints apply.

**File location**: `<domain-root>/raw/<id>.md`
**Created by**: `/seed` command

### Additional Frontmatter Fields

```yaml
---
id: payments-20260306-c4f1
source:
  tool: seed                                  # FIXED value for all seeded items
  location: /path/to/doc.md                   # Origin file path or URL; REQUIRED for seeded items
type: responsibility                          # Inferred at seed time; same rules as /capture
domain: payments
tags: []
captured_at: 2026-03-06T10:15:00Z
captured_by: alice
status: raw
seed-note: "Relevance uncertain"              # OPTIONAL — present only for ambiguous segments
---
```

### seed-note Field

| Value | Meaning | Effect in /refine |
|-------|---------|-------------------|
| *(absent)* | Segment was confidently classified as in-scope | Processed identically to a manually captured item |
| `"Relevance uncertain"` | Segment could not be confidently classified | Surfaces as a governed decision; includes "not relevant — archive" as an option |

### source.tool Values

| Value | Set by | Meaning |
|-------|--------|---------|
| `claude-code` | `/capture` | Manually captured in a Claude Code session |
| `seed` | `/seed` | Bulk-imported from an existing document or URL |
| `chat` | future | Captured from a Claude chat session |
| `import` | future | Imported via authenticated API (Confluence, etc.) |

### Segment Title Derivation

The `# <title>` line in the raw item body is derived as follows:

1. If the segment was extracted from under a named heading (`##`, `###`): use that heading text as the title.
2. If the segment has no heading (body-only paragraph): Claude infers a ≤10-word title from the content.
3. The title MUST NOT be blank.

---

## Seed Session (in-memory only)

A seed session is not persisted to a file. It is an in-memory record maintained during a
single `/seed` invocation, used to generate the end-of-session summary.

### Session State

| Field | Type | Description |
|-------|------|-------------|
| `source` | string | The file path, URL, or directory provided by the user |
| `segments_examined` | int | Total candidate segments extracted from the source |
| `items_created` | int | Raw items written (in-scope segments) |
| `items_skipped` | int | Segments discarded (clearly out-of-scope) |
| `items_flagged` | int | Raw items written with `seed-note: Relevance uncertain` |
| `files_unreadable` | list | Files or URLs that could not be accessed |
| `cap_reached` | bool | Whether the 100-item cap was hit |
| `segments_remaining` | int | Segments not processed due to cap (0 if cap not reached) |
| `resume_offset` | int | Starting segment index for the next run (= items_created + items_flagged from prior runs) |

### Session Summary Output Format

```
Seed session complete.

Source: <source>
  Created (in scope):     <N> items
  Skipped (out of scope): <N> segments
  Flagged (uncertain):    <N> items
  Unreadable:             <N> files/URLs

Run /refine to process the new items.
```

If the cap was reached:

```
Session capped at 100 raw items. <N> segments remain unprocessed.
Re-run /seed on the same source to continue (will resume from segment <offset>).
```
