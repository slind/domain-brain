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

## Feature 004 — User Stories (US1–US6)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-b1a2, domain-20260312-c3d4, domain-20260312-d5e6, domain-20260312-e7f8, domain-20260312-f9a1, domain-20260312-a2b3]

### US1 — View and Prioritise the Backlog (P1)
A domain steward invokes `/triage` and immediately sees the full backlog organised by priority and status. They can directly set the priority of any item in a single interaction.

**Acceptance scenarios**:
1. Given a backlog with open items of mixed priority, When a user invokes `/triage`, Then items displayed grouped as: in-progress first, then high/medium/low, with item numbers for reference.
2. Given backlog displayed, When user says "set 4 to high", Then item 4's priority updated immediately, no confirmation required.
3. When user says "show done", Then Done section listed.
4. Given empty backlog, Then friendly message shown ("Backlog is empty — capture some items first with /capture") with no error.

### US2 — AI-Assisted Reprioritisation (P2)
A domain steward gives a natural language hint and receives a proposed priority re-ranking as a table before any modification is made. The user confirms or rejects before anything is written.

**Acceptance scenarios**:
1. Given populated backlog, When user gives a hint, Then proposed changes shown as table (item, current priority, proposed priority) and written only after confirmation.
2. When user says "yes"/"apply", Then all changes written in single operation.
3. When user says "no"/"cancel", Then no changes made.
4. Given hint matches no items, Then system reports no matches and asks if user wants to rephrase.
5. When user says "apply guidelines" and guidelines document exists, Then full re-ranking proposed before applying.

### US3 — Start Work on an Item (P2)
A domain steward picks a backlog item. The system marks it `in-progress` and offers a pre-populated handoff to the feature spec workflow in one confirmation.

**Acceptance scenarios**:
1. Given open item at position N, When user says "start N", Then system marks it `in-progress` and asks "Ready to start speccing?".
2. Given confirmation prompt shown, When user says "yes", Then spec workflow launched with item's description pre-loaded.
3. Given item already `in-progress`, When user says "start N", Then system notes it is already in progress and asks if user wants to continue speccing it anyway.
4. When user says "not yet", Then item remains `in-progress` but spec workflow not launched.

### US4 — Close or Drop a Completed Item (P3)
A domain steward closes a finished item or removes a cancelled one. System requires a rationale before closing and records it in the audit log. Done items remain visible in a dedicated section.

**Acceptance scenarios**:
1. Given open item, When user says "close N", Then system asks for a one-line rationale before making any change.
2. Given rationale provided, Then item marked `done`, moved to Done section in `backlog.md`, and changelog entry appended.
3. When user says "drop N" or "remove N", Then governed decision presented with at least two options plus "flag as unresolved".
4. Given "mark as done — dropped" option chosen, Then item moved to Done with reason recorded.

### US5 — Maintain Priority Guidelines (P3)
A domain steward creates or updates a persistent guidelines document. New items from `/refine` are automatically assigned initial priority based on these guidelines. Steward can also trigger bulk re-ranking.

**Acceptance scenarios**:
1. Given no guidelines document, When user says "update guidelines", Then system presents template and writes `config/priorities.md` in single exchange.
2. Given guidelines document exists, When user says "update guidelines", Then system shows current content and allows selective updates.
3. Given guidelines exist, When new task processed by `/refine`, Then backlog entry's `**Priority**` set according to guidelines, not always `medium`.
4. Given no guidelines, Then new items default to `**Priority**: medium`.
5. When user says "apply guidelines", Then proposed re-rankings for all open items presented, awaiting confirmation before applying.

### US6 — Query Backlog via Natural Language (P3)
Anyone can ask natural language questions about backlog state via `/query` and receive a grounded, prioritised answer without needing to invoke `/triage`.

**Acceptance scenarios**:
1. Given populated backlog, When user asks "what's on the backlog?", Then `/query` classifies as `task-management` mode and returns open items grouped by priority.
2. Given item is in-progress, When user asks "what are we working on?", Then in-progress item highlighted in response.
3. When user asks "what's done?", Then `/query` returns the Done section from `backlog.md`.

---

## Feature 004 — Edge Cases
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-b4c5]

