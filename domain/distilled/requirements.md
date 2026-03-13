# Requirements

<!-- Constraints, non-negotiables, and quality attributes. Populated by /refine from captured 'requirement' items. -->

## Feature 001 — User Stories (US1–US5)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-b0c1, domain-20260306-d2e3, domain-20260306-f4a5, domain-20260306-b6c7, domain-20260306-d8e9]

### US1 — Capture a Knowledge Item
A domain expert encounters knowledge they want to preserve. They capture it immediately with minimal friction from wherever they are working (IDE or chat interface), providing only a description and perhaps a title and type. The system generates required structure automatically and queues it for refinement.

**Acceptance scenarios**:
1. Given a domain expert in their IDE, when they invoke capture with title and type, then a valid raw item is created with auto-populated id, source, domain, timestamp, author, and status `raw`.
2. Given a domain expert in chat, when they invoke /capture and paste unstructured text, then the system extracts title, infers type, formats envelope, and asks for confirmation only if type is genuinely ambiguous.
3. Given a submitted raw item, when a required envelope field is missing, then the system flags it as malformed and does not add it to queue until corrected.

### US2 — Refine Raw Items Into Distilled Knowledge
A domain expert initiates a refine session to process the accumulated raw queue. The system works autonomously — deduplicating, summarising, aggregating, routing items with high confidence. When it encounters conflict, new normative fact, or something it cannot classify reliably, it pauses and presents a single governed decision. The human responds in natural language.

**Acceptance scenarios**:
1. Duplicate entry → merged silently, raw item archived without human input.
2. Two items assigning same responsibility to different teams → single governed decision with "flag as unresolved" option.
3. Human responds "go with B but add a note that this needs an architecture call" → distilled entry reflects option B AND the note.
4. Human says "skip for today" → session pauses cleanly, remaining items stay in queue.
5. Completed session → changelog entry appended with all autonomous actions and governed decisions with rationale.
6. Similar items (not exact duplicates) → merged silently if confidence is high.
7. Item with multiple types → split into multiple items with appropriate types if confidence is high.

### US3 — Query Domain Knowledge
A domain expert needs to answer a design, decision, or planning question. They ask in natural language. The system classifies the query, retrieves only relevant portions of the distilled knowledge base, and returns a cited, grounded answer. If it cannot answer well due to missing knowledge, it names the specific gap and offers to capture it.

**Acceptance scenarios**:
1. "Who owns the onboarding flow?" → retrieves from stakeholders and domain knowledge only, returns cited answer naming owning team.
2. Domain with open ADRs, ask "What is blocking progress?" → open decisions appear in answer alongside requirements gaps.
3. Query requiring uncaptured interface definition → names specific missing knowledge and asks to capture it or proceed with flagged gaps.
4. Query exceeds chunk cap → notifies user that a more specific query may yield better results rather than silently truncating.

### US4 — Process Large Linked Documents
A domain expert captures a large document (compliance spec, architecture PDF, content export) too large to treat as a single raw item. The system automatically processes it into queryable chunks, stores a summary and chunk references in the appropriate distilled file, and makes its contents discoverable through targeted retrieval.

**Acceptance scenarios**:
1. Document above threshold → chunked at logical boundaries, distilled entry created with summary and chunk references.
2. Precision query (design-proposal/compliance mode), summary insufficient → second-stage retrieval against source document index.
3. Overview query (diagram/gap-analysis mode), summary present → uses summary only, no second-stage retrieval triggered.

### US5 — Track and Discover Open Decisions
A domain expert wants to know what architecture questions are currently unresolved. They query for open decisions and receive a list of open ADRs with context, options considered, and reason each was left unresolved. They can also encounter open decisions as cited context in other queries.

**Acceptance scenarios**:
1. Conflict flagged as unresolved during refinement → stored with status (open), conflicting captures, options, reason pending.
2. Open ADR in decisions file → when expert queries intersecting topic, open ADR appears in cited context with status clearly marked.

---

## Feature 001 — Edge Cases
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-f0a1]

