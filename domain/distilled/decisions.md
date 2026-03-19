# Decisions

<!-- Architecture Decision Records (ADRs), open and resolved. Populated by /refine from captured 'decision' items and from governed decisions flagged as unresolved. -->

<!-- ADR format:
## [OPEN] ADR-NNN: <title>
**Status**: open
**Captured**: YYYY-MM-DD
**Context**: <why this decision arose>
**Options**:
- A: <option>
- B: <option>
**Flagged by**: refine agent
**Pending**: <what needs to happen>

---

## [RESOLVED] ADR-NNN: <title>
**Status**: resolved
**Decision**: <what was decided>
**Rationale**: <why>
**Decided by**: <person> | **Date**: YYYY-MM-DD
-->

## [RESOLVED] ADR-001: Delivery Mechanism

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: Domain Brain needs a delivery mechanism that integrates naturally with AI assistant workflows without adding runtime dependencies or build steps.

**Options considered**:
- Claude AI assistant extension (command files only)
- Node.js CLI
- Python scripts

**Decision**: Domain Brain is delivered as a Claude AI assistant extension — command files only (`.claude/commands/*.md`). No build step, no server, no dependencies. Commands invoke built-in tools (Read, Write, Edit, Glob, Grep, Bash).

**Rationale**: Node.js CLI and Python scripts were rejected because both violate the Extension-First principle and add runtime dependencies. Command files require nothing beyond the AI assistant that is already in use.

**Type**: decision
**Source items**: [domain-20260306-a1b2]

---

## [RESOLVED] ADR-002: Hot-Reload for types.yaml

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: The type registry (`config/types.yaml`) must reflect changes made by the steward without requiring a process restart, since Domain Brain has no persistent daemon.

**Options considered**:
- Read `config/types.yaml` at every command invocation using the Read tool
- File watcher daemon

**Decision**: Read `config/types.yaml` at every command invocation using the Read tool. "Hot-reload" means the command reads the file on every call — no daemon needed. Changes take effect at next `/capture` or `/refine` invocation without restart.

**Rationale**: A file watcher daemon was rejected because it violates the Extension-First principle and is impossible to implement from a command file. The Read-on-every-invocation approach achieves the same effect with zero infrastructure.

**Type**: decision
**Source items**: [domain-20260306-c3d4]

---

## [RESOLVED] ADR-003: Retrieval Strategy by Domain Size

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: `/query` must retrieve relevant distilled content efficiently across domains of varying sizes without violating the Extension-First or Knowledge as Code principles.

**Options considered**:
- Tiered retrieval based on domain size
- SQLite full-text search
- External vector store

**Decision**: Tiered retrieval strategy: Small (≤50 entries) → Read all candidate files; Medium (51–500) → Grep + Read top-N; Large (>500) → hosted index deferred to v2. Claude context window holds all distilled files for small domains. Grep-based retrieval is O(file size) and sufficient for ≤500 entries.

**Rationale**: SQLite FTS was rejected for violating the Knowledge as Code principle. External vector stores were rejected for violating Extension-First and being over-engineered for v1 scale. The tiered approach matches infrastructure complexity to domain size.

**Type**: decision
**Source items**: [domain-20260306-e5f6]

---

## [RESOLVED] ADR-004: Refine Subagent Pattern

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: `/refine` must separate orchestration concerns (host: human interaction, file writing) from knowledge processing concerns (subagent: classification, content generation) while preserving human governance over ambiguous decisions.

**Options considered**:
- Host command orchestrates a refine subagent via the Agent tool
- Single monolithic /refine with no subagent

**Decision**: `/refine` host command orchestrates a refine subagent via the Agent tool. Flow: host loads raw queue → invokes subagent with batch + context → subagent returns structured plan (autonomous actions silently, governed decisions to host) → host presents decisions one at a time → human responds → host records in changelog. Subagent NEVER writes files directly.

**Rationale**: A single monolithic `/refine` was rejected because it conflates orchestration with knowledge processing. The subagent pattern cleanly separates concerns and ensures the human remains in the loop for governed decisions without the subagent gaining write authority.

