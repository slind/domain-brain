# Requirements — Archived

<!-- Entries captured 2026-03-06 through 2026-03-12 (Features 001, 002, 004 and cross-cutting). Split from requirements.md on 2026-03-17. -->

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