- **Unclassifiable `other` type**: If refine agent cannot confidently classify even after analysis, user is asked to confirm candidate type.
- **Conflicting captures in same session**: If two captures conflict and conflict cannot be resolved automatically, user is asked to resolve.
- **Inaccessible large document at processing time**: If raw item references inaccessible document, user is asked for a new source.
- **Governed decision response maps to no option**: Infer user's intent from natural language response.
- **Distilled file grows too large for retrieval**: System automatically splits into sub-files as a governed action requiring user confirmation before committing restructuring.
- **Chunk cap reached with no clear ranking**: Ties broken by entry recency (most recently updated first). Cap applied, user notified to issue more specific query.
- **Same large document captured from multiple sources**: Identified as duplicate during refinement.

---

## Feature 001 — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-b8c9, domain-20260306-e5f6]

- **Delivery mechanism**: Domain Brain MUST be delivered as an extension to an existing AI assistant — not a standalone application. All user-facing capabilities are commands, skills, and subagents. For v1, Claude is the host AI.
- **Command surface**: `/capture` (intake), `/refine` (run refine session), `/query` (reason against distilled base). Each is a Claude command or skill; refine agent is a subagent orchestrated by the host.
- **Storage format**: All knowledge files use Markdown with YAML frontmatter. Files live in a version-controlled repository and MUST be human-readable without tooling.
- **Host AI**: Claude (v1). Multi-assistant support is a future iteration. *Vision: the system should eventually support AI hosts beyond Claude — a stated product direction, not a current requirement.*

---

## Feature 001 — Functional Requirements: Capture (FR-001–FR-007)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-b2c3]

- **FR-001**: System MUST allow users to submit raw item with only title and type; all other envelope fields auto-populated.
- **FR-002**: System MUST allow users to submit raw item with only description; all other envelope fields auto-populated.
- **FR-003**: System MUST support configurable type set loaded at runtime from `config/types.yaml`. Default types: `responsibility`, `interface`, `codebase`, `requirement`, `stakeholder`, `decision`, `task`, `mom`, `other`. Each type definition MUST include name, description, routing target, and at least one example.
- **FR-003a**: System MUST reload type registry without requiring restart; changes take effect immediately.
- **FR-003b**: When presenting type options, system MUST display each type's configured description alongside its name.
- **FR-004**: System MUST validate each captured item's envelope at intake and reject items with missing required fields.
- **FR-005**: System MUST never require user to hand-author structured envelope format.
- **FR-006**: When capture type is genuinely ambiguous, system MUST ask for confirmation; when type can be inferred with high confidence, system MUST NOT prompt.
- **FR-007**: System MUST process documents above large document threshold by chunking at logical boundaries and storing chunk references with summary in relevant distilled file.

---

## Feature 001 — Functional Requirements: Refine (FR-008–FR-015)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-d4e5]

- **FR-008**: System MUST autonomously perform deduplication, summarisation, normalisation, aggregation, routing of type `other`, and archiving of processed raw items when confidence is high.
- **FR-009**: System MUST pause and request human approval before writing any normative content: new responsibilities, low-confidence conflict resolution, task promotion to requirement, new ADR creation, deprecation of existing entries.
- **FR-010**: System MUST present governed decisions one at a time; MUST NOT batch multiple questions in a single prompt.
- **FR-011**: Every governed decision MUST include "flag as unresolved" as a valid option.
- **FR-012**: System MUST accept and correctly interpret natural language responses to governed decisions.
- **FR-013**: System MUST allow refine session to be paused at any point, leaving unprocessed raw items in queue for future session.
- **FR-014**: System MUST append structured changelog entry at end of every refine session, recording all autonomous actions and governed decisions with human's rationale.
- **FR-015**: Unresolved ambiguities MUST be stored as open ADR entries in decisions file and remain queryable.

---

## Feature 001 — Functional Requirements: Query/Reason (FR-016–FR-023)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-f6a7]