**Type**: decision
**Source items**: [domain-20260306-a7b8]

---

## [RESOLVED] ADR-005: Large Document Chunking

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: Documents above ~10 pages / ~5000 tokens cannot be held in context as a single unit during retrieval, requiring a chunking strategy that preserves targeted access without external infrastructure.

**Options considered**:
- Chunk storage under `index/<doc-id>/chunks/`
- Single large-document file
- External vector index

**Decision**: Documents above ~10 pages / ~5000 tokens: Read with page ranges, split at logical boundaries, store each chunk as `index/<doc-id>/chunks/chunk-NNNN.md`, store ≤500-word summary at `index/<doc-id>/summary.md`, update distilled entry with `chunk-ids`. Second-stage retrieval: Grep chunks, load matched.

**Rationale**: A single large-document file defeats targeted retrieval. External vector indexes violate both Extension-First and Knowledge as Code principles. The two-level structure (summary for default retrieval, chunks for deep retrieval) gives efficient access at both levels.

**Type**: decision
**Source items**: [domain-20260306-c9d0]

---

## [RESOLVED] ADR-006: Domain Brain Instance Layout

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: A Domain Brain instance needs a discoverable directory structure that supports multiple independent domains within a single repository.

**Options considered**:
- Standard directory layout with command discovery order
- Flat structure in repo root

**Decision**: A domain brain instance is a directory with `config/`, `raw/`, `distilled/`, `index/` subdirectories. Teams initialize by copying the `domain/` template. Command discovery order: (1) explicit `--domain <path>`, (2) `.domain-brain-root` file at git root, (3) conventional `domain/` at git root.

**Rationale**: Per-directory isolation enables multiple independent domains within one repository. The three-level discovery order supports explicit override, project-level configuration, and sensible default — in that priority.

**Type**: decision
**Source items**: [domain-20260306-e1f2]

---

## [RESOLVED] ADR-007: Raw Item Filename Convention

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: Raw items need a filename convention that enables discovery without parsing frontmatter, provides approximate chronological ordering, and remains identifiable if files are moved.

**Options considered**:
- `raw/<domain>-<YYYYMMDD>-<4hex>.md` (id-matched filename)
- Generic sequential numbering
- UUID-only filenames

**Decision**: Each raw item stored as `raw/<id>.md` where `<id>` = `<domain>-<YYYYMMDD>-<4hex>`. Filename matches the `id` frontmatter field — findable without parsing frontmatter. Sorting by filename gives approximate chronological order. Domain prefix keeps items identifiable if files are ever moved.

**Rationale**: The id-matched filename approach satisfies all three requirements: discoverability, chronological sorting, and domain-tagged identity. UUID-only filenames would lose chronological information; sequential numbering would require a counter file.

**Type**: decision
**Source items**: [domain-20260306-a3b4]

---

## [RESOLVED] ADR-008: Command File Patterns

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: Domain Brain command files need a consistent schema to support command-palette discoverability and chained workflows.

**Options considered**:
- Speckit command file schema with `description` and `handoffs` frontmatter
- Custom ad-hoc frontmatter per command

**Decision**: All Claude command files follow the speckit command file schema with `description` and `handoffs` frontmatter. The `handoffs` array enables chained workflows (e.g., after `/capture`, offer `/refine`). Domain Brain commands chain `/capture` → `/refine` → `/query`.

**Rationale**: The speckit pattern is proven and enables command-palette discoverability. The `handoffs` mechanism provides natural workflow guidance without hard-wiring sequences, allowing users to deviate when appropriate.

**Type**: decision
**Source items**: [domain-20260306-c5d6]

---

## [RESOLVED] ADR-009: /frame Collection UX — Template-Fill Pattern

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: `/frame` must collect domain identity information from the steward with minimal friction while pre-filling known fields.

**Options considered**:
- Template-fill pattern (pre-fill auto-derivable fields, present labelled placeholders)
- Multi-turn field-by-field collection
- Fully non-interactive flags

