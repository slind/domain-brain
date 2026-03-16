# Codebases

<!-- Repositories, services, tech stack, and ownership. Populated by /refine from captured 'codebase' items. -->

## Raw Item

The fundamental unit of captured knowledge in Domain Brain. A Raw Item represents a single piece of domain knowledge captured from any source, in unprocessed form awaiting refinement.

**File location**: `<domain-root>/raw/<id>.md`
**Filename convention**: `<domain>-<YYYYMMDD>-<4-char-hex>.md` — filename matches the `id` frontmatter field, enabling discovery without parsing frontmatter.

**YAML frontmatter fields**:
- `id`: matches filename (e.g., `domain-20260306-a1b2`)
- `source.tool`: one of `claude-code` | `seed` | `chat` | `import`
- `source.location`: origin path or URL
- `type`: value from `config/types.yaml`
- `domain`: domain name
- `tags`: list of free-form tags
- `captured_at`: ISO 8601 timestamp
- `captured_by`: identity of capturer
- `status`: one of `raw` | `refined` | `archived`

**Body**: Free-form Markdown containing the captured knowledge.

**State transitions**:

| Transition | Trigger | Set by |
|---|---|---|
| `raw` → `refined` | Processed in a refine session (subagent) | Refine subagent, Steps 9/10 |
| `raw` → `refined` (duplicate) | Exact body match found in distilled files during host pre-filter | Host Step 6.5 |
| `raw` → `refined` (out-of-scope) | High-confidence Out-of-scope match during host pre-filter | Host Step 6.5 |
| `refined` → `archived` | Cleaned up after distillation | Post-session cleanup |

The two pre-filter transitions (duplicate, out-of-scope) bypass subagent invocation entirely; no new distilled entry is created.

**Type**: codebase
**Source items**: [domain-20260306-a9b0, domain-20260312-a1b3]

---

## Seeded Raw Item

A Seeded Raw Item extends the Raw Item entity with additional fields set by the `/seed` command. It represents a knowledge segment extracted from a document during a seed session, which may be flagged for human review if domain relevance is uncertain.

**File location**: `<domain-root>/raw/<id>.md` (same location as Raw Item)
**Extends**: Raw Item — all Raw Item fields apply.

**Additional frontmatter fields**:
- `source.tool`: FIXED to `"seed"` for all seeded items (distinguishes from `claude-code`, `chat`, `import`)
- `source.location`: REQUIRED — must reference the source document path or URL
- `seed-note: "Relevance uncertain"`: OPTIONAL — present only when the segment's domain relevance is ambiguous

**Segment title**: Derived from the heading text if a heading is present, otherwise inferred as a ≤10-word descriptive title.

**Processing in /refine**:
- `seed-note` absent → processed identically to a manually captured item
- `seed-note` present → triggers a governed decision in `/refine` with "Archive — not relevant" presented as the first option

**Type**: codebase
**Source items**: [domain-20260306-d3e4]

---

## Type Registry

The type registry defines the classification vocabulary for raw items and controls routing to distilled files. Loaded fresh at every `/capture` and `/refine` invocation (hot-reload by design — see ADR-002).

**File location**: `<domain-root>/config/types.yaml`

**Schema**: 9 built-in types: `responsibility`, `interface`, `codebase`, `requirement`, `stakeholder`, `decision`, `task`, `mom`, `other`.

**Per-type fields**:
- `name`: type identifier
- `description`: human-readable description of when to use this type
- `routes_to`: distilled file path (e.g., `distilled/decisions.md`), or `null` for `other`
- `example`: one sentence illustrating a canonical use

**Special case**: Type `other` has `routes_to: null`. The refine agent determines appropriate routing during the refinement step for items of this type.

**Type**: codebase
**Source items**: [domain-20260306-c1d2]

---

## Domain Identity

The Domain Identity document establishes the scope, ownership, and purpose of a Domain Brain instance. It is created by `/frame` and read by `/seed` (relevance filter), `/refine` (scope-aware archival), and `/query` (answer framing).

**File location**: `<domain-root>/config/identity.md`