- **FR-016**: Before retrieving any content, system MUST classify each query by topic scope and reasoning mode.
- **FR-017**: System MUST support five reasoning modes: `gap-analysis`, `design-proposal`, `diagram`, `stakeholder-query`, `decision-recall`.
- **FR-018**: System MUST restrict retrieval to candidate files determined by query classification; non-candidate files MUST NOT be loaded.
- **FR-019**: Retrieved context MUST be assembled with source labels (file name and entry title) for cited answers.
- **FR-020**: System MUST enforce hard ceiling on retrieved chunks and notify user when ceiling reached.
- **FR-021**: When retrieval is insufficient, system MUST identify specific missing knowledge and offer to initiate a capture.
- **FR-022**: Second-stage retrieval against large source document chunks MUST be triggered for precision modes (`design-proposal`) and suppressed for structural overview modes (`diagram`, `gap-analysis`).
- **FR-023**: System MUST adapt retrieval strategy based on distilled knowledge base size: in-context loading for small (≤50), local index for medium (51–500), hosted index for large (>500).

---

## Feature 001 — Success Criteria (SC-001–SC-008)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-f2a3]

- **SC-001**: Domain expert can submit new capture item in under 30 seconds from decision to capture, without leaving current tool.
- **SC-002**: At least 70% of raw items in a typical refine session are processed autonomously with no human prompt.
- **SC-003**: Each governed decision resolved in at most 2 exchanges.
- **SC-004**: Reasoning query against a domain with fewer than 500 distilled entries returns cited answer in under 60 seconds.
- **SC-005**: When system cannot answer a query, it identifies specific missing knowledge in 100% of cases (no speculation).
- **SC-006**: Every normative change to any distilled file is traceable to a specific human decision and rationale in changelog.
- **SC-007**: All open architecture decisions discoverable via a single natural language query.
- **SC-008**: New team member can correctly identify domain ownership, active interfaces, and unresolved decisions using queries alone, without reading raw items.

---

## Feature 001 — Assumptions
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-b4c5]

- Primary users are software engineers, tech leads, and architects within a defined software domain (Team Topology sense).
- System operates per-domain; one team or service area = one domain brain instance.
- Distilled knowledge base is intentionally kept small and opinionated — a large or rapidly growing distilled set is a quality signal problem.
- Authentication and access control within the knowledge repository are out of scope for v1.
- System supports one generalist refine agent in v1; specialist subagents are a future concern.
- Cross-domain federation — queries spanning multiple domain brains — is out of scope for v1.
- Automated capture triggers from CI/CD pipelines or third-party integrations are out of scope for v1.
- Large document size threshold is a sensible default (~10 pages); exact calibration is an implementation detail.
- Knowledge persists as human-readable, diffable files in a version-controlled repository — a constraint, not an assumption.
- All knowledge files use Markdown with YAML frontmatter.

---

## Feature 002 — User Stories (US1–US4)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-e1f2, domain-20260306-e3f4, domain-20260306-e5f6, domain-20260306-e7f8]

### US1 — Frame the Domain Identity
A domain steward runs `/frame` when initialising a new domain brain or at any time to update what the domain is about. The command collects the domain's one-line headline, a 3–5 sentence pitch, an explicit "in scope" list, and an equally explicit "out of scope" list. Without this framing, the domain brain has no way to judge whether captured or seeded knowledge belongs here or elsewhere.

**Acceptance scenarios**:
1. No `config/identity.md` → `/frame` interactively collects all fields, writes complete `config/identity.md` with auto-populated domain name and steward.
2. Existing `config/identity.md` → `/frame` presents current values and allows selective updates, overwrites with new values.
3. Inline arguments providing all required fields → `/frame` writes `config/identity.md` without interactive questions.

### US2 — Seed Knowledge from Existing Sources
A domain steward runs `/seed <source>` to import existing team knowledge — design documents, runbooks, decision logs, exported wiki pages — into the raw queue. Rather than manually re-typing, `/seed` reads the source, segments it into atomic items, and uses the domain identity to pre-filter relevance before writing raw items.

**Acceptance scenarios**:
1. Complete identity + `/seed path/to/document.md` → reads, segments at logical boundaries, creates one raw item per in-scope segment (`source.tool: seed`, `source.location` set), skips out-of-scope, flags ambiguous, reports session summary.
2. Complete identity + `/seed URL` → fetches page, segments, applies relevance filter, raw items with URL as `source.location`.
3. Complete identity + `/seed path/to/docs/` → processes every `.md` and `.pdf` in directory through same pipeline.
4. No `config/identity.md` → stops immediately with clear error directing user to run `/frame` first.
5. Source with no heading structure → falls back to paragraph breaks and warns user segment boundaries may be imprecise.

