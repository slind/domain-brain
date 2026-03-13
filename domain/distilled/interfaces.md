# Interfaces

<!-- API contracts, event schemas, and integration points. Populated by /refine from captured 'interface' items. -->

## /capture Interface Contract
**Type**: interface
**Captured**: 2026-03-06
**Source**: domain-20260306-aa1b, domain-20260306-aa2c, domain-20260306-aa3d, domain-20260306-aa4e, domain-20260306-aa5f, domain-20260306-aa6a

### Invocation Syntax

```
/capture <description>
/capture --title "Title text" --type <type> [description]
/capture --domain <path> <description>
```

### Arguments

| Argument | Required | Description |
|---|---|---|
| `<description>` | Yes (if no `--title`) | Free-form description of the knowledge item |
| `--title` | No | Explicit title; inferred from description if absent |
| `--type` | No | Explicit type from types.yaml; inferred from description if absent |
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

### Auto-Populated Envelope Fields

| Field | Generation rule |
|---|---|
| `id` | `<domain>-<YYYYMMDD>-<4-char-hex>` using current date and random hex |
| `source.tool` | Detected from invocation context (`claude-code`, `chat`, etc.) |
| `source.location` | Active file path or URL if available; omitted otherwise |
| `type` | Inferred from description using types.yaml examples; confirmed if ambiguous |
| `domain` | Inferred from domain brain root name or `.domain-brain-root` file |
| `captured_at` | Current UTC timestamp in ISO 8601 format |
| `captured_by` | Git user name or session identity |
| `status` | Always `raw` at capture time |

### Type Inference and Confirmation

If `--type` is provided explicitly: use it without inference; skip all phases below.

Otherwise, apply the three-phase inference sequence:

**Phase 1 — Signal scan** (applied first; fastest path)

Scan the title and body for the following signals. First match wins.

| Signal in title or body | Inferred type |
|---|---|
| MUST, SHALL, SHOULD, cannot, required, forbidden (as normative constraints) | `requirement` |
| API, event schema, endpoint, contract, integration protocol, interface definition | `interface` |
| why, because, rationale, trade-off, architectural decision, ADR | `decision` |
| "X owns", "X is responsible for", "X team handles" (ownership assertion) | `responsibility` |
| repository, service, library, tech stack, deployment, microservice | `codebase` |
| Person assigned to role, team, or title | `stakeholder` |
| TODO, backlog, spike, implement, fix, migrate (action item) | `task` |
| Meeting notes, call, standup, retro, decision log (meeting record) | `mom` |

If a signal fires with high confidence: assign type silently and skip Phases 2 and 3.

**Phase 2 — Description/example comparison** (fallback when no signal fires clearly)

Load `config/types.yaml`. Match description against each type's `description` and `example` fields.
- If confidence is high (clear match): assign type silently.
- If confidence is low (ambiguous): display type options with descriptions and ask for confirmation. Present one question only.

**Phase 3 — Last resort**

If no type scores clearly above the others after Phase 2: ask the user to select a type. Assign `other` only if the user explicitly chooses it or does not respond.

> **Note — /seed Step 7**: The same three-phase logic applies when `/seed` infers the type of a seeded raw item. The only difference is in Phase 3: `/seed` never asks the user — it assigns `other` silently when no type scores clearly above the others.

**Source**: [domain-20260312-5f3b]

### Output Formats

**Success**
```
Captured: payments-20260305-a3f2
  Type: responsibility
  File: raw/payments-20260305-a3f2.md
  Status: raw — ready for next refine session
```

**Validation Failure**
```
Error: Could not determine domain. Use --domain <path> or create a .domain-brain-root file.
Missing fields: [domain]
```

**Large Document Detected**
```
Large document detected: psd2-spec-v4.pdf (~42 pages)
Processing: chunking at logical boundaries...
  Created 38 chunks in index/psd2-spec-v4/
  Summary written to index/psd2-spec-v4/summary.md
Captured: payments-20260305-e5f6 (type: requirement, with chunk references)
```