**Decision**: `/frame` pre-fills all auto-derivable fields (domain name from directory, steward from `git config user.name`, creation date) and presents a Markdown template with remaining fields as labelled placeholders — single exchange. On re-run, current values replace placeholders.

**Rationale**: Multi-turn field-by-field collection produces high friction. Fully non-interactive flags are awkward for multi-item lists (In scope, Out of scope). The template-fill pattern achieves a single-exchange interaction with maximum pre-fill, matching the way developers interact with scaffolding tools.

**Type**: decision
**Source items**: [domain-20260306-f7e8]

---

## [RESOLVED] ADR-010: config/identity.md File Schema

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: The domain identity document needs a schema that is both machine-readable (for commands that parse specific fields) and human-readable/editable (for stewards).

**Options considered**:
- YAML frontmatter + Markdown body
- Pure YAML
- Embedded in types.yaml

**Decision**: Identity document uses YAML frontmatter (domain, created, steward — machine-readable) and Markdown body (One-line, Pitch, In scope, Out of scope — human-readable). Uses `**Bold label**: content` pattern consistent with distilled file entries.

**Rationale**: Pure YAML is harder to read for non-technical stewards. Embedding in types.yaml mixes domain identity with type registry configuration, creating coupling between unrelated concerns. The split schema gives each audience the format they need.

**Type**: decision
**Source items**: [domain-20260306-b9c0]

---

## [RESOLVED] ADR-011: /seed Resume Logic — Implicit Offset via Existing Raw Items

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: `/seed` processes large documents in segments and must support resuming a prior session after interruption without external state files.

**Options considered**:
- Implicit offset derived from counting existing raw items with matching source.location
- Explicit `--start N` flag
- Progress tracking file

**Decision**: On re-run, count existing raw items with matching `source.location`. Use that count as segment skip offset. Segmentation is deterministic (document order). No persistent state file needed — raw items ARE the progress log.

**Rationale**: An explicit `--start N` flag requires the user to manually track position, creating error-prone bookkeeping. A progress tracking file introduces opaque state that violates the Knowledge as Code principle. Using the raw items themselves as the progress log is self-consistent and requires no additional mechanism.

**Type**: decision
**Source items**: [domain-20260306-d1e2]

---

## [RESOLVED] ADR-012: Cap Applies to Raw Items Created, Not Segments Examined

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: `/seed` enforces a 100-item session cap to prevent runaway processing, but the definition of "cap" affects how useful each session is for domains with mixed-relevance source documents.

**Options considered**:
- Cap counts items written (in-scope + flagged-as-uncertain)
- Cap counts segments examined

**Decision**: The 100-item cap counts items written (in-scope + flagged-as-uncertain). Out-of-scope skips do NOT count toward the cap.

**Rationale**: Capping on segments examined would penalise users with well-defined out-of-scope lists — a domain with 40% out-of-scope content would produce only 60 useful items per session instead of 100. Capping on items written ensures the cap is a guarantee of minimum useful output.

**Type**: decision
**Source items**: [domain-20260306-f3a4]

---

## [RESOLVED] ADR-013: /refine Identity Context Injection

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: The refine subagent needs domain identity context (especially the Out of scope list) to correctly classify items as `out_of_scope`, but the injection point must keep orchestration concerns with the host and knowledge processing concerns with the subagent.

**Options considered**:
- Explicit read of `config/identity.md` in `/refine` Step 6; pass to subagent
- Separate structured parameter passed to subagent
- Host performs out-of-scope classification before invoking subagent

**Decision**: In `/refine` Step 6, add explicit read of `config/identity.md` if it exists. Identity document passed to refine subagent alongside raw items and distilled files. Subagent uses the "Out of scope" list for `out_of_scope` classification.

**Rationale**: A separate structured parameter is over-engineered — the identity document is already a well-structured Markdown file. Having the host perform classification before the subagent splits the classification concern confusingly across two agents.

**Type**: decision
**Source items**: [domain-20260306-b5c6]

---

## [RESOLVED] ADR-014: /query Identity Framing — Step 2.5

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: `/query` answers should be framed with domain context (e.g., a one-line description in the answer header) but the identity read must never block a query if the file is absent.