### US3 — Refine Seeded Items with Scope Awareness
When a domain steward runs `/refine` after a seed session, the refine agent has access to the domain identity and treats seeded items appropriately. Items clearly outside the stated scope are archived autonomously without a governed decision. Items flagged as uncertain are surfaced as governed decisions confirming both type and relevance.

**Acceptance scenarios**:
1. Seeded item matching "Out of scope" list with high confidence → refine agent archives it autonomously as `out_of_scope` action, logs in changelog, does NOT present as governed decision.
2. Seeded item with `seed-note: Relevance uncertain` → presented as governed decision with both type options and "not relevant — archive" option, user's choice recorded in changelog.
3. Seeded item with no `seed-note`, clearly in scope → processed identically to manually captured item of same type.

### US4 — Query with Domain Context
When anyone queries the domain brain via `/query`, the response is framed within the domain's identity — opening with a statement of what the domain owns and why it exists. New team members and colleagues from other domains get immediate orientation.

**Acceptance scenarios**:
1. Complete `config/identity.md` → every `/query` response begins with a domain framing statement derived from the one-line description.
2. No `config/identity.md` → `/query` proceeds normally without error and without a framing line.

---

## Feature 002 — Edge Cases
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-e9fa]

- **/seed on URL requiring authentication**: Stops for that URL, logs as inaccessible in session summary, continues with remaining sources.
- **`config/identity.md` with empty "Out of scope" list**: All segments treated as ambiguous; session summary warns user.
- **Seeded item identical to existing raw item**: Standard duplicate detection in `/refine` handles it.
- **User re-runs /seed on same source after prior refine cycle**: New raw items created; `/refine` deduplication handles duplicates.
- **/frame run on domain with existing distilled knowledge or seeded raw items**: Writes identity normally. If seeded raw items exist, warns that scope classifications may be stale. If distilled entries exist, warns similarly.
- **Source directory with unsupported formats (.docx, .xlsx)**: Skips them, lists in session summary, tells user to export to Markdown or PDF.

---

## Feature 002 — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-f5f6]