### Files Written

- `raw/<id>.md` — the captured raw item

Optionally (large document):
- `index/<doc-id>/summary.md`
- `index/<doc-id>/chunks/chunk-NNNN.md` (one per chunk)

---

## /refine Interface Contract
**Type**: interface
**Captured**: 2026-03-06
**Source**: domain-20260306-ab1c, domain-20260306-ab2d, domain-20260306-ab3e, domain-20260306-ab4f, domain-20260306-ab5a, domain-20260306-ab6b, domain-20260306-ac1d, domain-20260306-ac2e, domain-20260306-ac3f, domain-20260306-ac4a

### Invocation Syntax

```
/refine
/refine --domain <path>
/refine --limit <N>
```

### Arguments

| Argument | Required | Description |
|---|---|---|
| `--domain` | No | Path to domain brain root; uses default discovery if absent |
| `--limit N` | No | Process at most N raw items in this session; remainder stays in queue |

### Session Flow

```
1. LOAD      Load raw queue (all files in raw/ with status: raw)
2. ANNOUNCE  Report queue size and item titles to user
3. PROCESS   Invoke refine subagent with batch + distilled context
4. LOOP      For each item in batch:
               a. Autonomous action -> execute silently, record in session log
               b. Governed decision  -> surface to host, present to user one at a time
5. HUMAN     User responds to each governed decision in natural language
6. RECORD    Write governed decisions + rationale to session log
7. WRITE     Apply all changes to distilled files (host writes, never subagent directly)
8. COMMIT    Append changelog entry to distilled/changelog.md
9. REPORT    Show session summary
```

### Specialist Routing

The `/refine` host routes each item to a TypeClusterBatch based on its type. Specialist clusters receive a reduced, focused context; the generalist cluster receives the full distilled context (identical to pre-Feature 003 behaviour).

| Item type | Cluster | Context files loaded |
|---|---|---|
| `requirement` | requirements | requirements.md, decisions.md, identity.md |
| `interface` | interfaces | interfaces.md, decisions.md, identity.md |
| `decision` | decisions | decisions.md, identity.md |
| `responsibility` | generalist | all distilled files, identity.md |
| `codebase` | generalist | all distilled files, identity.md |
| `stakeholder` | generalist | all distilled files, identity.md |
| `task` | generalist | all distilled files, identity.md |
| `mom` | generalist | all distilled files, identity.md |
| `other` | generalist | all distilled files, identity.md |

Context loading follows ADR-015: the host resolves routing targets before invoking the subagent. Items of type `other` (routes_to: null) trigger full load of all distilled files, consistent with ADR-015 behaviour.

**Source**: [domain-20260312-0c4a]

### Autonomous Actions

The refine subagent performs these silently when confidence is high:

| Action | Condition |
|---|---|
| Merge duplicate | New item's content substantially overlaps an existing distilled entry |
| Summarise and route | Item type is clear and content is non-normative |
| Aggregate partial info | Item adds new facts to an existing entry without conflict |
| Classify `other` | Sufficient context to confidently assign a type from types.yaml |
| Archive raw item | Item has been successfully processed (set status: refined) |
| Split multi-type item | Item clearly contains multiple separable knowledge types |

### Governed Decisions

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

### Governed Decision Presentation

Each decision is presented one at a time:

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

Natural language responses are accepted and correctly interpreted. Examples:
- "go with A" -> select option A
- "use option B but note that we need to revisit this" -> select B, record note
- "leave it open for now" -> flag as unresolved

### Pause and Resume

At any point the user may say "stop", "pause", or "skip for today". The command will:
1. Stop processing further items.
2. Leave all unprocessed raw items in the queue with status: raw.
3. Write the changelog entry for work completed so far.
4. Report how many items remain.

### Changelog Entry Format