**Options considered**:
- Soft-read `config/identity.md` as Step 2.5 after argument parsing
- Read identity inside Step 5 context retrieval

**Decision**: After argument parsing, add Step 2.5: soft-read `config/identity.md`. If found, store the one-line description for use in the answer header. If absent, proceed normally — never block a query.

**Rationale**: Adding the identity read inside Step 5 context retrieval would complicate the candidate file selection logic. A dedicated Step 2.5 keeps the concern isolated and makes the soft-read / non-blocking behaviour explicit in the command flow.

**Type**: decision
**Source items**: [domain-20260306-d7e8]

---

## Design Clarifications — Feature 001 Specification Session (2026-03-05)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-06
**Source**: [domain-20260306-d6e7]

Design questions resolved during the Feature 001 specification session:

| Question | Resolution |
|---|---|
| What file format should distilled knowledge files and raw item queue use? | Markdown with YAML frontmatter. |
| Is `compliance` in FR-021 a distinct 6th reasoning mode or a synonym for `design-proposal`? | `compliance` is a sub-mode/synonym; FR-021 updated to reference `design-proposal` only. |
| What entry-count thresholds define small/medium/large domains for retrieval strategy switching? | Small = ≤50 entries; medium = 51–500; large = >500. |
| What happens when a distilled file grows too large? | System automatically splits into sub-files as a governed action requiring user confirmation. |
| Chunk cap reached with no clear ranking? | Break ties by entry recency, apply cap, notify user to narrow query. |
| Duplicate FR-007 number — which to renumber? | Keep Capture FR-007; renumber Refine FR-007→FR-008 and cascade. |
| What is the structure of the source field? | Structured with `tool` and optional `location`, both auto-populated. |
| What format should the Raw Item id field use? | `<domain>-<YYYYMMDD>-<4-char hex>`, auto-generated. |

---

## Design Clarifications — Feature 002 Specification Session (2026-03-06)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-06
**Source**: [domain-20260306-ebec]

Design questions resolved during the Feature 002 specification session:

| Question | Resolution |
|---|---|
| What is the minimum segment size for a segment to become a raw item? | Complete-thought minimum — Claude assesses whether segment contains at least one complete, standalone knowledge claim. No fixed word count. Heading-only or single-phrase segments are merged with next or skipped. |
| What is the basis for classifying a segment as in-scope, out-of-scope, or ambiguous? | Semantic judgment — Claude evaluates segment's topic against identity's pitch and scope lists holistically, not by keyword matching. |
| Where does a seeded raw item's title come from? | Hybrid — use nearest section heading when exists; infer ≤10-word title from content when no heading. |
| What should /seed do when session would produce more raw items than the practical limit? | Warn and cap at 100 raw items per run (default). Stop after cap, report unprocessed remaining, invite re-run. |
| When /frame updates identity, what happens to seeded raw items already in queue? | Warn only — /frame checks for existing seeded raw items and warns user their scope classifications may be stale. Recommends /refine. No automatic re-flagging. |

---

## Feature 002 — Explicit Scope Boundary Decisions
**Type**: decision (feature scope record, not an ADR)
**Captured**: 2026-03-06
**Source**: [domain-20260306-fdfe]

The following capabilities are explicitly out of scope for Feature 002 (/frame and /seed). These are deliberate deferral decisions, not omissions:

- **Authenticated enterprise API integration**: Confluence REST, Notion API, Jira, SharePoint — deferred to a future release.
- **Automated or scheduled seeding**: No seeding without manual invocation in v1.
- **Cross-domain seeding**: Importing content tagged for a different domain brain instance is not supported.
- **Versioning or diffing of config/identity.md**: Beyond what git provides natively — not addressed in v1.
- **Multiple identity documents or sub-domain framing**: A single `config/identity.md` per domain brain instance is the v1 model.

---

## [RESOLVED] ADR-015: Type-aware context loading in /refine Step 6