- **Delivery mechanism**: Claude command files (`.claude/commands/*.md`) — no standalone app, no external services, no compilation step.
- **Command surface**: `/frame` (new), `/seed` (new); `/refine`, `/query` (enhanced).
- **Storage format**: All outputs are Markdown files with YAML frontmatter in the version-controlled domain brain directory.
- **Supported source types**: Local Markdown files, local PDFs, public web URLs. Authenticated enterprise APIs deferred to future release.
- **Host AI**: Claude Code via Claude command files; built-in tools only (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash` for git).

---

## Feature 002 — Functional Requirements: /frame Command (FR-001–FR-006)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-edee]

- **FR-001**: System MUST provide a `/frame` command that creates or updates `config/identity.md` in domain brain root.
- **FR-002**: `config/identity.md` MUST contain: domain name, one-line description (≤15 words), pitch (3–5 sentences), in-scope list (≥1 item), out-of-scope list (≥1 item), steward name, creation date.
- **FR-003**: Domain name MUST be auto-populated from domain brain root directory name without prompting.
- **FR-004**: Steward name MUST be auto-populated from git user name; if unavailable, user is prompted once.
- **FR-005**: When re-running `/frame` on a domain with existing `config/identity.md`, command MUST present current values and allow selective updates rather than restarting from scratch.
- **FR-005a**: After updating `config/identity.md`, if any raw items with `source.tool: seed` exist in queue, `/frame` MUST warn user and recommend running `/refine` to review them. No automatic re-flagging.
- **FR-006**: `config/identity.md` MUST be a human-readable Markdown file users can edit directly without running any command.

---

## Feature 002 — Functional Requirements: /seed Command (FR-007–FR-015)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-eff0]

- **FR-007**: System MUST provide a `/seed <source>` command where `<source>` is a local file path, web URL, or directory path.
- **FR-008**: `/seed` MUST stop immediately with clear error if `config/identity.md` does not exist, directing user to run `/frame` first.
- **FR-009**: Command MUST segment source content at logical boundaries: Markdown at `##` headings (fallback `###` or paragraph breaks); PDFs at detected headings or page boundaries; web pages by heading structure. A segment is eligible only if it contains at least one complete, standalone knowledge claim — heading-only, single-phrase, or boilerplate segments are merged or discarded.
- **FR-010**: For directory sources, command MUST process every Markdown and PDF file through the same pipeline.
- **FR-011**: For each segment, command MUST classify relevance against domain identity using semantic judgment (holistic evaluation, not keyword matching alone): clearly in scope → create raw item with no flag; clearly out of scope → skip, log with reason; ambiguous → create raw item with `seed-note: Relevance uncertain`.
- **FR-012**: Every created raw item MUST have `source.tool: seed` and `source.location` set to origin path or URL.
- **FR-012a**: Title MUST be derived from nearest section heading if present; otherwise infer ≤10-word title from content. Title MUST NOT be blank.
- **FR-013**: Single `/seed` session MUST NOT produce more than 100 raw items (default cap). When cap reached, stop, report unprocessed remaining, prompt user to re-run. Cap overridable with `--limit N`.
- **FR-013a**: Session end MUST output summary: items created, skipped, flagged, files/URLs unreadable, and if cap reached — unprocessed remaining.
- **FR-014**: Unsupported file formats MUST be skipped with log entry instructing user to export to Markdown or PDF.
- **FR-015**: Inaccessible URLs MUST be logged in session summary rather than stopping the whole seed session.

---

## Feature 002 — Functional Requirements: /refine Enhancements (FR-016–FR-019)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-f1f2]

- **FR-016**: Refine subagent MUST read `config/identity.md` (if it exists) as part of its context to inform scope judgements.
- **FR-017**: When a raw item's content clearly matches a term on the "Out of scope" list in `config/identity.md` with high confidence, refine subagent MUST classify it as an `out_of_scope` autonomous action and archive it without a governed decision.
- **FR-018**: The `out_of_scope` autonomous action MUST be recorded in session changelog, including item id, matched out-of-scope term, and archive outcome.
- **FR-019**: When a raw item has `seed-note: Relevance uncertain` in its frontmatter, refine subagent MUST present it as a governed decision including both type options and a "not relevant — archive" option.

---

## Feature 002 — Functional Requirements: /query Enhancements (FR-020–FR-022)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-f3f4]

- **FR-020**: `/query` MUST read `config/identity.md` as the first context element (before any distilled files) if the file exists.
- **FR-021**: When `config/identity.md` exists, every query response MUST include a one-line domain framing statement derived from the identity's one-line description.
- **FR-022**: When `config/identity.md` does not exist, `/query` MUST proceed normally without error and without a framing statement.

---

## Feature 002 — Success Criteria (SC-001–SC-006)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-f9fa]

- **SC-001**: Domain steward can produce complete `config/identity.md` for a new domain in under 3 minutes using `/frame`.
- **SC-002**: Running `/seed` against a 50-page source document produces categorised raw items in under 2 minutes, with no manual segmentation required. Sessions producing more than 100 raw items stop cleanly at cap and report remaining segments.
- **SC-003**: At least 75% of seeded segments correctly classified as in-scope, out-of-scope, or uncertain relative to a human reviewer's independent classification.
- **SC-004**: After a seed-and-refine cycle, zero out-of-scope items (per `identity.md`) appear in any distilled file.
- **SC-005**: Every `/query` response for a domain with complete identity includes a domain framing statement.
- **SC-006**: Domain steward can onboard an existing knowledge base of 5 documents (~200 pages total) into the raw queue using only `/frame` and `/seed`, without writing a single raw item manually.

---

## Feature 002 — Assumptions
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-fbfc]

1. Users are expected to run `/frame` before `/seed` or `/capture` for the first time.
2. Web URLs are publicly accessible without authentication. Authenticated sources require manual export.
3. Relevance filter uses Claude's language understanding — no external classifier or embedding model required.
4. A single `config/identity.md` per domain brain instance covers all v1 needs.
5. Re-seeding the same source after a prior refine cycle is a valid workflow; `/refine` deduplication handles duplicates.
6. The `seed-note` frontmatter field is a new convention introduced by this feature, understood by the enhanced `/refine` subagent.