Appended to `distilled/changelog.md` at end of every session (completed or paused):

```
## <YYYY-MM-DD> -- Refine Session

### Autonomous actions
- [action]: [item-id] -> [description of what was done]

### Governed decisions
- [item-id]: [decision topic] -> [outcome]
  Decided by: <user> | Rationale: "[user's stated rationale]"

---
```

### Output Formats

**Session Start**
```
Raw queue: 7 items
  payments-20260305-a3f2 (responsibility) -- Payments owns checkout error handling
  payments-20260305-b1c3 (other) -- The checkout flow behaves differently on mobile
  ... [5 more]

Starting refine session...
```

**Session End (completed)**
```
Refine session complete.

Autonomous: 5 items processed
  Merged 2 duplicates
  Routed 2 items to distilled files
  Classified 1 'other' item as requirement

Governed: 2 decisions
  ADR-012 created (checkout error ownership -- flagged open)
  Task promoted to requirement (auth token TTL configurable)

Changelog updated: distilled/changelog.md
```

**Session Paused**
```
Session paused. 3 items remain in queue.
Changelog updated with progress so far.
```

### Files Written

- `distilled/*.md` -- updated with new/merged/deprecated entries (host only, never subagent)
- `distilled/changelog.md` -- appended with session entry
- `raw/<id>.md` -- status field updated to `refined` for processed items

---

## /query Interface Contract
**Type**: interface
**Captured**: 2026-03-06
**Source**: domain-20260306-ad1e, domain-20260306-ad2f, domain-20260306-ad3a, domain-20260306-ad4b

### Invocation Syntax

```
/query <natural language question>
/query --mode <reasoning-mode> <question>
/query --domain <path> <question>
```

### Arguments

| Argument | Required | Description |
|---|---|---|
| `<question>` | Yes | Natural language question about the domain |
| `--mode` | No | Override reasoning mode; usually auto-classified |
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

### Query Classification and Reasoning Modes

Before retrieving any content, the command classifies the query by topic scope and reasoning mode.

| Mode | Trigger patterns | Files loaded | Second-stage retrieval |
|---|---|---|---|
| `gap-analysis` | "what's missing", "gaps", "what don't we know" | All distilled files | No |
| `design-proposal` | "how should we", "design", "approach", "proposal" | Relevant distilled + index | Yes |
| `diagram` | "show me", "map", "structure", "components", "draw" | domain, codebases, interfaces | No |
| `stakeholder-query` | "who owns", "who is", "who's responsible", "team" | domain, stakeholders | No |
| `decision-recall` | "decided", "why did we", "pending", "open decisions", "ADR" | decisions | No |

### Retrieval Strategy

**By domain size**

| Tier | Threshold | Strategy |
|---|---|---|
| Small | <=50 distilled entries | Load all candidate files fully into context (Read) |
| Medium | 51-500 entries | Grep candidate files for keyword matches; load top-N chunks (Grep + Read) |

**Candidate file selection**: Only files identified as candidates by query classification are loaded. Non-candidate files are never loaded.

**Chunk cap**: A hard ceiling applies to the number of retrieved chunks. When reached, ties broken by entry recency (most recently updated first). User is notified: "Context capped -- consider a more specific query for better results." Answer is still attempted with available context.

**Second-stage retrieval**: For `design-proposal` mode only -- if distilled summary is insufficient, a second Grep pass is performed against `index/<doc-id>/chunks/` files and matched chunks are loaded. Suppressed for `gap-analysis` and `diagram` modes.

### Output Formats

**Successful answer**
```
Query mode: stakeholder-query
Candidates: domain.md, stakeholders.md

The Payments team owns the checkout flow end-to-end, including error handling, retry logic,
and user-facing error messages. The tech lead is Alice.

Sources:
  - domain.md -> "Payments Team Responsibilities"
  - stakeholders.md -> "Alice -- Payments Tech Lead"
```