**Schema** (see also ADR-010):
- YAML frontmatter: `domain` (from directory name), `created` (first-run only, preserved on re-run), `steward` (from `git config user.name`)
- Markdown body:
  - `**One-line**`: ≤15-word description of the domain
  - `**Pitch**`: 3–5 sentence explanation of the domain's value
  - `**In scope**`: list of ≥1 topic areas that belong to this domain brain
  - `**Out of scope**`: list of ≥1 topic areas explicitly excluded

**Constraints**:
- Must be human-readable and directly editable by non-technical stewards
- `Out of scope` MUST have ≥1 item for the `/seed` relevance filter to function
- `/frame` preserves the `created` field on re-runs (never overwrites with a new date)

**Type**: codebase
**Source items**: [domain-20260306-b1c2]

---

## Distilled Entry

A Distilled Entry is the refined, governed representation of one or more raw items, stored in a typed distilled file. Distilled files are the primary retrieval source for `/query`.

**File location**: `<domain-root>/distilled/<file>.md`
**Separation**: Entries within a file are separated by `---`.
**Title**: Each entry begins with a level-2 heading (`## Title`).

**Standard format**:
```
## Title
<content>
**Last updated**: <date> | **Source items**: [<ids>]
```

**ADR format** (decisions.md only):
```
## [OPEN|RESOLVED] ADR-NNN: <title>
**Status**: Open | Resolved
**Captured**: <date>
**Context**: <why this arose>
**Options considered**: <options>
**Decision**: <what was decided>
**Rationale**: <why>
**Source items**: [<ids>]
```

**Distilled file routing**:
- `domain.md` ← responsibility items
- `codebases.md` ← codebase items
- `interfaces.md` ← interface items
- `requirements.md` ← requirement items
- `stakeholders.md` ← stakeholder items
- `decisions.md` ← decision items
- `backlog.md` ← task items
- `changelog.md` ← mom items + audit trail

**Type**: codebase
**Source items**: [domain-20260306-e3f4]

---

## Changelog Entry

The Changelog Entry records the audit trail of every refine session, capturing both autonomous actions taken by the refine subagent and governed decisions made by the human steward.

**File location**: `<domain-root>/distilled/changelog.md`
**Write pattern**: Appended at the end of every refine session (never edited in place).

**Format**:
```
## YYYY-MM-DD — Refine Session

### Autonomous actions
- <action>: <item-id> → <description>

### Governed decisions
- <item-id>: <conflict type> → <outcome>
  Decided by: <name> | Rationale: "<text>"

---
```

**Type**: codebase
**Source items**: [domain-20260306-a5b6]

---

## Large Document Index

The Large Document Index stores chunked representations of documents too large to hold in context as a single unit during retrieval. Used when a source document exceeds ~10 pages / ~5000 tokens (see ADR-005).

**Directory structure**: `<domain-root>/index/<doc-id>/`

**Contents**:
- `summary.md`: ≤500-word summary of the document, loaded by default retrieval
- `chunks/chunk-NNNN.md`: sequentially numbered ~500-token chunks split at logical boundaries

**Integration with distilled entries**: When a large document is the source of a distilled entry, the entry references it with:
- `Detail-source: <doc-id>`
- `Chunk-ids: [<chunk-list>]`

**Second-stage retrieval**: Grep chunks for query terms, then load only matched chunks — avoids loading the entire document for every query.

**Type**: codebase
**Source items**: [domain-20260306-c7d8]

---

## Knowledge Chunk

A Knowledge Chunk is a single self-contained passage from a large document, stored as part of the Large Document Index. Chunks enable targeted second-stage retrieval without loading an entire large document.

**File location**: `<domain-root>/index/<doc-id>/chunks/chunk-NNNN.md`

**YAML frontmatter fields**:
- `doc-id`: identifier of the parent document
- `chunk-id`: sequential chunk identifier (e.g., `chunk-0001`)
- `source-location`: origin path or URL of the source document

**Body**: Verbatim or lightly cleaned passage from the source document. Each chunk is standalone and self-contained — interpretable without reading adjacent chunks.

