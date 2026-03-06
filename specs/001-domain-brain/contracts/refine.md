# Contract: /refine Command

**Command file**: `.claude/commands/refine.md`
**FR coverage**: FR-008–FR-015

---

## Invocation Syntax

```
/refine
/refine --domain <path>
/refine --limit <N>
```

## Arguments

| Argument | Required | Description |
|---|---|---|
| `--domain` | No | Path to domain brain root; uses default discovery if absent |
| `--limit N` | No | Process at most N raw items in this session; remainder stays in queue |

## Session Flow

```
1. LOAD      Load raw queue (all files in raw/ with status: raw)
2. ANNOUNCE  Report queue size and item titles to user
3. PROCESS   Invoke refine subagent with batch + distilled context
4. LOOP      For each item in batch:
               a. Autonomous action → execute silently, record in session log
               b. Governed decision  → surface to host, present to user one at a time
5. HUMAN     User responds to each governed decision in natural language
6. RECORD    Write governed decisions + rationale to session log
7. WRITE     Apply all changes to distilled files (host writes, never subagent directly)
8. COMMIT    Append changelog entry to distilled/changelog.md
9. REPORT    Show session summary
```

## Autonomous Actions (no human prompt required — FR-008)

The refine subagent performs these silently when confidence is high:

| Action | Condition |
|---|---|
| Merge duplicate | New item's content substantially overlaps an existing distilled entry |
| Summarise and route | Item type is clear and content is non-normative |
| Aggregate partial info | Item adds new facts to an existing entry without conflict |
| Classify `other` | Sufficient context to confidently assign a type from types.yaml |
| Archive raw item | Item has been successfully processed (set status: refined) |
| Split multi-type item | Item clearly contains multiple separable knowledge types |

## Governed Decisions (require human approval — FR-009)

The refine subagent surfaces these as structured decision requests:

| Trigger | Presented as |
|---|---|
| Conflicting responsibility claims | Two options + "flag as unresolved" |
| Low-confidence type classification | Candidate types with descriptions |
| Task promotion to requirement | Proposed requirement text + rationale |
| New ADR creation | Draft ADR with options |
| Deprecation of existing entry | Entry to be deprecated + reason |
| Inaccessible large document | Request for new source URL/path |
| Unknown `other` type after analysis | Type selection with descriptions |

## Governed Decision Presentation (FR-010, FR-011)

Each decision is presented one at a time in this format:

```
Decision required (1 of N):

[Clear description of the conflict or decision]

Options:
  A. [Option A]
  B. [Option B]
  ...
  Z. Flag as unresolved (create open ADR)

You can reply with an option letter or describe your decision in natural language.
```

The command accepts and correctly interprets natural language responses (FR-012). Examples:
- "go with A" → select option A
- "use option B but note that we need to revisit this" → select B, record note
- "leave it open for now" → flag as unresolved

## Pause and Resume (FR-013)

At any point the user may say "stop", "pause", or "skip for today". The command will:
1. Stop processing further items.
2. Leave all unprocessed raw items in the queue with status: raw.
3. Write the changelog entry for work completed so far.
4. Report how many items remain.

## Changelog Entry (FR-014)

At the end of every session (completed or paused), the command appends to `distilled/changelog.md`:

```markdown
## <YYYY-MM-DD> — Refine Session

### Autonomous actions
- [action]: [item-id] → [description of what was done]

### Governed decisions
- [item-id]: [decision topic] → [outcome]
  Decided by: <user> | Rationale: "[user's stated rationale]"

---
```

## Output

### Session Start

```
Raw queue: 7 items
  payments-20260305-a3f2 (responsibility) — Payments owns checkout error handling
  payments-20260305-b1c3 (other) — The checkout flow behaves differently on mobile
  ... [5 more]

Starting refine session...
```

### Session End (completed)

```
Refine session complete.

Autonomous: 5 items processed
  ✓ Merged 2 duplicates
  ✓ Routed 2 items to distilled files
  ✓ Classified 1 'other' item as requirement

Governed: 2 decisions
  ✓ ADR-012 created (checkout error ownership — flagged open)
  ✓ Task promoted to requirement (auth token TTL configurable)

Changelog updated: distilled/changelog.md
```

### Session Paused

```
Session paused. 3 items remain in queue.
Changelog updated with progress so far.
```

## Files Written

- `distilled/*.md` — updated with new/merged/deprecated entries (host only, never subagent)
- `distilled/changelog.md` — appended with session entry
- `raw/<id>.md` — status field updated to `refined` for processed items
