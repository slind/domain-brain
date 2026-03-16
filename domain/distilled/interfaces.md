# Interfaces

<!-- API contracts, event schemas, and integration points. Populated by /refine from captured 'interface' items. -->

## /capture Interface Contract
**Type**: interface
**Captured**: 2026-03-06
**Source**: domain-20260306-aa1b, domain-20260306-aa2c, domain-20260306-aa3d, domain-20260306-aa4e, domain-20260306-aa5f, domain-20260306-aa6a
**Describes**: .claude/commands/capture.md

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
**Describes**: .claude/commands/refine.md

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
| `responsibility` | responsibility | responsibilities.md (if present), identity.md |
| `codebase` | codebase | codebases.md, identity.md |
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

### Pre-filtered (host)
- [duplicate]: <item_id> → exact match in <matched_file>
- [out_of_scope]: <item_id> → matched term "<matched_term>"

### Semantic Duplicates       ← omit entirely if count is zero
- [semantic_duplicate]: <item_id> → archived
  Matched: <matched_entry>
  Basis: <similarity_basis>

### Autonomous actions
- [action]: [item-id] -> [description of what was done]

### Governed decisions
- [item-id]: [decision topic] -> [outcome]
  Decided by: <user> | Rationale: "[user's stated rationale]"

---
```

**Rules for Semantic Duplicates subsection** (Feature 005):
- MUST be omitted when no semantic duplicates were found. Never write an empty section.
- When present, appears after `### Pre-filtered (host)` and before `### Autonomous actions`.
- Each record includes `matched_entry` (the distilled entry matched) and `similarity_basis` (brief phrase explaining the overlap).

**Source**: [domain-20260313-b003]

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
**Describes**: .claude/commands/query.md

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
**Describes**: .claude/commands/frame.md

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
**Describes**: .claude/commands/seed.md

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

## config/similarity.md — Similarity Configuration
**Type**: interface
**Captured**: 2026-03-13
**Source**: domain-20260313-b001

Per-domain configuration file for semantic duplicate detection in `/refine`. If absent, the host applies the `moderate` default and surfaces a notice in the session output.

**File format** (`domain/config/similarity.md`):

```markdown
# Similarity Configuration

## Threshold

**Level**: moderate

<!-- Allowed values: conservative | moderate | aggressive
     conservative — filter only near-verbatim restatements
     moderate     — filter same core fact, different wording (DEFAULT)
     aggressive   — filter same topic, even with peripheral additions -->
```

**Governance**: Non-normative config file. Domain owners may edit it directly without a governed decision. Changes take effect on the next `/refine` invocation.

**Fallback behaviour**: If the file is absent or has an invalid `level` value, the host falls back to `moderate` and surfaces a warning in session output.

**Read by**: `/refine` host in Step 6; result stored in the `SimilarityConfig` in-memory session entity.

---

## /triage — Backlog Lifecycle Data Model
**Type**: interface
**Captured**: 2026-03-12
**Source**: [domain-20260312-f6a7, domain-20260312-a8b9, domain-20260312-b1c2, domain-20260312-c3d5, domain-20260312-d6e7]

Data model for the `/triage` command. Covers all persistent entities, structural conventions, and ephemeral artefacts involved in backlog lifecycle management.

### Entity 1: Backlog Entry (Extended)

Full entry format (after Feature 004 migration):

```markdown
## <Title>
**Type**: task
**Status**: open | in-progress | done
**Priority**: high | medium | low
**Captured**: YYYY-MM-DD
**Source**: [<raw-item-id>]

<Body text>

---
```

Field definitions:

| Field | Values | Default | Set by |
|---|---|---|---|
| `**Status**` | `open`, `in-progress`, `done` | `open` | `/refine` (initial); `/triage` (lifecycle) |
| `**Priority**` | `high`, `medium`, `low` | `medium` | `/refine` (initial, guidelines-driven); `/triage` (direct or AI-proposed) |
| `**Type**` | `task` (fixed) | — | `/refine` |
| `**Captured**` | YYYY-MM-DD | — | `/refine` |
| `**Source**` | raw item id | — | `/refine` |

