# Contract: /frame Command

**Command file**: `.claude/commands/frame.md`
**FR coverage**: FR-001–FR-006, FR-005a

---

## Invocation Syntax

```
/frame
/frame --domain <path>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

## Collection Flow

### First run (no existing `config/identity.md`)

1. Auto-populate `domain` (from directory name), `steward` (from `git config user.name`),
   `created` (today's date).
2. Present a single template prompt showing pre-filled and empty fields:

```
Creating config/identity.md for the "payments" domain.
Steward: alice | Created: 2026-03-06

Fill in the three sections below and reply. I'll create the file.

---
One-line (≤15 words):
[What does this domain own in one sentence?]

Pitch (3–5 sentences):
[What is this domain responsible for? What does it own end-to-end?]

In scope (list, one item per line, prefix with -):
- [e.g., Checkout error handling and retry logic]

Out of scope (list, one item per line, prefix with -):
- [e.g., Fraud scoring algorithms (Risk domain)]
---
```

3. Wait for the user's response.
4. Parse the response into `One-line`, `Pitch`, `In scope`, `Out of scope`.
5. Validate: all four sections non-empty; one-line ≤15 words; pitch ≥1 sentence; both lists
   ≥1 item. If invalid, output a specific error and prompt the user to retry.
6. Write `config/identity.md`.

### Re-run (existing `config/identity.md`)

1. Read `config/identity.md`. Load current values for all fields.
2. Present the same template with current values pre-filled:

```
Updating config/identity.md for the "payments" domain.
Current values shown — edit any field and reply, or say "keep" to leave unchanged.

---
One-line: Owns all financial transaction flows from cart to settlement confirmation.

Pitch: The Payments domain is responsible for checkout initiation...

In scope:
- Checkout error handling and retry logic
- Payment processor integration contracts

Out of scope:
- Fraud scoring algorithms (Risk domain)
---
```

3. Apply only fields the user changed. Preserve `created` from the original file.

### After writing

Check for existing raw items with `source.tool: seed` in `raw/`:
- If any exist: output a warning (FR-005a)
- If existing distilled entries exist: output a note recommending `/refine`

## Output

### First-run success

```
Identity created: config/identity.md

  Domain:  payments
  Steward: alice
  One-line: Owns all financial transaction flows from cart to settlement confirmation.

Run /seed to import existing knowledge, or /capture to start adding items manually.
```

### Re-run success

```
Identity updated: config/identity.md

  Changed: one-line, out-of-scope list

⚠ Warning: 47 seeded raw items in queue were classified under the previous identity.
  Their scope classifications may be stale. Run /refine to review them.
```

### Validation error

```
Error: Could not create identity — missing required fields: [Pitch, Out of scope].
Please provide all four sections and try again.
```

## Files Written

- `config/identity.md` — created on first run, updated on re-run