- **Empty backlog**: `/triage` shows a helpful message rather than an error or blank output.
- **All items in-progress or done**: `/triage` reports "no open items" and shows the in-progress / done sections.
- **Hint matches no items**: System reports no matches and offers to rephrase rather than silently applying no changes.
- **Guidelines file missing**: `/refine` defaults new items to `medium`; `/triage` hint-driven reprioritisation works without guidelines by asking the user to describe their intent more specifically.
- **User starts an already-in-progress item**: System notes the item is already in-progress and asks whether to re-launch the spec workflow.
- **User provides no rationale on close**: System asks once. If still no rationale, defaults to "no rationale provided" and proceeds — does not block the close.
- **Conflict between hint and explicit priority**: If a user previously set an item to `high` manually, a hint-driven proposal to lower it is clearly flagged as "overriding a manual assignment" in the proposal table.

---

## Feature 004 — Functional Requirements: /triage Command (FR-001–FR-011)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-c6d7]

- **FR-001**: System MUST provide a `/triage` command as the single entry point for all backlog lifecycle operations (view, prioritise, start, close, drop, guidelines).
- **FR-002**: `/triage` MUST display backlog items grouped in this order: in-progress → high → medium → low, with sequential item numbers for reference.
- **FR-003**: `/triage` MUST support direct priority assignment ("set N to high/medium/low") without requiring confirmation.
- **FR-004**: `/triage` MUST support hint-driven priority reassignment via an AI subagent that proposes changes as a table; changes MUST require explicit user confirmation before being written.
- **FR-005**: Hint-driven proposals MUST clearly show current priority and proposed priority for each affected item, and MUST flag items whose priority was previously set manually.
- **FR-006**: `/triage` MUST mark an item `in-progress` and offer a pre-populated handoff to the feature spec workflow when the user starts an item.
- **FR-007**: The spec workflow handoff MUST be triggered by a single confirmation ("yes" / "ready") and MUST pre-populate the feature description with the backlog item's body text.
- **FR-008**: `/triage` MUST require a rationale before closing an item and MUST record the rationale in the audit log.
- **FR-009**: Closed items MUST be moved to a `## Done` section at the bottom of `backlog.md`, not deleted.
- **FR-010**: Dropping an item MUST be a governed decision presenting at least two alternatives plus "flag as unresolved".
- **FR-011**: Every close or drop action MUST append a structured entry to `distilled/changelog.md` including item id, title, date, and rationale.

---

## Feature 004 — Functional Requirements: Priority Guidelines (FR-012–FR-014)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-d8e9]

- **FR-012**: System MUST support a persistent priority guidelines document (`config/priorities.md`) describing what types of items should be elevated, kept at medium, or deferred to low.
- **FR-013**: `/triage` MUST provide a guided single-exchange interaction for creating or updating the guidelines document.
- **FR-014**: When guidelines are updated, `/triage` MUST offer to re-rank the existing open backlog against the new guidelines (with confirmation gate before applying).

---

## Feature 004 — Functional Requirements: /refine Integration (FR-015–FR-016)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-e1f2]

- **FR-015**: When `/refine` routes a new task item to `backlog.md`, the resulting entry MUST include `**Status**: open` and `**Priority**: <value>`.
- **FR-016**: If `config/priorities.md` exists, `/refine` MUST use a subagent to evaluate the new item against the guidelines and assign an appropriate priority. If the file does not exist, priority defaults to `medium`.

---

## Feature 004 — Functional Requirements: /query Integration (FR-017–FR-019)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-f3a4]

- **FR-017**: `/query` MUST support a `task-management` reasoning mode triggered by questions about backlog state ("what's open", "what's in progress", "what should we work on", "what's done").
- **FR-018**: The `task-management` mode MUST return items grouped by priority (high → medium → low) with in-progress items highlighted.
- **FR-019**: The `task-management` mode MUST load only `backlog.md` (no other distilled files).

---

## Feature 004 — Functional Requirements: Backlog Entry Schema (FR-020–FR-022)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-a5b6]

- **FR-020**: Every backlog entry MUST carry a `**Status**` field with values `open`, `in-progress`, or `done`.
- **FR-021**: Every backlog entry MUST carry a `**Priority**` field with values `high`, `medium`, or `low`.
- **FR-022**: All 12 existing backlog entries MUST be backfilled with `**Status**: open` and `**Priority**: medium` as the initial migration.

---

## Feature 004 — Success Criteria (SC-001–SC-007)
**Type**: requirement
**Captured**: 2026-03-12
**Source**: [domain-20260312-e4f5]