**Status**: Resolved
**Captured**: 2026-03-06
**Context**: `/refine` Step 6 unconditionally loads all distilled files before invoking the refine subagent. Since each raw item's type is resolved at capture time (written into YAML frontmatter), and the type registry maps each type to a specific distilled file via `routes_to`, loading files irrelevant to the batch's item types wastes tokens. ADR-003 established tiered retrieval for `/query`; no equivalent scoping existed for `/refine`. ADR-013 added a targeted read of `config/identity.md`. ADR-004 specifies the host owns all context loading.

**Options considered**:
- Selective load: union routes_to targets of batch item types + decisions.md + identity.md always; type `other` triggers full load
- Full load always: keep current behaviour (simpler, no risk of missing cross-file context)
- Selective load with keyword heuristic: same as selective, but opportunistically adds files referenced in item bodies

**Decision**: Selective load (option A). For each /refine session, the host reads `config/types.yaml`, resolves the `routes_to` target for each item's type, unions the resulting file set, and always adds `decisions.md` (for ADR conflict detection) and `config/identity.md` (per ADR-013). Items of type `other` (routes_to: null) trigger full load of all distilled files.

**Rationale**: Consistent with the candidate-file selection pattern established in ADR-003 for `/query`. The keyword heuristic (option C) was rejected as unnecessary complexity — the union of routing targets already covers the relevant files for any well-typed batch. Full load always (option B) was rejected as inconsistent with the token efficiency requirement captured alongside this ADR.

**Type**: decision
**Source items**: [domain-20260306-b3c4]

---

## Design Assumptions — Feature 003 Specification Session (2026-03-12)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-12
**Source**: [domain-20260312-7d2e]

Design assumptions established during the Feature 003 (refine pipeline performance) specification session:

| Assumption | Detail |
|---|---|
| Distilled files in memory during `/refine` | The host already has access to all distilled files in memory during a `/refine` session (per ADR-015); exact-duplicate detection requires no additional I/O. |
| Definition of "exact duplicate" | Byte-for-byte identical content between the raw item and a distilled entry; semantic similarity detection is out of scope for this feature. |
| Out-of-scope keyword matching | The Out-of-scope list in `config/identity.md` contains explicit keywords or patterns sufficient for deterministic matching; fuzzy scope detection is out of scope. |
| Specialist subagent coverage | Five specialist subagents (`requirements`, `interfaces`, `decisions`, `codebase`, `responsibility`) cover the majority of high-volume item types; Feature 006 extended the original three-specialist roster (Feature 003 FR-007) by adding `codebase` and `responsibility` clusters. Further specialists can be added in future iterations. |
| Type inference mechanism | Type inference at `/capture` and `/seed` time uses heuristic content analysis; machine-learning-based classification is out of scope. |
| No retroactive reclassification | Existing `other`-typed items already in the raw queue are not retroactively reclassified; the improvement applies only to newly captured or seeded items. |

---

## Design Assumptions — Feature 005 Specification Session (2026-03-13)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-13
**Source**: [domain-20260313-a009]

Design assumptions established during the Feature 005 (semantic duplicate detection in /refine) specification session:

| Assumption | Detail |
|---|---|
| Knowledge base size fits in context | The domain's distilled knowledge base is small enough to compare against in a single `/refine` session context without hitting context-length limits (consistent with the ≤500-entry scope boundary from Feature 001; hosted-index tier for larger domains is a separate backlog item). |
| Similarity comparison mechanism | Semantic similarity comparison is performed by the AI host reasoning in-context (FR-006 resolved: no external embedding APIs). |
| Definition of "semantic similarity" | Meaning-level overlap sufficient that the incoming item would add no new distilled knowledge — not surface-level word overlap. |
| Pre-filter accounting | The existing pre-filter accounting structure from Feature 003 (archiving filtered items with a reason) is extended, not replaced. |

---

## Design Clarifications — Feature 004 Specification Session (2026-03-12)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-12
**Source**: [domain-20260312-b7c8, domain-20260312-c9d1, domain-20260312-d2e3]

Design assumptions and constraints established during the Feature 004 (backlog lifecycle) specification session:

| Assumption / Constraint | Detail |
|---|---|
| Delivery mechanism | Claude command file (`.claude/commands/triage.md`) — no standalone application, no external services. |
| Command surface | `/triage` (new); `/query` extended with `task-management` mode; `/refine` extended with priority assignment and updated entry format. |
| Storage format | Markdown with YAML frontmatter in version-controlled repository; all files human-readable (`distilled/backlog.md`, `config/priorities.md`). |
| Host AI and orchestration | Claude (claude-sonnet-4-6+); the priority subagent is an Agent tool invocation orchestrated by `/triage`. No new dependencies beyond built-in tools. |
| Backlog Entry schema | Task-typed item with `Status` (`open`\|`in-progress`\|`done`) and `Priority` (`high`\|`medium`\|`low`) fields in `distilled/backlog.md`. The `## Done` section is a structural divider within the same file, not a separate file. |
| Priority Guidelines document | Persistent steward-maintained file (`config/priorities.md`) encoding strategic focus as human-readable rules. Read by priority subagent and `/refine` when processing new task items. Optional — if absent, defaults apply. |
| Triage Session scope | A single conversational `/triage` invocation. May span multiple user turns. Each session that closes or drops items appends to the changelog. |
| `distilled/backlog.md` pre-existence | Assumed to already exist (created by the existing `/refine` pipeline) when `/triage` is invoked. |
| Speckit handoff | `/triage` treats the speckit.specify workflow as an available handoff target when starting work on a backlog item. |
| Priority inference at `/refine` time | Uses the same AI-judgment approach as scope classification — heuristic, not keyword matching — guided by `config/priorities.md`. |
| Drop vs Close governance | "Drop" (cancel without completion) is a governed decision because it is potentially irreversible and audit-worthy. "Close" (completed) requires only a rationale. |

---

## [RESOLVED] ADR-016: Governance of Priority Guideline Changes

**Status**: Resolved
**Captured**: 2026-03-13
**Context**: `config/priorities.md` encodes strategic task prioritisation rules used by the priority subagent and `/refine`. When these rules change, the change has downstream effects on backlog ordering and autonomous decisions made during `/refine`. The question arose whether priority guideline changes should be governed by the ADR process, a lighter changelog, or git history alone.

**Options considered**:
- A: Log every change to `config/priorities.md` as a new ADR in `distilled/decisions.md`, using the full ADR format with Context, Options, Decision, and Rationale.
- B: Maintain a lightweight `config/priorities-history.md` changelog (date, summary, rationale) — separate from the ADR log.
- C: Rely on git history alone for priority guideline provenance.

**Decision**: Log every change to `config/priorities.md` as a new ADR in `distilled/decisions.md` using the full ADR format.

**Rationale**: The priorities file controls the general direction that the domain takes. It guides the AI's automated decisions and severely impacts priorities. Given this strategic weight, changes warrant the full governance treatment afforded to architectural decisions.

**Decided by**: Søren Lindstrøm | **Date**: 2026-03-13
**Source items**: [domain-20260313-c2d4]

---

## [RESOLVED] ADR-017: Extend Specialist Subagent Roster to Include Codebase and Responsibility Clusters
**Status**: Resolved
**Captured**: 2026-03-13
**Context**: Feature 003 (FR-007) mandated three specialist subagents (requirements, interfaces, decisions). All other item types — including `codebase` and `responsibility` — fell to a generalist subagent that loads the full distilled context window. As item volumes grew, this created unnecessary overhead: codebase and responsibility items are high-volume and self-contained enough to be handled by focused specialists with scoped context.
**Options considered**:
- Keep generalist handling for all non-mandated types (status quo — increasing overhead as volume grows)
- Add dedicated specialists for codebase and responsibility clusters only, retaining generalist for remaining low-volume types (stakeholder, task, mom, other)
- Add dedicated specialists for all remaining types immediately
**Decision**: Add `codebase` and `responsibility` specialist subagents in Feature 006. The generalist subagent is retained as fallback for `stakeholder`, `task`, `mom`, `other`, and unrecognised types.
**Rationale**: Codebase and responsibility items are sufficiently high-volume and have well-defined context file sets (respective distilled file plus identity.md) to justify dedicated specialists. Stakeholder, task, and mom types do not yet meet that threshold. The Feature 003 specialist instruction template is reused unchanged, keeping the extension low-cost.
**Decided by**: Søren Lindstrøm | **Date**: 2026-03-13
**Source items**: [domain-20260313-1a2b]