**Type**: codebase
**Source items**: [domain-20260306-e9f0]

---

## Seed Session

A Seed Session is an in-memory record maintained during a single `/seed` invocation. It tracks progress across the document segmentation and filtering process but is never persisted to disk — the raw items created are the durable record (see ADR-011).

**Persistence**: In-memory only. Not written to any file.

**Fields**:
- `source`: location of the document being seeded
- `segments_examined`: total count of segments evaluated
- `items_created`: count of raw items written (in-scope)
- `items_skipped`: count of segments classified as out-of-scope
- `items_flagged`: count of items written with `seed-note: "Relevance uncertain"`
- `files_unreadable`: count of files that could not be read
- `cap_reached`: boolean — true if the 100-item cap was hit
- `segments_remaining`: count of unprocessed segments if cap was reached
- `resume_offset`: number of items to skip on re-run (derived from existing raw items with matching source.location)

**Type**: codebase
**Source items**: [domain-20260306-f5a6]

---

## Refine Pipeline — Type Clusters and Subagents
**Type**: codebase
**Captured**: 2026-03-12
**Source**: [domain-20260312-f0a7]
**Describes**: .claude/commands/refine.md

The refine pipeline routes raw items to specialised processing tracks based on their type. Three concepts support this routing:

**Type cluster**: A named grouping of related item types that maps to a single specialist subagent. Feature 006 extended the roster from three to five specialist clusters: `requirements`, `interfaces`, `decisions`, `codebase`, and `responsibility`. The generalist cluster remains the fallback. Each cluster receives only the distilled context files relevant to its types, keeping the subagent's context window focused.

**Specialist subagent**: An Agent-tool invocation with a focused context window scoped to one type cluster. Receives only the items and distilled files for its cluster, produces a `SpecialistPlan`, and returns it to the host for merging. The new `codebase` and `responsibility` specialists (Feature 006) reuse the same instruction template as the original three specialists from Feature 003.

**Generalist subagent**: The existing single subagent, retained as the fallback cluster for `stakeholder`, `task`, `mom`, `other`, and unrecognised types. Behaviour is unchanged from Feature 003.

**Context file set**: The specific subset of distilled files passed to a specialist. Defined per cluster in the routing table:
- `requirements` → requirements.md, decisions.md, identity.md
- `interfaces` → interfaces.md, decisions.md, identity.md
- `decisions` → decisions.md, identity.md
- `codebase` → codebases.md, identity.md
- `responsibility` → responsibilities.md (if present), identity.md
- `generalist` → all distilled files, identity.md

**Source**: [domain-20260312-f0a7, domain-20260313-d5a6]

---

## PreFilterResult
**Type**: codebase
**Captured**: 2026-03-12
**Source**: [domain-20260312-e2f9, domain-20260313-b002]

An in-memory data structure produced by Step 6.5 of `/refine`. Represents a single raw item that was resolved by the host pre-filter before any subagent was invoked. Never written to disk; recorded only in the session log for the changelog.

**Fields**:
- `item_id` (string): the raw item id that was pre-filtered
- `filter_reason` (`"duplicate"` | `"out_of_scope"` | `"semantic_duplicate"`): the reason the item was resolved early — `semantic_duplicate` added in Feature 005
- `matched_file` (string | null): the distilled file where the duplicate body was found, or `null` for out-of-scope and semantic-duplicate matches
- `matched_term` (string | null): the Out-of-scope term that matched, or `null` for duplicate/semantic-duplicate
- `matched_entry` (string | null): *(Feature 005)* title or ID of the distilled entry that is the semantic match; `null` for non-semantic-duplicate reasons
- `similarity_basis` (string | null): *(Feature 005)* brief phrase explaining the semantic overlap; `null` for non-semantic-duplicate reasons

**Persistence**: In-memory only. Not written to any file.

---

## TypeClusterBatch
**Type**: codebase
**Captured**: 2026-03-12
**Source**: [domain-20260312-4a8c]

An in-memory data structure produced by the refine host after pre-filtering, immediately before specialist subagent invocation. Groups raw items by their assigned type cluster for focused processing. Never persisted to disk.