**Insufficient context**
```
Query mode: design-proposal
Candidates: interfaces.md, requirements.md

I can answer partially, but the following knowledge is missing:

  Missing: No interface definition found for the current callback retry contract.

Would you like to capture this now? (/capture --type interface "callback retry contract")
Or proceed with the answer flagged as incomplete?
```

**Chunk cap reached**
```
Note: Context capped at [N] chunks. Some potentially relevant entries may not be included.
For better results, try a more specific query (e.g., ask about a specific component or team).

[Answer based on available context follows...]
```

**Open decisions surfaced** (when query intersects an open ADR)
```
[Answer...]

Open decision intersects this topic:
  ADR-012 [OPEN]: Checkout error-handling ownership -- pending architecture call
    Options: A (Payments), B (Orders), C (Shared)
    Source: decisions.md -> "ADR-012"
```

---

## /frame Interface Contract
**Type**: interface
**Captured**: 2026-03-06
**Source**: domain-20260306-ae1a, domain-20260306-ae2b, domain-20260306-ae3c, domain-20260306-ae4d, domain-20260306-ae5e, domain-20260306-ae6f

### Invocation Syntax

```
/frame
/frame --domain <path>
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

### First-Run Collection Flow (no existing config/identity.md)

1. Auto-populate `domain` (from directory name), `steward` (from `git config user.name`), `created` (today's date).
2. Present a single template prompt showing pre-filled and empty fields.
3. Wait for the user's response.
4. Parse the response into `One-line`, `Pitch`, `In scope`, `Out of scope`.
5. Validate: all four sections non-empty; one-line <=15 words; pitch >=1 sentence; both lists >=1 item. If invalid, output a specific error and prompt the user to retry.
6. Write `config/identity.md`.

### Re-Run Collection Flow (existing config/identity.md)

1. Read `config/identity.md`. Load current values for all fields.
2. Present the same template with current values pre-filled.
3. Apply only fields the user changed. Preserve `created` from the original file.

### Post-Write Checks

After writing `config/identity.md`:
- If any raw items exist with `source.tool: seed` in `raw/`: output a warning that seeded items may have stale scope classifications.
- If existing distilled entries exist: output a note recommending `/refine`.

### Output Formats

**First-run success**
```
Identity created: config/identity.md

  Domain:  payments
  Steward: alice
  One-line: Owns all financial transaction flows from cart to settlement confirmation.

Run /seed to import existing knowledge, or /capture to start adding items manually.
```

**Re-run success**
```
Identity updated: config/identity.md

  Changed: one-line, out-of-scope list

Warning: 47 seeded raw items in queue were classified under the previous identity.
  Their scope classifications may be stale. Run /refine to review them.
```

**Validation error**
```
Error: Could not create identity -- missing required fields: [Pitch, Out of scope].
Please provide all four sections and try again.
```

### Files Written

- `config/identity.md` -- created on first run, updated on re-run

---

## /seed Interface Contract
**Type**: interface
**Captured**: 2026-03-06
**Source**: domain-20260306-af1a, domain-20260306-af2b, domain-20260306-af3c, domain-20260306-af4d, domain-20260306-af5e, domain-20260306-af6f, domain-20260306-af7a, domain-20260306-af8b

### Invocation Syntax

```
/seed <source>
/seed --domain <path> <source>
/seed --limit N <source>
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<source>` | Yes | Local file path, web URL, or directory path to import from |
| `--domain` | No | Path to domain brain root; uses default discovery if absent |
| `--limit N` | No | Override the default 100-item cap for this session |

### Session Flow

```
1. LOCATE     Domain brain root (same discovery logic as /capture, /refine, /query)
2. CHECK      config/identity.md exists -- error if missing
3. LOAD       config/identity.md into context (pitch, In scope list, Out of scope list)
4. DETECT     Source type (file, URL, directory); enumerate all target files
5. RESUME     Count existing raw items with source.location matching this source -> compute offset
6. SEGMENT    Split source content at logical boundaries (per source type)
7. FILTER     Classify each segment for relevance against the domain identity
8. WRITE      Create raw item files for in-scope and ambiguous segments
9. REPORT     Output session summary
```

### Source Type Handling

| Source type | Detection | Segmentation |
|-------------|-----------|--------------|
| Markdown file (.md) | file path ends in `.md` | Split at `##` headings; fall back to `###` or paragraph breaks for long sections |
| PDF file (.pdf) | file path ends in `.pdf` | Read in 10-page batches; split at detected headings or page boundaries |
| Web URL | starts with `http://` or `https://` | Fetch with Read tool; split by heading structure |
| Directory | path is a directory | Glob `.md` and `.pdf` files; apply per-file rules; report unsupported formats |