- **SC-001**: A user can view the full prioritised backlog and make at least one priority change in under 2 minutes from invoking `/triage`.
- **SC-002**: 100% of priority changes proposed by AI (hint-driven or guidelines-driven) require explicit user confirmation before being written — zero silent modifications.
- **SC-003**: A user can go from "start item N" to an active feature spec session in a single `/triage` interaction, with zero manual copy-paste of the item description.
- **SC-004**: 100% of close and drop actions produce a changelog entry — zero silent removals from the active backlog.
- **SC-005**: When a priority guidelines document exists, 100% of new task items processed by `/refine` arrive in `backlog.md` with a priority field set by the guidelines (not always defaulting to `medium`).
- **SC-006**: A user can update priority guidelines and see a proposed full re-ranking of the existing backlog within the same `/triage` session.
- **SC-007**: All common backlog status queries ("what's open?", "what's in progress?", "what should we work on?") return a cited answer via `/query` without invoking `/triage`.

---

## Feature 005 — User Stories (US1–US3): Semantic Duplicate Pre-Filtering
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a001, domain-20260313-a002, domain-20260313-a003]

### US1 — Near-Duplicates Filtered Before Subagent (P1)
A user runs `/refine` on a raw queue containing items that paraphrase or partially overlap with already-distilled knowledge. The host scores each incoming item against existing distilled entries; items at or above the similarity threshold are identified as semantic duplicates and excluded from the subagent batch automatically — the same way exact duplicates are handled today.

**Acceptance scenarios**:
1. Given a raw item that is a close paraphrase of an existing distilled entry, when `/refine` runs, then the host identifies it as a semantic duplicate, excludes it from the subagent batch, and records it as `[semantic-duplicate: <matched-entry-id>]` in the session output.
2. Given a raw item that mentions the same fact as a distilled entry using entirely different words, when `/refine` runs, then the host identifies the semantic overlap and excludes the item before any subagent is invoked.
3. Given a raw item that is genuinely new knowledge with no significant overlap to any distilled entry, when `/refine` runs, then the item passes through pre-filtering unchanged and reaches the subagent as normal.
4. Given a raw item that is an exact byte-for-byte duplicate of a distilled entry, when `/refine` runs, then the existing exact-duplicate pre-filter (Feature 003 FR-001) still catches it — no regression.

### US2 — Configurable Similarity Threshold (P2)
A domain owner wants to tune how aggressively near-duplicates are suppressed. The threshold is stored in the domain's `config/` directory and can be changed without modifying any command file.

**Acceptance scenarios**:
1. Given a similarity threshold configured in `config/`, when `/refine` runs, then the host uses that threshold for all pre-filter comparisons in the session.
2. Given no similarity threshold configured, when `/refine` runs, then the host applies a built-in default threshold and notes in session output that the default is in use.
3. Given a threshold value outside the valid range, when `/refine` runs, then the host rejects the config value, falls back to the default, and warns the user.

### US3 — Semantic Duplicate Outcomes Visible in Changelog (P3)
After a `/refine` session, a domain owner wants to understand what was suppressed and why. Semantic duplicate outcomes appear in the session changelog, clearly distinguished from other filter reasons, so users can audit the feature's behaviour and spot if the threshold needs adjustment.

**Acceptance scenarios**:
1. Given one or more semantic duplicates were suppressed in a `/refine` session, when the session completes, then each suppressed item is recorded in the session changelog entry with the matched distilled entry reference.
2. Given a `/refine` session where no semantic duplicates were found, when the session completes, then the changelog entry does not add a semantic-duplicate section (no empty noise).
3. Given a session that suppresses both exact duplicates and semantic duplicates, when the changelog is written, then the two categories appear separately and are clearly labelled.

---

## Feature 005 — Edge Cases: Semantic Duplicate Detection in /refine
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a004]

- **Multiple matches**: If a raw item is semantically similar to two or more distilled entries, the host records the closest match and suppresses the item once; both matched entries may be noted in session output.
- **Full-batch suppression**: If all items in a batch are identified as semantic duplicates, the session completes immediately with a full suppression summary; no subagent is invoked.
- **Empty or sparse knowledge base**: If the distilled knowledge base is empty or very sparse, similarity scoring finds no matches and all items pass through to the subagent as normal.
- **Micro-items**: If an item's content is too short to meaningfully compare, the host skips similarity scoring for that item and passes it through; a minimum-length threshold prevents false positives.
- **Comparison failure**: If the similarity comparison fails mid-batch, the failing item passes through to the subagent as a safe fallback; the failure is noted in session output but does not abort the session.

---

## Feature 005 — Functional Requirements (FR-001–FR-012): Semantic Pre-Filtering and Threshold Configuration
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a005, domain-20260313-a006]

