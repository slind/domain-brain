# Contract: /query Command

**Command file**: `.claude/commands/query.md`
**FR coverage**: FR-016–FR-023

---

## Invocation Syntax

```
/query <natural language question>
/query --mode <reasoning-mode> <question>
/query --domain <path> <question>
```

## Arguments

| Argument | Required | Description |
|---|---|---|
| `<question>` | Yes | Natural language question about the domain |
| `--mode` | No | Override reasoning mode (see modes below); usually auto-classified |
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

## Query Classification (FR-016)

Before retrieving any content, the command classifies the query by:

1. **Topic scope**: Which distilled files are candidates based on query content.
2. **Reasoning mode**: One of five supported modes.

### Reasoning Modes (FR-017)

| Mode | Trigger patterns | Files loaded | Second-stage retrieval |
|---|---|---|---|
| `gap-analysis` | "what's missing", "gaps", "what don't we know" | All distilled files | No |
| `design-proposal` | "how should we", "design", "approach", "proposal" | Relevant distilled + index | Yes |
| `diagram` | "show me", "map", "structure", "components", "draw" | domain, codebases, interfaces | No |
| `stakeholder-query` | "who owns", "who is", "who's responsible", "team" | domain, stakeholders | No |
| `decision-recall` | "decided", "why did we", "pending", "open decisions", "ADR" | decisions | No |

## Retrieval Strategy (FR-018, FR-023)

### By domain size

| Tier | Threshold | Strategy |
|---|---|---|
| Small | ≤50 distilled entries | Load all candidate files fully into context (Read) |
| Medium | 51–500 entries | Grep candidate files for keyword matches; load top-N chunks (Grep + Read) |

### Candidate file selection (FR-018)

Only files identified as candidates by query classification are loaded. Non-candidate files
are never loaded (FR-018).

### Chunk cap (FR-020)

A hard ceiling applies to the number of retrieved chunks. When the ceiling is reached:
- Ties broken by entry recency (most recently updated first).
- User is notified: "Context capped — consider a more specific query for better results."
- The answer is still attempted with available context.

### Second-stage retrieval (FR-022)

For `design-proposal` mode only: if the distilled summary is insufficient, the command
performs a second Grep pass against `index/<doc-id>/chunks/` files and loads matched chunks.

For `gap-analysis` and `diagram` modes: second-stage retrieval is suppressed; distilled
summaries only are used.

## Output

### Successful answer

```
Query mode: stakeholder-query
Candidates: domain.md, stakeholders.md

The Payments team owns the checkout flow end-to-end, including error handling, retry logic,
and user-facing error messages. The tech lead is Alice.

Sources:
  - domain.md → "Payments Team Responsibilities"
  - stakeholders.md → "Alice — Payments Tech Lead"
```

### Insufficient context (FR-021)

```
Query mode: design-proposal
Candidates: interfaces.md, requirements.md

I can answer partially, but the following knowledge is missing:

  Missing: No interface definition found for the current callback retry contract.

Would you like to capture this now? (/capture --type interface "callback retry contract")
Or proceed with the answer flagged as incomplete?
```

### Chunk cap reached (FR-020)

```
Note: Context capped at [N] chunks. Some potentially relevant entries may not be included.
For better results, try a more specific query (e.g., ask about a specific component or team).

[Answer based on available context follows...]
```

### Open decisions surfaced (FR-017, User Story 5)

When a query intersects an open ADR, the answer includes:

```
[Answer...]

Open decision intersects this topic:
  ⚠ ADR-012 [OPEN]: Checkout error-handling ownership — pending architecture call
    Options: A (Payments), B (Orders), C (Shared)
    Source: decisions.md → "ADR-012"
```