Field placement rule: `**Status**` and `**Priority**` MUST appear directly after `**Type**`, in that order.

State transitions:
- `open` → `in-progress`: via `/triage "start N"`
- `open` → `done`: via `/triage "close N"` (requires rationale)
- `in-progress` → `done`: via `/triage "close N"` (requires rationale)
- `open`/`in-progress` → `done` (dropped): via `/triage "drop N"` governed decision
- No backward transitions. Once `done`, moved to `## Done` section, not re-opened.

Priority rules:
- Direct assignment: immediate write, no confirmation
- Hint-driven: AI proposes, user confirms before write
- Guidelines-driven: AI assigns at `/refine` time, based on `config/priorities.md`
- Manual flag: if user explicitly set priority, any AI-proposed change MUST be flagged with ⚠ in proposal table

### Entity 2: Done Section

Structural divider within `backlog.md` that collects completed entries. Not a separate file — a `## Done` heading within `backlog.md`.

Structure:

```markdown
# Backlog

## <open item 1>
...
---

## Done

## <done item 1>
**Status**: done
**Priority**: medium
...
---
```

Rules:
- `## Done` heading created by `/triage` on first close if it does not already exist
- All open items appear above `## Done`; all done items appear below it
- Done items retain all original fields (`Status: done`, `Priority` unchanged)
- Within Done section, items ordered by closure date (most recent last — append order)

### Entity 3: Priority Guidelines Document

Persistent file at `domain/config/priorities.md`. Human-editable. Read by priority subagent and `/refine` when processing new task items.

Required format:

```markdown
# Priority Guidelines

## Elevate to High
- <rule in plain English>

## Keep at Medium
- <rule in plain English>

## Defer to Low
- <rule in plain English>
```

Rules:
- File is optional. If absent, `/refine` defaults all new items to `medium`; `/triage` hint-driven works without it.
- Created by `/triage` on first "update guidelines" request (template + user rules in one exchange).
- Sections must use exact headings: `## Elevate to High`, `## Keep at Medium`, `## Defer to Low`.
- Each section contains bullet-point rules in natural language.
- Human may edit directly between triage sessions.

### Entity 4: Triage Changelog Entry

Appended to `domain/distilled/changelog.md` by `/triage` when a close or drop action is executed. Priority-only sessions do not generate a changelog entry.

Format:

```markdown
## YYYY-MM-DD — Triage Session

### Closed
- [close]: <raw-item-id> → <title>
  Rationale: "<user's words>"

### Dropped
- [drop]: <raw-item-id> → <title>
  Decision: <chosen option>
  Rationale: "<user's words>"

---
```

Rules:
- Multiple closes/drops in one session listed together under their subsection
- If session has only closes, omit `### Dropped` (and vice versa)
- Rationale is user's literal words; if none provided, record "no rationale provided"

### Entity 5: Priority Proposal (Ephemeral)

Generated by hint-driven or guidelines-driven subagent. Exists only during a triage session — never persisted to a file.

Subagent output format:

```json
PRIORITY_PROPOSAL:
[
  {
    "item_num": 2,
    "title": "Enterprise API Integration for /seed",
    "current": "medium",
    "proposed": "high",
    "reason": "matches enterprise integration hint",
    "was_manual": false
  }
]
```

Display format (shown to user before confirmation):

```
Proposed priority changes (N items):

  #  Title                                  Current → Proposed  Note
  2  Enterprise API Integration for /seed   medium  → high
  5  Semantic Duplicate Detection           medium  → high
 10  Multi-AI Host Support                  medium  → low       ⚠ previously manual

Apply these changes? (yes / no / select N,M to apply only some)
```

Validation rules:
- `was_manual: true` MUST produce ⚠ flag in display
- Proposed value must differ from current value (no no-op entries)
- `item_num` references sequential display number from current `/triage` session, not a stored ID

---