### Semantic Pre-Filtering (FR-001–FR-006)
- **FR-001**: Before invoking any subagent, the `/refine` host MUST compare each raw item against all existing distilled entries for semantic similarity, extending (not replacing) the existing exact-duplicate check from Feature 003 FR-001.
- **FR-002**: The host MUST apply a configurable similarity threshold when classifying an item as a semantic duplicate; items scoring at or above the threshold MUST be excluded from the subagent batch.
- **FR-003**: Semantic duplicate items MUST be accounted for in the session output with: (a) the suppressed item's identifier, (b) the matched distilled entry reference, and (c) the basis for the match.
- **FR-004**: Items scoring below the similarity threshold MUST pass through to the subagent unchanged; the feature MUST NOT increase the false-negative rate for genuinely new knowledge.
- **FR-005**: The minimum content length for similarity comparison MUST be enforced; items below the minimum length MUST be passed through without similarity scoring.
- **FR-006**: Similarity comparison MUST be performed solely by the AI host's in-context reasoning; no external embedding APIs or external service calls are permitted. This preserves the no-external-service constraint established in Feature 003 Design Assumptions.

### Threshold Configuration (FR-007–FR-009)
- **FR-007**: A similarity threshold value MUST be readable from the domain's `config/` directory; the config key and file path MUST be documented in the feature's data model.
- **FR-008**: When no threshold is configured, the host MUST apply a documented default value and surface a visible notice in the session output.
- **FR-009**: An invalid or out-of-range threshold value MUST cause the host to fall back to the default and warn the user; it MUST NOT abort the session.

### Changelog Integration (FR-010–FR-012)
- **FR-010**: Every `/refine` session that suppresses one or more semantic duplicates MUST append a `### Semantic Duplicates` subsection to the session's changelog entry in `distilled/changelog.md`.
- **FR-011**: Sessions with zero semantic duplicates MUST NOT add a semantic-duplicate section to the changelog entry (no empty sections).
- **FR-012**: Semantic duplicate records in the changelog MUST be formatted consistently with existing exact-duplicate and out-of-scope records.

---

## Feature 005 — Technical Constraints, Key Entities, and Success Criteria
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-a007, domain-20260313-a008]

### Technical Constraints
- **Delivery mechanism**: Enhancement to the existing `/refine` Claude command file — no new command surfaces introduced.
- **Command surface**: `/refine` (modified); no new skills or commands.
- **Storage format**: Similarity threshold stored as a config value in a Markdown or YAML file under `domain/config/`; changelog entries in existing `distilled/changelog.md` format.
- **Host AI**: Claude (claude-sonnet-4-6+); multi-host support deferred per Feature 001 constraints.
- **Scope boundary**: This feature modifies the host pre-filtering stage only. Subagent logic, governed-decision flow, and distilled-file write operations are unchanged.

### Key Entities
- **Raw item**: An unprocessed knowledge capture awaiting `/refine`; has an identifier and content body.
- **Distilled entry**: An existing processed knowledge item in any `distilled/` file; the corpus against which incoming raw items are compared.
- **Similarity score**: A measure of semantic overlap between a raw item and a distilled entry; compared against the threshold to determine suppression.
- **Similarity threshold**: A configurable value stored in `domain/config/` that sets the suppression boundary; items at or above this value are treated as semantic duplicates.

### Success Criteria
- **SC-001**: The proportion of raw items autonomously resolved (without a governed human decision) increases by at least 15 percentage points above the Feature 003 baseline, pushing the overall autonomy rate toward the 90%+ target.
- **SC-002**: Zero semantic duplicate items reach the subagent when the similarity threshold is correctly configured — confirmed by running a test batch where all near-duplicate items are known in advance.
- **SC-003**: A domain owner can adjust the similarity threshold and observe a measurable change in suppression behaviour on the next `/refine` run, without modifying any command file.
- **SC-004**: Every `/refine` session output provides a complete account of all suppressed items — exact duplicates, out-of-scope items, and semantic duplicates — so that no item silently disappears from the pipeline.

---

## Feature 006 — User Stories (US1–US3): Specialist Subagent Extension
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-3c4d, domain-20260313-5e6f, domain-20260313-7a8b]

### US1 — Codebase Items Routed to Focused Specialist (P1)
A user runs `/refine` with a batch that includes items of type `codebase` — descriptions of repositories, services, or tech stack entries. Instead of falling to the generalist subagent (which loads every distilled file), these items are routed to a dedicated codebase specialist that receives only `codebases.md` and `identity.md`.

