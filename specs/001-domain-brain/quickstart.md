# Quickstart: Software Domain Brain

**Feature**: 001-domain-brain | **Date**: 2026-03-05

This guide walks through initializing a domain brain for a team and running the first
capture → refine → query cycle.

---

## Prerequisites

- Claude Code CLI installed and authenticated
- A git repository for your domain's knowledge (can be an existing repo)

---

## Step 1: Initialize a Domain Brain

Copy the template domain directory from this repo into your knowledge repository:

```bash
cp -r domain/ my-payments-domain/
cd my-payments-domain/
git add .
git commit -m "init: domain brain for payments domain"
```

For single-domain repos, name it `domain/` and the commands will find it automatically.
For multi-domain repos, create a `.domain-brain-root` file at the git root:

```
echo "my-payments-domain/" > .domain-brain-root
```

---

## Step 2: Configure Types (Optional)

The default `config/types.yaml` covers the nine standard types. Edit it to add domain-specific
types or adjust routing:

```yaml
# Example: add a compliance-specific type
types:
  # ... default types ...
  - name: regulation
    description: "A regulatory requirement or compliance constraint from an external authority."
    routes_to: distilled/requirements.md
    example: "PSD2 requires Strong Customer Authentication for all payment flows over €30."
```

Changes take effect immediately at the next command invocation.

---

## Step 3: Capture Your First Item

From your IDE or terminal with Claude Code active:

```
/capture Payments team owns all checkout error handling including retry logic and user-facing error messages
```

Expected output:
```
Captured: payments-20260305-a3f2
  Type: responsibility
  File: raw/payments-20260305-a3f2.md
  Status: raw — ready for next refine session
```

Capture a few more items to build a meaningful queue:

```
/capture The checkout API emits a payment.completed event with orderId, amount, and currency fields
/capture We decided to use Kafka for all async domain events due to throughput requirements
/capture Alice is the tech lead for the Payments team
```

---

## Step 4: Run Your First Refine Session

```
/refine
```

The refine agent will process your raw queue. For a small queue it will likely handle
everything autonomously:

```
Raw queue: 4 items

Starting refine session...

Autonomous actions:
  ✓ Routed payments-20260305-a3f2 → domain.md (responsibility)
  ✓ Routed payments-20260305-b2c3 → interfaces.md (interface)
  ✓ Routed payments-20260305-c3d4 → decisions.md (new resolved ADR)
  ✓ Routed payments-20260305-d4e5 → stakeholders.md (stakeholder)

Refine session complete. Changelog updated.
```

If there are conflicts or ambiguous items, the refine agent will present each decision
one at a time for your input.

---

## Step 5: Query the Brain

```
/query Who owns checkout error handling?
```

```
Query mode: stakeholder-query
Candidates: domain.md, stakeholders.md

The Payments team owns all checkout error handling, including retry logic and user-facing
error messages. The tech lead is Alice.

Sources:
  - domain.md → "Payments Team Responsibilities"
  - stakeholders.md → "Alice — Payments Tech Lead"
```

Try other query types:

```
/query What interfaces does the payments domain expose?
/query What architectural decisions have been made?
/query What decisions are still pending?
/query Are there any gaps in our domain knowledge?
```

---

## Verification Checklist

After completing steps 1–5, verify:

- [ ] `raw/` contains at least one `.md` file with valid YAML frontmatter (status: refined after refine)
- [ ] `distilled/domain.md` contains the responsibility entry from Step 3
- [ ] `distilled/changelog.md` contains a session entry from Step 4
- [ ] `/query Who owns checkout error handling?` returns a cited answer
- [ ] Adding a new type to `types.yaml` and running `/capture` shows the new type without restart

---

## Acceptance Scenario Walkthrough

To verify all User Stories from spec.md:

**User Story 1 (Capture)**: Run `/capture` with only a description. Verify id, source,
domain, timestamp, and author are all auto-populated in the generated file.

**User Story 2 (Refine)**: Add two raw items with conflicting responsibility claims. Run
`/refine`. Verify the conflict triggers exactly one governed decision and the response is
recorded in the changelog.

**User Story 3 (Query)**: With a populated distilled base, run `/query Who owns the
onboarding flow?` Verify a cited answer is returned naming the team.

**User Story 4 (Large Documents)**: Capture an item referencing a document above ~10 pages.
Verify chunks appear in `index/` and a subsequent precision query returns chunk-level detail.

**User Story 5 (Open Decisions)**: Flag a conflict as unresolved during refine. Run
`/query what decisions are pending?`. Verify the open ADR appears with status and options.