### Segment Eligibility

A segment is eligible to become a raw item only if it contains at least one complete, standalone knowledge claim. Segments that are only a heading, a single phrase, or boilerplate (e.g., table of contents, navigation, footers) are merged with the adjacent segment or discarded.

### Relevance Classification

Uses semantic judgment against `config/identity.md` -- not keyword matching alone.

| Classification | Condition | Action |
|----------------|-----------|--------|
| In scope | Topic clearly aligns with the "In scope" list and pitch | Create raw item, no `seed-note` |
| Out of scope | Topic clearly aligns with the "Out of scope" list | Skip; log reason in session summary |
| Ambiguous | Neither clearly in nor out; or identity scope lists are insufficient to judge | Create raw item with `seed-note: Relevance uncertain` |

If the "Out of scope" list in `config/identity.md` is empty: all segments are treated as ambiguous and the session summary warns the user.

### Session Cap

- Default cap: 100 raw items written per session (in-scope + flagged; skipped items do not count).
- Override with `--limit N`.
- When cap is reached: stop, report remaining segment count, report resume offset for next run.
- On re-run: auto-detect resume offset from count of existing raw items with matching `source.location`.

### Raw Item Structure

Each created raw item follows the standard raw item format with `source.tool: seed` and the source document path in `source.location`. Ambiguous segments have `seed-note: "Relevance uncertain"` in their frontmatter.

Title rule: Use the nearest section heading if present; otherwise infer a <=10-word title from the segment content. Title MUST NOT be blank.

### Output Formats

**Session in progress**
```
Seeding from: <source>
Domain: payments | Identity: config/identity.md loaded

Resuming from segment 101 (100 already seeded).
Processing segments 101-200...
```

**Session complete**
```
Seed session complete.

Source: path/to/document.md
  Created (in scope):     42 items
  Skipped (out of scope): 18 segments
  Flagged (uncertain):    7 items
  Unreadable:             0

Run /refine to process the 49 new items.
```

**Session complete -- cap reached**
```
Seed session complete. Cap reached at 100 raw items.

Source: path/to/large-doc.md
  Created (in scope):     82 items
  Skipped (out of scope): 31 segments
  Flagged (uncertain):    18 items
  Unreadable:             0

84 segments remain unprocessed.
Re-run /seed on the same source to continue (will resume from segment 202).
```

**Error -- missing identity**
```
Error: config/identity.md not found.
Run /frame first to define what this domain is about before seeding.
```

**Error -- unsupported file format (within directory seed)**
```
Skipped 3 unsupported files:
  - design-spec.docx  (export to PDF or Markdown first)
  - budget.xlsx       (export to Markdown first)
  - notes.pages       (export to PDF or Markdown first)
```

**Error -- inaccessible URL**
```
Skipped 1 inaccessible URL:
  - https://wiki.internal.example.com/payments (authentication required)
Export the page content to a local file and re-run /seed with the file path.
```

### Files Written

- `raw/<id>.md` -- one per in-scope or ambiguous segment (up to 100 per session)

---