## /consistency-check Interface Contract
**Type**: interface
**Captured**: 2026-03-16
**Source**: specs/008-consistency-check
**Describes**: .claude/commands/consistency-check.md

### Invocation Syntax

```
/consistency-check
/consistency-check --domain <path>
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

### Session Flow

```
1. LOCATE     Domain brain root (same discovery logic as all other commands)
2. SCAN       Grep all distilled files for **Describes**: lines → build candidate list
3. DETECT     For each candidate: git-compare entry captured date vs. source file last-commit date
4. REPORT     List staleness candidates to steward (oldest-first by captured date)
5. RESOLVE    For each candidate: present dismiss / re-capture / archive options
6. RECORD     Append session summary to distilled/changelog.md
```

### Staleness Detection Logic

For each distilled entry with a `**Describes**: <path>` line:

1. Extract `captured_date` from `**Captured**: YYYY-MM-DD`
2. Run: `git log --format="%ai" -1 -- <describes_path> | cut -d' ' -f1` → `file_date`
3. If `file_date` is empty (file untracked or new): skip — not a candidate
4. If `<describes_path>` not found in working tree: surface as "source deleted"
5. If `captured_date < file_date`: surface as staleness candidate
6. Otherwise: skip silently

### Output Formats

**No candidates found**
```
Consistency check complete. No stale entries found.

All N tracked entries are current.
```

**Candidates found**
```
Consistency check — N stale entries found:

  [1] /refine Interface Contract   (interfaces.md)
      Describes: .claude/commands/refine.md
      Entry captured: 2026-03-06 | File last changed: 2026-03-16 (10 days)

  [2] ...

Review each entry? (yes / skip all / select N,M)
```

**Per-candidate resolution prompt**
```
Entry [1]: /refine Interface Contract

Options:
  A. Dismiss — not a material change (entry stays, flag cleared)
  B. Re-capture — I'll update the entry content now
  C. Archive — entry is no longer relevant (governed: requires rationale)

Your choice:
```

**Session complete**
```
Consistency check complete.

  Reviewed:    2
  Dismissed:   1
  Re-captured: 1
  Archived:    0

Changelog updated: distilled/changelog.md
```

**Source deleted**
```
Warning: 1 entry references a source file that no longer exists:
  - /refine Interface Contract → .claude/commands/refine.md (not found)

These entries need manual review. Include in session? (yes / skip)
```

### Governed Action: Archive

Archiving a distilled entry is a destructive governed action requiring explicit rationale:

```
Decision required: Archive "/refine Interface Contract"

This will remove the entry from interfaces.md. This action is logged and irreversible
without git revert.

One-line rationale:
```

No "flag as unresolved" option for archive decisions — the steward must provide a rationale or cancel.

### Changelog Entry Format

Appended to `distilled/changelog.md` at the end of every `/consistency-check` session:

```markdown
## YYYY-MM-DD — Consistency Check Session

### Candidates Found: N
- **<Entry Title>** (`<distilled-file>`) — describes `.claude/commands/<file>.md`, last updated YYYY-MM-DD (N days after capture)
- ...

### Resolutions
- [reviewed]: <Entry Title> — no material change
  Rationale: "<steward's words>"
- [re-captured]: <Entry Title> — content updated
  Rationale: "<steward's words>"
- [archived]: <Entry Title> — entry removed
  Rationale: "<steward's words>"

### Skipped (source deleted)
- <Entry Title> — `.claude/commands/<file>.md` no longer exists

---
```

Omit subsections that are empty. If no candidates were found, write:

```markdown
## YYYY-MM-DD — Consistency Check Session

No stale entries found. All tracked entries are current.

---
```

**Source**: [domain-20260316-9c5b]

### Files Written

- `distilled/*.md` — modified when entries are re-captured or archived (host only)
- `distilled/changelog.md` — appended with session summary

### Files Read

- All `distilled/*.md` files — scanned for `**Describes**` lines
- `config/identity.md` — soft-read for domain name in session header (non-blocking if absent)

---