**Fields**:
- `cluster` (`"requirements"` | `"interfaces"` | `"decisions"` | `"generalist"`): the cluster this batch targets
- `items` (RawItem[]): the raw items routed to this cluster
- `context_files` (string[]): paths to the distilled files that should be loaded as context for this cluster's subagent

**Lifecycle**: Created by the host routing step; consumed immediately by specialist subagent invocation; discarded after the `SpecialistPlan` is returned.

**Persistence**: In-memory only. Not written to any file.

---

## SpecialistPlan
**Type**: codebase
**Captured**: 2026-03-12
**Source**: [domain-20260312-6b2d]

The REFINE_PLAN returned by a specialist subagent after processing its `TypeClusterBatch`. Contains the autonomous actions and governed decisions produced for that cluster's items. Not persisted directly — merged into the session's `MergedRefinePlan` before execution.

**Fields**:
- `cluster` (string): the cluster name this plan originated from (e.g., `"requirements"`)
- `autonomous_actions` (AutonomousAction[]): actions that can be executed without human approval
- `governed_decisions` (GovernedDecision[]): decisions that require human input before execution

**Lifecycle**: Returned by the specialist subagent; immediately merged into `MergedRefinePlan` by the host; not stored separately.

**Persistence**: In-memory only. Not written to any file.

---

## MergedRefinePlan
**Type**: codebase
**Captured**: 2026-03-12
**Source**: [domain-20260312-9e1f]

The concatenation of all `SpecialistPlan` instances returned by the specialist subagents in a single refine session. Consumed by Steps 8–10 of `/refine` to execute autonomous actions and present governed decisions to the human steward.

**Fields**:
- `autonomous_actions` (AutonomousAction[]): union of all autonomous actions across all specialist plans
- `governed_decisions` (GovernedDecision[]): union of all governed decisions across all specialist plans

**Construction**: The host iterates over all `TypeClusterBatch` invocations, collects each resulting `SpecialistPlan`, and concatenates their action lists. Order of actions within each list is preserved; cluster ordering follows the routing sequence.

**Persistence**: In-memory only. Not written to any file.

---

## SimilarityConfig
**Type**: codebase
**Captured**: 2026-03-13
**Source**: [domain-20260313-b004]

A session-scoped in-memory entity loaded by the `/refine` host in Step 6. Holds the resolved similarity threshold for use in Step 6.5c semantic duplicate detection. Never persisted to disk.

**Fields**:
- `level` (`"conservative"` | `"moderate"` | `"aggressive"`): the threshold to apply when comparing raw items against distilled entries
- `source` (`"config/similarity.md"` | `"default"`): indicates whether the threshold was read from the domain config file or fell back to the default

**Threshold semantics**:
- `conservative` — filter only near-verbatim restatements
- `moderate` — filter same core fact, different wording (default)
- `aggressive` — filter same topic, even with peripheral additions

**Fallback**: When `source` is `"default"`, the host surfaces the notice: `No similarity config found — using default threshold: moderate.`

**Lifecycle**: Created during `/refine` Step 6 by reading `config/similarity.md`; consumed in Step 6.5c; discarded at session end.

**Persistence**: In-memory only. Not written to any file.

---

## Describes-Link Convention
**Type**: codebase
**Captured**: 2026-03-16
**Source**: specs/008-consistency-check

An opt-in field added to distilled entries to enable automated staleness detection by the `/consistency-check` command. When present, it creates a tracked link from a distilled entry to the source file it documents.

**Format**:
```markdown
## <Entry Title>
**Type**: interface
**Captured**: YYYY-MM-DD
**Source**: <raw-item-ids>
**Describes**: .claude/commands/<command-name>.md

<entry content>

---
```

**What it signals**: This distilled entry documents the behaviour of the named source file. When the source file changes (as detected by `git log`), the entry may be stale and should be reviewed.

**Format rules**:
- The path is relative to the repository root.
- The `**Describes**` line appears in the entry metadata block, after `**Source**` and before the entry body.
- Only one `**Describes**` line per entry is supported (v1 constraint — one source file per entry).
- The path should refer to a file that is tracked in git. Untracked files are ignored by the command.