**Acceptance scenarios**:
1. Given a raw item of type `codebase` in the active batch, When `/refine` runs, Then the item is routed to the codebase specialist, not the generalist.
2. Given the codebase specialist is invoked, When it processes items, Then it receives only `codebases.md` and `identity.md` — no other distilled files.
3. Given a batch containing only `codebase` items, When `/refine` completes, Then no full-distilled-files load is triggered and SC-005 is satisfied.

### US2 — Responsibility Items Routed to Focused Specialist (P2)
A user runs `/refine` with items of type `responsibility` — team ownership records, role definitions, or accountability mappings. These are routed to a responsibility specialist that loads only `responsibilities.md` and `identity.md`, rather than the full distilled context.

**Acceptance scenarios**:
1. Given a raw item of type `responsibility` in the active batch, When `/refine` runs, Then it is routed to the responsibility specialist, not the generalist.
2. Given the responsibility specialist is invoked, When it processes items, Then it receives only `responsibilities.md` and `identity.md`.
3. Given a batch where all items are either `codebase` or `responsibility`, When `/refine` completes, Then the generalist subagent is not invoked at all.

### US3 — Mixed Batch Correctly Partitioned Across All Specialists (P2)
A user runs `/refine` with a real-world mixed batch: some requirements, some interface definitions, some codebase entries, some responsibility records, and a few unrecognised items. The host correctly partitions the batch across five specialists (requirements, interfaces, decisions, codebase, responsibility) and the generalist, merges all results, and presents a single coherent session output.

**Acceptance scenarios**:
1. Given a mixed batch covering `requirement`, `interface`, `decision`, `codebase`, and `responsibility` types plus one `other` item, When `/refine` runs, Then exactly five specialist invocations and one generalist invocation occur.
2. Given all specialist invocations complete, When the host merges results, Then the combined session output is a single coherent list of autonomous actions and governed decisions, consistent with the Feature 003 merge format.
3. Given a `codebase` or `responsibility` item that cannot be confidently acted on autonomously, When the specialist raises a governed decision, Then the governed decision appears in the merged output and is presented to the user for resolution.

---

## Feature 006 — Edge Cases: Specialist Subagent Extension
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-9c0d]

- **Missing context file for new specialist**: If `codebases.md` or `responsibilities.md` does not yet exist in the domain, the specialist is still invoked using only `identity.md`; it MUST NOT fall back to a full-context load.
- **Responsibility item spanning two distilled files**: The specialist's defined context files govern — the host does not expand the context. Items that are genuinely ambiguous across files can be escalated as governed decisions.
- **Both `codebase` and `responsibility` items in same batch**: Both specialists are invoked concurrently, following the existing multi-specialist pattern from Feature 003.
- **All items covered by specialists, no `other` or unrecognised items**: The generalist is not invoked. This is the desired outcome satisfying SC-005.
- **Governed decision from new specialist conflicts with autonomous action from another specialist**: The merge step concatenates all results; conflict resolution follows the existing governed-decision escalation flow.

---

## Feature 006 — Functional Requirements: Extended Specialist Routing in /refine (FR-001–FR-009)
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-b1e2]

- **FR-001**: The `/refine` host routing table MUST include a `codebase` type cluster with a dedicated specialist subagent.
- **FR-002**: The `/refine` host routing table MUST include a `responsibility` type cluster with a dedicated specialist subagent.
- **FR-003**: The codebase specialist MUST receive only `codebases.md` and `identity.md` as distilled context — no other distilled files.
- **FR-004**: The responsibility specialist MUST receive only `responsibilities.md` (if it exists in the domain) and `identity.md` as distilled context — no other distilled files.
- **FR-005**: If the designated context file for a new specialist does not exist in the domain, the specialist MUST still be invoked using only `identity.md`, and MUST NOT fall back to a full-context load.
- **FR-006**: Items of type `stakeholder`, `task`, `mom`, `other`, and any unrecognised types MUST continue to fall back to the generalist subagent as defined in Feature 003 FR-008.
- **FR-007**: The host MUST continue to merge results from all specialist and generalist invocations into a single coherent session output, consistent with the merge behaviour specified in Feature 003 FR-009.
- **FR-008**: The session output MUST identify which specialist handled each item (for auditability), consistent with the existing per-cluster tracking.
- **FR-009**: The updated routing table MUST be documented in `refine.md` and supersede the Feature 003 FR-007 list.

---

## Feature 006 — Technical Constraints: /refine Specialist Extension
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-c3f4]

