# Quickstart: Domain Identity and Knowledge Seeding

**Feature**: 002-domain-identity-seed | **Date**: 2026-03-06

This guide walks through the complete frame → seed → refine → query cycle for a team
importing an existing knowledge base into a domain brain for the first time.

---

## Prerequisites

- Domain brain initialized (domain directory exists with `config/types.yaml`)
- Claude Code CLI installed and authenticated
- Existing documentation to import (Markdown files, PDFs, or web pages)

---

## Step 1: Frame the Domain Identity

Run `/frame` once before capturing or seeding anything. This tells the system — and your team
— what this domain brain is about.

```
/frame
```

The command pre-fills what it knows (domain name, steward, date) and asks you for:
- A one-line headline (≤15 words)
- A 3–5 sentence pitch
- An "In scope" list (≥1 item)
- An "Out of scope" list (≥1 item)

Example response:

```
One-line: Owns all financial transaction flows from cart to settlement confirmation.

Pitch: The Payments domain is responsible for checkout initiation, payment processing,
fraud detection handoff, and settlement confirmation. It owns the contracts between the
storefront and external payment processors, and the retry and error-handling logic for
failed transactions.

In scope:
- Checkout error handling and retry logic
- Payment processor integration contracts
- Settlement and refund workflows
- Fraud detection API integration (contract only; fraud logic is owned by Risk)

Out of scope:
- Fraud scoring algorithms (Risk domain)
- Order management and fulfillment (Orders domain)
- Customer identity and authentication (Platform domain)
```

Expected output:

```
Identity created: config/identity.md

  Domain:  payments
  Steward: alice
  One-line: Owns all financial transaction flows from cart to settlement confirmation.

Run /seed to import existing knowledge, or /capture to start adding items manually.
```

You can edit `config/identity.md` directly at any time. Re-run `/frame` to update it
interactively. Changes take effect at the next `/seed` or `/refine` invocation.

---

## Step 2: Seed from Existing Documentation

Point `/seed` at a source document or directory. The command reads it, segments it into
atomic knowledge items, filters by domain scope, and creates raw items in the queue.

### Single file

```
/seed docs/payments-runbook.md
```

### PDF

```
/seed specs/payment-processor-api-v3.pdf
```

### Directory (all `.md` and `.pdf` files)

```
/seed docs/payments/
```

### Web page (publicly accessible)

```
/seed https://wiki.example.com/payments/architecture
```

Expected output:

```
Seeding from: docs/payments/
Domain: payments | Identity: config/identity.md loaded

Processing 6 files...

Seed session complete.

Source: docs/payments/
  Created (in scope):     67 items
  Skipped (out of scope): 23 segments
  Flagged (uncertain):    11 items
  Unreadable:             0

Run /refine to process the 78 new items.
```

If the session hits the 100-item cap, re-run `/seed` on the same source. The command
automatically resumes from where it left off.

---

## Step 3: Refine the Seeded Queue

Run `/refine` as normal. The refine agent now has access to `config/identity.md` and
handles seeded items with scope awareness:

```
/refine
```

What to expect:

- **In-scope items with no flag**: processed identically to manually captured items —
  autonomous routing, or governed decision for normative content.
- **Items flagged `seed-note: Relevance uncertain`**: surface as governed decisions with an
  additional "not relevant — archive" option.

Example governed decision for a flagged item:

```
Decision required (3 of 11):

This item was flagged during seeding as potentially outside the domain scope.

Content: "The fraud scoring model uses a gradient boosted tree trained on 18 months
of transaction history, updated nightly by the ML Platform team."

This appears to describe the fraud scoring algorithm internals, which are listed as
out of scope for the Payments domain (owned by Risk / ML Platform).

Options:
  A. Archive it — out of scope for Payments domain
  B. Route to requirements.md — capture as a constraint on the fraud API contract
  C. Route to interfaces.md — capture as an interface dependency on ML Platform
  Z. Flag as unresolved (create open ADR)

You can reply with an option letter or describe your decision in natural language.
```

At the end of the refine session, a changelog entry records all autonomous actions and
governed decisions, including the out-of-scope archival count.

---

## Step 4: Query with Domain Context

After refining, query the domain brain. Responses now open with the domain identity framing:

```
/query Who owns checkout error handling?
```

```
Domain: Payments — Owns all financial transaction flows from cart to settlement confirmation.

Query mode: stakeholder-query
Candidates: domain.md, stakeholders.md

The Payments team owns all checkout error handling, including retry logic and user-facing
error messages. The tech lead is Alice.

Sources:
  - domain.md → "Payments Team Responsibilities"
  - stakeholders.md → "Alice — Payments Tech Lead"
```

---

## Verification Checklist

After completing steps 1–4, verify:

- [ ] `config/identity.md` exists with all required sections populated
- [ ] Running `/frame` again shows current values and allows updates
- [ ] After seeding, `raw/` contains items with `source.tool: seed` and correct `source.location`
- [ ] Ambiguous items have `seed-note: Relevance uncertain` in frontmatter
- [ ] After `/refine`, out-of-scope items are archived (not in any distilled file)
- [ ] Flagged items were presented as governed decisions with a "not relevant — archive" option
- [ ] `distilled/changelog.md` contains the refine session entry with autonomous action log
- [ ] `/query` responses open with the domain one-line framing statement

---

## Acceptance Scenario Walkthrough

**User Story 1 (Frame)**: Run `/frame` on a new domain brain (no `config/identity.md`).
Verify the file is created with all required sections. Re-run `/frame` — verify current
values are pre-filled and changes are applied without restarting.

**User Story 2 (Seed)**: Prepare a document with clearly in-scope, clearly out-of-scope, and
ambiguous sections (relative to the identity you created in US1). Run `/seed`. Verify the
three categories are correctly classified and reported in the session summary.

**User Story 3 (Scope-aware refine)**: After seeding the mixed document above, run `/refine`.
Verify: out-of-scope items are archived autonomously (no decision prompt); flagged items
produce governed decisions with the archive option; in-scope items are processed normally.

**User Story 4 (Query framing)**: Run any `/query` on a domain with a complete identity.
Verify the response header includes the one-line domain description. Then delete
`config/identity.md` and run the same query — verify it proceeds without error and without
the framing line.