**How `/consistency-check` discovers it**: The command greps all `distilled/*.md` files for the literal string `**Describes**: ` and parses the path that follows. No YAML frontmatter change is required.

**Opt-in, not mandatory**: Entries without a `**Describes**` line are never surfaced as staleness candidates. The convention is applied selectively to entries that document a specific implementation artefact (e.g., a command file's interface contract).

**Source-deleted edge case**: If the file at the `describes_path` no longer exists in the working tree (renamed, deleted, moved), the entry is surfaced as "source deleted" rather than stale — these require manual review to determine whether the entry should be updated, kept, or archived.

---

## Staleness Candidate
**Type**: codebase
**Captured**: 2026-03-16
**Source**: [domain-20260316-9c1d]

A distilled entry identified as potentially stale because its `**Captured**` date predates the last git commit to its source command file. Produced during a `/consistency-check` run; never written to disk as a separate file.

**Staleness condition**: `captured_date < file_last_commit_date` AND `describes_file` is non-null and the file exists in the repo.

**Fields**:

| Field | Type | Source |
|-------|------|--------|
| `entry_title` | string | Level-2 heading (`## Title`) of the distilled entry |
| `entry_file` | string | Path to the distilled file (e.g., `domain/distilled/interfaces.md`) |
| `captured_date` | YYYY-MM-DD | `**Captured**: YYYY-MM-DD` field in the distilled entry |
| `describes_file` | string | `**Describes**: <path>` line in the entry content; `null` if absent |
| `file_last_commit_date` | YYYY-MM-DD | Output of `git log --format="%ai" -1 -- <describes_file>`, date portion |
| `staleness_days` | integer | `file_last_commit_date - captured_date` in days (approximate, for display) |
| `status` | enum | `pending` (awaiting review) |

**Not a staleness candidate**:
- Entry has no `**Describes**` field → skip (not tracked)
- `describes_file` not found in git history → surface as "source deleted" (distinct case)
- `captured_date >= file_last_commit_date` → not stale, skip silently

**Persistence**: In-memory only during a `/consistency-check` session. Not written to any file.

---

## Staleness Resolution
**Type**: codebase
**Captured**: 2026-03-16
**Source**: [domain-20260316-9c2e]

The outcome of a steward reviewing a Staleness Candidate. Written to `distilled/changelog.md` at session end. Never a standalone file.

**Fields**:

| Field | Type | Values |
|-------|------|--------|
| `entry_title` | string | Title of the reviewed entry |
| `describes_file` | string | The source file path that triggered the staleness flag |
| `outcome` | enum | `reviewed` \| `re-captured` \| `archived` |
| `rationale` | string | Steward's stated reason; `"no rationale provided"` if empty |
| `resolved_by` | string | Git user name or session identity |
| `resolved_date` | YYYY-MM-DD | Date of resolution |

**Outcome semantics**:
- `reviewed` — steward dismissed the change as non-material; distilled entry unchanged
- `re-captured` — steward updated the entry content to reflect the source change; distilled entry modified
- `archived` — entry is no longer relevant; removed from distilled file (governed action requiring confirmation)

**Persistence**: Written to `distilled/changelog.md` at session end.

---

## ConsistencyCheckSession
**Type**: codebase
**Captured**: 2026-03-16
**Source**: [domain-20260316-9c3f]

In-memory record maintained during a single `/consistency-check` invocation. Tracks progress and outcome counts for the session summary. Never written to disk; the changelog entry is the durable record.

**Fields**:

| Field | Description |
|-------|-------------|
| `candidates_found` | Count of Staleness Candidates identified |
| `candidates_reviewed` | Count resolved by the steward during this session |
| `candidates_dismissed` | Count resolved as `reviewed` (non-material) |
| `candidates_recaptured` | Count resolved as `re-captured` |
| `candidates_archived` | Count resolved as `archived` |
| `source_deleted` | Count of entries where `describes_file` was not found in the working tree |

**Persistence**: In-memory only. Not written to any file.

---