---

## Cross-cutting Quality Requirement — Token Efficiency (FR-024)
**Type**: requirement
**Captured**: 2026-03-06
**Source**: [domain-20260306-d5e6]

- **FR-024**: The domain brain SHOULD avoid unnecessary token usage by limiting the context loaded during refinement and query operations to files relevant to the items or query being processed. Loading irrelevant distilled files into the context window is considered a quality defect.

Satisfying mechanisms:
- `/query`: ADR-003 (tiered retrieval — only candidate files loaded based on query classification)
- `/refine`: ADR-015 (type-aware context loading — only `routes_to` targets of batch item types loaded, plus `decisions.md` and `config/identity.md` always)

---

## Feature 003 — User Stories (US1–US3)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-a3f1, domain-20260312-b7c2, domain-20260312-d9e4]

### US1 — Fast Batch Processing via Host Pre-Filtering
A user invokes `/refine` with a raw queue containing 20 items. Before any subagent is invoked, the host eliminates exact duplicates (items whose content already exists verbatim in the distilled knowledge base) and items that clearly fall outside the domain scope (as defined in `config/identity.md`). The subagent receives only the items that genuinely require reasoning.

**Acceptance scenarios**:
1. Given a raw queue item whose content is identical to an existing distilled entry, When `/refine` runs, Then the host discards or archives the item before invoking any subagent, and the item does not appear in the subagent's input.
2. Given a raw queue item whose content matches a keyword or pattern explicitly listed in the domain's Out-of-scope list, When `/refine` runs, Then the host archives the item as out-of-scope before invoking any subagent.
3. Given a batch of 20 items where 8 are duplicates and 4 are out-of-scope, When `/refine` runs, Then the subagent receives at most 8 items, and all 12 filtered items are accounted for in the session output.

### US2 — Specialist Subagents Per Item-Type Cluster
A user invokes `/refine` with a mixed batch containing requirements, interface definitions, and ADR items. Instead of routing all items to one generalist subagent, the host routes each item to a specialist subagent matched to its type cluster. Each specialist uses a focused context window containing only the distilled files relevant to its type.

**Acceptance scenarios**:
1. Given a raw item classified as type `requirement`, When `/refine` runs, Then the item is routed to the requirements specialist subagent, not a generalist.
2. Given a raw item classified as type `interface`, When `/refine` runs, Then the item is routed to the interfaces specialist subagent with only interface-relevant distilled context loaded.
3. Given a batch with items of three different type clusters, When `/refine` runs, Then each item is processed by its corresponding specialist and the host merges the results into a single session output.
4. Given an item whose type cannot be determined, When `/refine` runs, Then the item falls back to the generalist subagent with full context.

### US3 — Improved Type Inference at Capture and Seed Time
A user invokes `/capture` or `/seed` to add new knowledge items. Instead of defaulting to type `other` when the type is ambiguous, the system applies higher-confidence inference rules to assign a specific type. This prevents `other`-typed items accumulating in the raw queue and triggering the full-load penalty during `/refine`.

**Acceptance scenarios**:
1. Given a captured item whose content clearly describes a system interface, When `/capture` runs, Then the item is assigned type `interface` rather than `other`.
2. Given a captured item whose content clearly describes a decision or rationale, When `/capture` runs, Then the item is assigned type `decision` rather than `other`.
3. Given a captured item that is genuinely ambiguous with no strong type signal, When `/capture` runs, Then the item is assigned type `other`.
4. Given a `/refine` session where no items are typed `other`, When the host loads context, Then the full-distilled-files load is not triggered and only type-specific files are loaded.

---

## Feature 003 — Edge Cases
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-2f5a]

- **Near-duplicate items**: Host pre-filtering handles only exact duplicates; semantically similar but non-identical items pass through to the subagent for reasoning.
- **Batch spans more types than specialist subagents exist**: Items whose type has no dedicated specialist fall back to the generalist subagent.
- **Out-of-scope list empty or missing in `config/identity.md`**: Host pre-filtering skips scope-based elimination and passes all items to the subagent.
- **Type inference confidence below threshold at capture time**: Item is stored as type `other` with a flag indicating low-confidence inference.
- **Host pre-filters all items in a batch (nothing left for subagent)**: The `/refine` session completes immediately with a summary of what was filtered and why; no subagent is invoked.