---

## Design Assumptions — Feature 006 Specification Session
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-13
**Source**: [domain-20260313-f9c0]

Assumptions captured during the Feature 006 specification session for specialist subagent extension:

- The `codebases.md` and `responsibilities.md` distilled files exist (or are empty) in the domain brain; the specialist does not depend on their presence but benefits from it.
- The context files needed for `codebase` and `responsibility` specialists are primarily the respective distilled file plus `identity.md`. Cross-file lookups (e.g., a codebase entry referencing an interface) are handled by governing decisions rather than expanding context.
- The Feature 003 specialist instruction template (SUBAGENT INSTRUCTIONS — REFINE AGENT) is reused unchanged for the new specialists; no new instruction variant is required.
- `stakeholder`, `task`, and `mom` types remain in the generalist cluster for now; their relative volume and decision complexity do not yet justify dedicated specialists.
- This feature does not retroactively reclassify or reprocess any items already in the raw queue or distilled files.

---

## [RESOLVED] ADR-018: Mechanism for keeping distilled entries consistent with implementation changes
**Status**: Resolved
**Captured**: 2026-03-16
**Context**: FR-024 establishes that distilled entries describing implementation MUST be kept current when the corresponding implementation changes. The specific mechanism for detecting staleness and triggering updates is not yet decided. Candidate approaches surfaced during the refine session that introduced FR-024: (A) a consistency-check phase inside `/refine`; (B) a separate `/consistency-check` command; (C) hook or git-diff-based detection.
**Options considered**:
- A: Add a consistency-check phase to `/refine` — at session start, compare distilled entries against their source command files and re-queue stale entries
- B: Introduce a dedicated `/consistency-check` command — keeps `/refine` lean but requires explicit invocation
- C: Hook/git-diff-based auto-injection of raw items when source files change (may conflict with no-external-service NFR)

**Decision**: Deliver FR-024 as a new standalone `.claude/commands/consistency-check.md` command (Option B). The command scans all distilled entries with a `**Describes**: <path>` opt-in line, compares each entry's `**Captured**` date against the source file's last git commit date, surfaces stale candidates ranked oldest-first, and guides the steward through dismiss / re-capture / archive resolutions with a changelog entry at session end.

**Rationale**: Option A was rejected because `/refine` is already at a complexity ceiling (579 lines, 13 steps, 5 specialist subagents); adding a consistency-check phase would increase cognitive load and expand the testing surface. Option C was rejected as it requires an external daemon or git hook — both violate the Extension-First principle (Principle I) and the no-external-services constraint. Option B cleanly separates concerns, is pattern-consistent with the simplicity of `/frame` and `/query`, and is estimated at 100–150 lines.

**Decided by**: Søren Lindstrøm | **Date**: 2026-03-16
**Source items**: [domain-20260316-c4f1]

---

## Design Assumptions — Feature 009 Specification Session (2026-03-16)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-16
**Source**: [domain-20260316-0a1b]

| Assumption | Detail |
|---|---|
| Primary splitting axis | Entry count, not byte size — a more stable and intent-aligned metric for distilled Markdown files. |
| Default threshold | Approximately 50 entries per file; exact value calibrated during implementation against context-window constraints. |
| Default grouping axis | Recency — recent/active entries form one sub-file; older/archived entries form another. Steward may override in natural language. |
| Sub-file naming convention | `{base}-{group-label}-{n}.md` (e.g., `requirements-archived-1.md`); group label derived from dominant entry type or steward-provided name; sequential number disambiguates multiple sub-files sharing a label. |
| Split detection timing | Runs at the start of `/refine` as a pre-processing phase, not on every file write — real-time monitoring is out of scope. |