- **Delivery mechanism**: Changes are implemented as modifications to the `/refine` command file — no standalone application or new command introduced.
- **Command surface**: Only `/refine` is modified. No changes to `/capture`, `/seed`, or any other command.
- **Storage format**: Markdown with YAML frontmatter; no schema changes required.
- **Host AI**: Claude (claude-sonnet-4-6+); new specialists are additional Agent tool invocations following the same pattern as existing specialists.

---

## Feature 006 — Success Criteria (SC-001–SC-004)
**Type**: requirement
**Captured**: 2026-03-13
**Source**: [domain-20260313-e7b8]

- **SC-001**: After this feature ships, the generalist subagent receives fewer items in a representative mixed batch — at minimum, `codebase` and `responsibility` items are no longer in its input, reducing generalist input by the proportion those types represent.
- **SC-002**: At least 70% of raw items across a representative set of `/refine` sessions are processed fully autonomously (no human intervention), meeting the system-wide SC-002 target more consistently than the Feature 003 baseline.
- **SC-003**: No `/refine` session triggers a full-distilled-files load for `codebase` or `responsibility` items; these types now satisfy SC-005 alongside requirements, interfaces, and decisions.
- **SC-004**: The governed-decision rate for `codebase` and `responsibility` items drops by at least 20% compared to processing those same items through the generalist, measured over a representative sample.

---

## Distilled Entry Consistency with Implementation (FR-024)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: [domain-20260316-a8e2, domain-20260316-c4f1]

**Motivation**: Distilled data accuracy is critical to user trust. If distilled entries describing implementation are stale or incorrect, queries produce misleading answers and users lose confidence in Domain Brain.

**Constraint**: Distilled entries that describe implementation MUST be kept current with the corresponding implementation. When implementation changes, affected distilled entries MUST be updated via the raw queue.

**Mechanism**: To be determined (see ADR-016).

---

## Feature 007 — Fix Stale /refine Interface Contract Routing Table
**Type**: requirement
**Captured**: 2026-03-16
**Source**: [domain-20260316-7a2c, domain-20260316-7a3d, domain-20260316-7a4e, domain-20260316-7a5f, domain-20260316-7a6a]

### User Story
A domain brain maintainer or developer consults the `/refine` Interface Contract to understand how item types are routed during a refine session. They need the routing table to accurately reflect the current system behaviour so they can correctly predict context loading and subagent selection.

**Why this priority**: The interface contract is the single authoritative reference for how `/refine` works. An incorrect routing table misleads developers building on or maintaining the system, and may cause future features to be designed against the wrong baseline.

**Acceptance Scenarios**:
1. Given the `/refine` Interface Contract routing table, When a developer looks up `codebase`, Then the table shows cluster `codebase` (specialist) and context files `codebases.md, identity.md`.
2. Given the `/refine` Interface Contract routing table, When a developer looks up `responsibility`, Then the table shows cluster `responsibility` (specialist) and context files `responsibilities.md (if present), identity.md`.
3. Given the routing table, When compared to the authoritative description in `codebases.md` ("Refine Pipeline — Type Clusters and Subagents"), Then the two are fully consistent with no contradictions.

### Edge Cases
- If `responsibilities.md` does not exist, the table still reflects the correct cluster assignment; the "(if present)" qualifier on the context file is preserved.
- Only the two explicitly identified rows (`codebase` and `responsibility`) are in scope for this fix; all other rows remain unchanged.

### Functional Requirements (FR-001–FR-004)
- **FR-001**: The routing table in the `/refine` Interface Contract MUST list `codebase` as routing to the `codebase` specialist cluster with context files `codebases.md, identity.md`.
- **FR-002**: The routing table MUST list `responsibility` as routing to the `responsibility` specialist cluster with context files `responsibilities.md (if present), identity.md`.
- **FR-003**: All other rows in the routing table MUST remain unchanged.
- **FR-004**: The updated routing table MUST be consistent with the "Refine Pipeline — Type Clusters and Subagents" entry in `distilled/codebases.md`.

### Technical Constraints
- **Delivery mechanism**: Direct edit to `distilled/interfaces.md` — no command file changes required.
- **Storage format**: Markdown file in version-controlled repository.
- **Scope**: Single table edit in one file. No behaviour changes; documentation fix only.

### Success Criteria (SC-001–SC-003)
- **SC-001**: The routing table in `distilled/interfaces.md` contains zero rows that contradict the routing behaviour documented in `distilled/codebases.md`.
- **SC-002**: A developer reading both files can confirm `codebase` and `responsibility` routing is identical across both sources in under 30 seconds.
- **SC-003**: The fix is a single, reviewable edit with no unintended side effects on other table rows or surrounding content.