---

## Feature 003 — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-4e1d]

- **Delivery mechanism**: All changes are implemented as modifications to Claude command/skill files and their supporting prompt instructions — no standalone application.
- **Command surface**: Changes affect `/refine` (host pre-filtering, specialist routing), `/capture` (type inference), and `/seed` (type inference for bulk-imported items). No new commands are introduced.
- **Storage format**: Markdown with YAML frontmatter in version-controlled repository; no schema changes required.
- **Host AI**: Claude (claude-sonnet-4-6+); specialist subagents are additional Agent tool invocations orchestrated by the existing host.

---

## Feature 003 — Functional Requirements: Pre-Filtering (FR-001–FR-004)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-8c6b]

- **FR-001**: Before invoking any subagent, the `/refine` host MUST compare each raw item's content against all existing distilled entries and exclude exact duplicates from the subagent batch.
- **FR-002**: Before invoking any subagent, the `/refine` host MUST evaluate each raw item against the Out-of-scope list in the domain identity document and exclude items that clearly match Out-of-scope criteria.
- **FR-003**: Items excluded by pre-filtering MUST be accounted for in the session output (archived or discarded) with a reason recorded.
- **FR-004**: Pre-filtering MUST NOT exclude items that are ambiguous or only partially matching Out-of-scope criteria; those MUST pass through to the subagent.

---

## Feature 003 — Functional Requirements: Specialist Subagents (FR-005–FR-009)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-8c6b]

- **FR-005**: The `/refine` host MUST route each item to a subagent matched to the item's type cluster rather than always using a single generalist subagent.
- **FR-006**: Each specialist subagent MUST receive only the distilled context files relevant to its type cluster (as defined by the type-routing rules established in ADR-015).
- **FR-007**: At least the following type clusters MUST have dedicated specialists: `requirements`, `interfaces`, `decisions` (ADRs).
- **FR-008**: Items of type `other` or any type without a dedicated specialist MUST fall back to the generalist subagent.
- **FR-009**: The host MUST merge results from all specialist invocations into a single coherent session output before presenting results to the user.

---

## Feature 003 — Functional Requirements: Type Inference at Capture and Seed (FR-010–FR-014)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-8c6b]

- **FR-010**: At `/capture` time, the system MUST apply type inference logic to assign the most specific applicable type to each new item.
- **FR-011**: At `/seed` time, the same type inference logic MUST be applied to each item ingested from the source material, so that bulk-imported items arrive in the raw queue with specific types rather than defaulting to `other`.
- **FR-012**: Type inference MUST use content signals (keywords, structural patterns, referenced entities) to distinguish between `requirements`, `interfaces`, `decisions`, and other known types.
- **FR-013**: Type inference MUST assign type `other` only when no type-specific signal exceeds the confidence threshold.
- **FR-014**: Items assigned type `other` at capture or seed time MUST be flagged to indicate that inference was inconclusive, to aid future reclassification.

---

## Feature 003 — Success Criteria (SC-001–SC-005)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-3b9c]

- **SC-001**: At least 30% of raw items in a representative batch are eliminated by host pre-filtering (duplicate or out-of-scope) before any subagent is invoked, reducing subagent input size by at least 30% on average.
- **SC-002**: At least 70% of raw items are processed fully autonomously (no human intervention required) across a representative set of `/refine` sessions, meeting the existing SC-002 autonomy target more consistently than the baseline.
- **SC-003**: The governed-decision rate (items escalated to human review) drops by at least 20% for batches processed by specialist subagents compared to the generalist baseline on the same item types.
- **SC-004**: Fewer than 20% of newly captured or seeded items are assigned type `other` after the improved inference is in place, compared to the pre-improvement baseline.
- **SC-005**: No `/refine` session triggers a full-distilled-files load unless at least one item in the batch genuinely cannot be typed (i.e., is legitimately `other`).

---