---

## Design Clarifications — Feature 009 Specification Session (2026-03-16)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-16
**Source**: [domain-20260316-2a3b]

| Question | Resolution |
|---|---|
| Where should split-detection and proposal logic live? | Integrated into `/refine` as a pre-processing phase (Option A) — not a standalone command. |
| How should sub-files be named when a split is executed? | `{base}-{group-label}-{n}.md`; group label from entry type or steward-provided name; sequential number for disambiguation (e.g., `requirements-archived-1.md`). |
| What is the default grouping axis when proposing a split? | Recency — recent/active entries in one sub-file, older/archived in another (Option B). |

---

## Design Clarifications — Feature 009 SplitCandidate State Transitions (2026-03-16)
**Type**: decision (clarification record, not an ADR)
**Captured**: 2026-03-16
**Source**: [domain-20260316-1a2b]

SplitCandidate state machine for Feature 009:

```
SplitCandidate
  pending → (presented as governed decision)
    → confirmed          — split executed; sub-files created; original retired; changelog updated
    → skipped            — no files modified; file flagged again next session
    → flagged_unresolved — open ADR created in decisions.md; no files modified
    → warning            — entry_count == 1; no split proposal presented; steward notified
```

---

## Design Assumptions — Feature 001 Specification Session (Explicit Subagents)
**Type**: decision
**Captured**: 2026-03-18
**Source**: domain-20260318-9e0f

- The Claude Agent tool supports passing instruction content loaded from a file at invocation time; no platform constraint prevents this.
- The single `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block is the complete set of inline subagent instructions to extract; no other embedded subagent blocks exist in the current `refine.md`.
- Specialist cluster routing (requirements, interfaces, decisions, codebase, responsibility) all use the same shared instruction block — a single subagent file is sufficient for this feature. Splitting by specialist type is out of scope.
- No other command files currently embed subagent instructions that need to be extracted as part of this feature.

---

## Design Clarifications — Feature 001 Specification Session (Explicit Subagents)
**Type**: decision
**Captured**: 2026-03-18
**Source**: domain-20260318-a1b2

**Clarifications (2026-03-17)**:
- Q: Where should subagent files be stored? → A: `.claude/agents/` to maintain conventions
- Q: What format should the subagent file header take? → A: Plain Markdown prose header (no YAML frontmatter)

**Scope Boundary Decisions**:
- **In scope**: Extracting the refine subagent instructions to a separate file; updating `refine.md` to load and reference it.
- **Out of scope**: Creating separate instruction files per specialist type (future feature); extracting instruction blocks from commands other than `/refine`; changing the content of the subagent instructions beyond what is necessary for the extraction.

---

## [RESOLVED] ADR-019: Consolidate Command Merged into Consistency-Check
**Status**: Resolved
**Captured**: 2026-03-18
**Context**: Feature 010 originally planned a standalone `/consolidate` command to generate `domain/README.md` as an onboarding artefact. During implementation it became clear that README generation was closely coupled to the consistency-checking workflow, which already inspects every distilled file and the command registry. Keeping a separate command would have duplicated that traversal and introduced a second entry point that users must remember to run.

**Options considered**:
- Keep `/consolidate` as a standalone command with its own `.claude/commands/consolidate.md` file
- Merge README generation into `/consistency-check` as an additional step executed during each consistency run

**Decision**: Merge the consolidate logic into `/consistency-check` as Step 6 (README refresh). No standalone `consolidate.md` command file is created.

**Rationale**: The consistency-check command already traverses all distilled files and the command registry; appending a README-generation step reuses that traversal at zero extra cost. A single command is simpler for users and eliminates the risk of `domain/README.md` going stale between separate command invocations. The `interfaces.md` entry for `/consolidate` was replaced with a merge notice pointing to `/consistency-check`, and the corresponding backlog item was closed as done.

**Decided by**: Søren Lindstrøm | **Date**: 2026-03-18
**Source items**: [domain-20260318-a4c7]

---