---

## Feature 008 — Consistency-Check Mechanism
**Type**: requirement
**Captured**: 2026-03-16
**Source**: [domain-20260316-8b5a, domain-20260316-8b6b, domain-20260316-8b8d, domain-20260316-8b9e]

### Functional Requirements (FR-001–FR-008)
- **FR-001**: The consistency-check mechanism MUST identify distilled entries whose source artefacts have changed since the entry was last updated.
- **FR-002**: The mechanism MUST NOT flag entries whose source artefacts are unchanged (zero false positives on unchanged sources).
- **FR-003**: The mechanism MUST surface flagged entries with sufficient context for the steward to decide: entry title, source artefact path, and an indication of what changed.
- **FR-004**: The steward MUST be able to dismiss a flagged entry (mark as reviewed without content change).
- **FR-005**: The steward MUST be able to initiate re-capture of a flagged entry's content (handoff to `/capture` or direct edit).
- **FR-006**: The mechanism MUST operate without external services or persistent background processes, consistent with the Extension-First principle.
- **FR-007**: ADR-018 MUST be resolved before implementation begins. ADR-018 has been resolved as of 2026-03-16 as Option B: standalone `/consistency-check` command. (The Feature 008 spec referred to this as ADR-016; it is recorded as ADR-018 in `distilled/decisions.md`.)
- **FR-008**: Each consistency-check run MUST append a summary of candidates found and resolutions made to `distilled/changelog.md`.

### Technical Constraints
- **Delivery mechanism**: Claude command file — no standalone app, no server, no daemon.
- **Storage format**: Markdown with YAML frontmatter in a version-controlled repository.
- **External services**: None. Change detection uses only local information (git history or file metadata).
- **Host AI**: Claude (claude-sonnet-4-6+); built-in tools only.
- **Invocation model**: Determined by ADR-018 (Option B: standalone `/consistency-check` command).

### Success Criteria (SC-001–SC-005)
- **SC-001**: A steward can identify all distilled entries affected by a set of source changes in a single consistency-check run — zero manual cross-referencing required.
- **SC-002**: Zero false positives: entries with unchanged source artefacts are never surfaced as stale candidates.
- **SC-003**: A steward can complete the full review-and-resolve cycle for a single flagged entry in under 3 minutes.
- **SC-004**: The mechanism runs fully offline — no network access or external service calls.
- **SC-005**: ADR-018 is resolved and recorded in `distilled/decisions.md` before any implementation work begins. (Satisfied as of 2026-03-16.)

### Assumptions
- Distilled entries eligible for consistency-checking carry a `**Source**` field referencing a command file path. Entries without this field are skipped.
- Change detection uses git commit history or file modification timestamps, as specified by ADR-018 (Option B).
- The steward's action workflow (re-capture, archive, dismiss) reuses the existing `/capture` and `/refine` pipeline; no new write path is introduced.
- At any given time, 10–30 distilled entries are expected to have trackable source links — well within the in-context retrieval tier.

---

## Feature 009 — User Story 1: Detect an Oversized Distilled File (P1)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-4c5d

A steward running `/refine` encounters a distilled file that has grown beyond the reliable-retrieval threshold. Before processing any raw items, the pre-processing phase detects the oversized file and surfaces a governed decision proposing a split plan. The session pauses until the steward confirms or dismisses.

**Acceptance Scenarios**:
1. Given a distilled file above threshold, when `/refine` is invoked, then a split proposal is surfaced as a governed decision before any raw items are processed.
2. Given all distilled files below threshold, when `/refine` is invoked, then no split proposal is surfaced and the session proceeds normally.
3. Given multiple oversized files, when `/refine` is invoked, then each is surfaced as a separate governed decision, one at a time.

---

## Feature 009 — User Story 2: Confirm and Execute a Split (P2)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-6e7f

The steward reviews the proposed split (showing which entries go into each sub-file) and confirms. The system creates the sub-files, retires the original, appends a changelog entry, and resumes the raw queue — all within the same invocation.

**Acceptance Scenarios**:
1. Given a confirmed split proposal, the system creates sub-files with entries distributed as proposed.
2. The original oversized file is retired (not left as a duplicate alongside sub-files).
3. A changelog entry is appended recording the split action, source file, and resulting sub-files.
4. The refine session resumes the raw queue without requiring a new invocation.

---

## Feature 009 — User Story 3: Dismiss or Flag a Split Proposal (P3)
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-8a9b

The steward may dismiss a split proposal (skip for now) or flag it as an unresolved decision. In either case the session continues without splitting and no files are modified. The same file will be flagged again in the next session until the steward acts.

**Acceptance Scenarios**:
1. Given "skip for now", the session continues and no files are modified.
2. Given "flag as unresolved" (option Z), an open ADR is created in `decisions.md` and the session continues.
3. At the next `/refine` invocation the split proposal is surfaced again — dismissal is not permanent.

---

## Feature 009 — Functional Requirements FR-001–FR-010
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-2e3f

- **FR-001**: `/refine` MUST include a pre-processing phase that detects oversized distilled files before processing raw items.
- **FR-002**: For each oversized file, generate a split proposal grouping by recency (active/recent vs. older/archived) as default axis. Sub-file names follow `{base}-{group-label}-{n}.md`. Proposal MUST include a stated grouping rationale.
- **FR-003**: Each split proposal MUST be surfaced as a governed decision, one at a time (not batched).
- **FR-004**: Every split governed decision MUST include "flag as unresolved" as an option, creating an open ADR in `decisions.md`.
- **FR-005**: The steward MUST be able to accept, dismiss, or redirect (with a different grouping) within the governed decision exchange.
- **FR-006**: On confirmed split: create sub-files, retire the original, update changelog — then resume the raw item queue.
- **FR-007**: Executed split MUST be recorded in `distilled/changelog.md` with source file name, resulting sub-file names, entry counts per sub-file, and steward's rationale (or "no rationale provided").
- **FR-008**: After a confirmed split the refine session MUST resume the remaining raw queue within the same invocation.
- **FR-009**: The entry-count threshold MUST be configurable; a sensible default MUST apply when no configuration is present.
- **FR-010**: If a file cannot be meaningfully split (e.g., single entry), surface a warning rather than a split proposal and continue without blocking.

---

## Feature 009 — Sub-file Naming Convention
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-3c4d

Sub-file names MUST follow `{base}-{group-label}-{n}.md`:

| Component | Rule |
|---|---|
| `{base}` | Original filename without `.md` (e.g., `requirements`) |
| `{group-label}` | Derived from grouping label (`active`, `archived`) or steward-provided name |
| `{n}` | Sequential integer starting at 1; incremented if a file with that name already exists |

Examples: `requirements-active-1.md`, `requirements-archived-1.md`; steward-named groups: `requirements-core-1.md`, `requirements-legacy-1.md`.

---

## Feature 009 — Technical Constraints
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-4a5b

- **Delivery**: Integrated into `/refine` as a pre-processing phase; no separate command.
- **Command surface**: Extends `.claude/commands/refine.md` only — no new commands or storage formats.
- **Storage format**: Markdown files with YAML frontmatter; sub-files follow the same naming and header conventions as existing distilled files.
- **Host AI**: Claude (claude-sonnet-4-6+); built-in tools only (Read, Write, Edit, Glob, Bash for git).
- **Governed action pattern**: All file writes require steward confirmation. No silent file creation or deletion.

---

## Feature 009 — Edge Cases
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-0c1d

- **Single-entry oversized file**: Split cannot be proposed; system warns the steward that the entry itself may need condensing, not the file split.
- **Proposed split yields empty sub-file**: System MUST NOT propose splits resulting in empty files; must re-partition until all sub-files have at least one entry.
- **Steward wants different grouping**: System accepts natural language re-grouping instructions in the governed decision response and revises the proposal.
- **Multiple oversized files simultaneously**: Each is presented as a separate governed decision, sequentially.
- **Split sub-file later grows past threshold**: Subject to the same detection on the next refine session.
- **All entries share the same `Captured` date**: Recency grouping falls back to the `**Type**` field as a secondary axis; steward may override.

---

## Feature 009 — Success Criteria SC-001–SC-005
**Type**: requirement
**Captured**: 2026-03-16
**Source**: domain-20260316-8e9f

- **SC-001**: A steward running `/refine` against an oversized distilled file is shown a split proposal before any raw items are processed — zero sessions where oversized files silently grow further.
- **SC-002**: The steward can confirm, dismiss, or redirect a split proposal in a single exchange (at most one clarifying follow-up turn per proposal).
- **SC-003**: After a confirmed split, sub-files together contain exactly the same entries as the original — zero entries lost or duplicated.
- **SC-004**: Every executed split is recorded in the changelog with source file, sub-file names, and rationale — 100% traceability.
- **SC-005**: Dismissing a split proposal does not block the refine session — raw item processing continues within the same invocation.

---
