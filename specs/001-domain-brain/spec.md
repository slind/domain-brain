# Feature Specification: Software Domain Brain

**Feature Branch**: `001-domain-brain`
**Created**: 2026-03-05
**Status**: Draft
**Input**: User description: "please create the specification based on the content of this document: domain-brain-spec.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture a Knowledge Item (Priority: P1)

A domain expert — an engineer, tech lead, or architect — encounters a piece of knowledge they want to preserve: a new interface contract, a team responsibility, a decision made in a meeting, or a requirement from a stakeholder. They capture it immediately with minimal friction from wherever they are working (their IDE or chat interface), providing only a description and perhaps a title and a type. The system generates the required structure around it automatically and queues it for refinement.

**Why this priority**: Capture is the entry point of the entire system. Without fast, low-friction intake, knowledge never enters the system and the refine and reason layers have nothing to work with. This is the most critical daily behaviour.

**Independent Test**: Can be fully tested by submitting a raw capture item with a title and type and verifying a correctly formatted capture envelope is created and persisted in the raw queue.

**Acceptance Scenarios**:

1. **Given** a domain expert in their IDE, **When** they invoke the capture command, provide a title ("Payments owns checkout error handling") and select type ("responsibility"), **Then** a valid raw item is created with auto-populated id, source, domain, timestamp, and author fields, and a status of "raw".
2. **Given** a domain expert in a chat interface, **When** they invoke `/capture` and paste unstructured text, **Then** the system extracts a title, infers the type, formats the capture envelope, and asks for confirmation only if the type is genuinely ambiguous.
3. **Given** a submitted raw item, **When** a required envelope field is missing, **Then** the system flags the item as malformed and does not add it to the raw queue until corrected.

---

### User Story 2 - Refine Raw Items Into Distilled Knowledge (Priority: P2)

A domain expert initiates a refine session to process their accumulated raw queue. The system works through the queue autonomously — deduplicating, summarising, aggregating, normalising, and routing items it can handle with high confidence. When it encounters a conflict, a new normative fact, or something it cannot classify reliably, it pauses and presents the human with a clear, single decision. The human responds in natural language and the session continues. At the end, the expert sees a summary of what changed, what was skipped, and what remains open.

**Why this priority**: Refinement is the product. The quality of distilled knowledge determines whether the Reason layer is reliable or useless. Without refinement, captured items pile up as noise.

**Independent Test**: Can be fully tested by running a refine session on a raw queue containing both simple items (deduplication, routing) and at least one conflict. Verify autonomous items are processed without prompts and the conflict triggers a single governed decision.

**Acceptance Scenarios**:

1. **Given** a raw queue with a duplicate entry, **When** a refine session runs, **Then** the duplicate is merged into the existing distilled entry silently, and the raw item is archived without human input.
2. **Given** two raw items that assign the same responsibility to different teams, **When** the refine agent encounters them, **Then** it pauses, presents both captures with clearly labelled options (including "flag as unresolved"), and waits for one human decision before proceeding.
3. **Given** a human responds "go with B but add a note that this needs an architecture call", **When** the agent processes the response, **Then** the distilled entry reflects option B and the note is recorded, not just the letter "B".
4. **Given** a refine session in progress, **When** the human says "skip for today", **Then** the session pauses cleanly and remaining raw items stay in the queue for a future session.
5. **Given** a completed refine session, **When** the session ends, **Then** a changelog entry is appended listing all autonomous actions and all governed decisions with their rationale.
6. **Given** a raw queue with entries that are not dublicates, but describe the same thing, **When** a refine session runs, **Then** the identical parts are merged into the existing distilled entry silently, and the raw item is archived without human input if confidence is high.
7. **Given** a raw queue with entries that describe multiple types of information, **When** a refine session runs, **Then** the parts are split into multiple items with appropriate types, and the raw item is archived without human input if confidence is high.

---

### User Story 3 - Query Domain Knowledge (Priority: P3)

A domain expert needs to answer a design, decision, or planning question about their domain. They ask in natural language. The system classifies the query, retrieves only the relevant portions of the distilled knowledge base, and returns a cited, grounded answer. If it cannot answer well due to missing knowledge, it names the specific gap and offers to capture it.

**Why this priority**: Reasoning is the payoff of the system. It converts the distilled knowledge base into actionable insight. Without it, the system is just a structured note store.

**Independent Test**: Can be fully tested by submitting each of the five supported query types against a populated distilled knowledge base and verifying cited, scoped answers are returned.

**Acceptance Scenarios**:

1. **Given** a populated distilled knowledge base, **When** the expert asks "Who owns the onboarding flow?", **Then** the system retrieves from stakeholders and domain knowledge only, and returns a cited answer naming the owning team.
2. **Given** a distilled knowledge base with open ADRs, **When** the expert asks "What is blocking progress toward our vision?", **Then** open decisions appear in the answer alongside requirements gaps, each attributed to its source file and entry.
3. **Given** a query that requires an interface definition that has not been captured, **When** the system cannot find sufficient context, **Then** it names the specific missing knowledge (e.g., "no interface definition for the current callback contract") and asks whether to capture it now or proceed with flagged gaps.
4. **Given** a query where retrieval would exceed the chunk cap, **Then** the system notifies the user that a more specific query may yield better results rather than silently truncating context.

---

### User Story 4 - Process Large Linked Documents (Priority: P4)

A domain expert captures a large document — a compliance specification, an architecture PDF, or a content export — that is too large to treat as a single raw item. The system automatically processes it into queryable chunks, stores a summary and chunk references in the appropriate distilled file, and makes its contents discoverable through targeted retrieval when queries require that level of detail.

**Why this priority**: Real domains accumulate large reference documents. Without large document support, the system cannot represent compliance requirements, external specifications, or legacy design docs — leaving critical knowledge outside the brain.

**Independent Test**: Can be fully tested by capturing a document exceeding the large document threshold, then issuing a precision query (design-proposal or compliance mode) and verifying the answer cites chunk-level detail from the source document.

**Acceptance Scenarios**:

1. **Given** a captured item linking to a document above the large document threshold, **When** the pipeline processes it, **Then** the document is chunked at logical boundaries and a distilled entry is created with a summary and chunk references.
2. **Given** a precision query (design-proposal or compliance reasoning mode), **When** the distilled summary is insufficient, **Then** the system performs a second-stage retrieval against the source document index to surface specific passages.
3. **Given** an overview query (diagram or gap-analysis mode), **When** the distilled summary is present, **Then** the system uses the summary only and does not trigger second-stage document retrieval.

---

### User Story 5 - Track and Discover Open Decisions (Priority: P5)

A domain expert wants to know what architecture questions are currently unresolved in their domain. They query for open decisions and receive a list of open ADRs with context, the options considered, and the reason each was left unresolved. They can also encounter open decisions as cited context in other queries, making ambiguity visible rather than hidden.

**Why this priority**: Hidden ambiguity is a primary cause of rework and misalignment. Making open decisions first-class and queryable surfaces them at the right moment.

**Independent Test**: Can be fully tested by flagging an item as unresolved during a refine session, then querying "what decisions are pending?" and verifying the open ADR appears with options and rationale.

**Acceptance Scenarios**:

1. **Given** a conflict flagged as unresolved during refinement, **When** stored in the decisions file, **Then** it includes status (open), the conflicting captures, the options considered, and the reason it was left pending.
2. **Given** an open ADR in the decisions file, **When** the expert queries a topic that intersects the open decision, **Then** the open ADR appears in the cited context with its status clearly marked.

---

### Edge Cases

- What happens when a captured item has type "other" and the agent cannot confidently classify it even after analysis?
ANSWER: During refinement, the user is asked to confirm a candidate type or provide another type.
- What happens if two different team members capture conflicting information in the same session?
ANSWER: If the conflict cannot be resolved with high confidence during refinement automatically, the user is asked to resolve the issue.
- What happens when a raw item references a large document that is no longer accessible at processing time?
ANSWER: If this happens during refinement, the user is asked to provide a new source.
- What happens if a human's governed decision response maps to none of the offered options?
ANSWER: Infer what the users intent is from a natural response. 
- What happens when a distilled file grows large enough that even the candidate portion no longer fits within retrieval limits?
ANSWER: The system automatically splits the oversized distilled file into sub-files (e.g., by entry type or time range) and updates internal references accordingly. The split is a governed action: the system proposes the split boundary and the user confirms before any file restructuring is committed.
- What happens when a query matches chunks from many files equally and the chunk cap is reached with no clear ranking?
ANSWER: Ties are broken by entry recency (most recently updated entries ranked first). The cap is then applied and the user is notified that context was truncated with a suggestion to issue a more specific query.
- What happens if the same large document is captured twice from different sources?
ANSWER: If multiple sources captures the same large document, it should be identified as a dublicate during refinement.

## Requirements *(mandatory)*

### Functional Requirements

**Capture**

- **FR-001**: System MUST allow users to submit a raw knowledge item by providing only a title and a type, with all other envelope fields populated automatically.
- **FR-002**: System MUST allow users to submit a raw knowledge item by providing only a description, with all other envelope fields populated automatically.
- **FR-003**: System MUST support a configurable set of capture types loaded at runtime from `config/types.yaml`. The default type set is: `responsibility`, `interface`, `codebase`, `requirement`, `stakeholder`, `decision`, `task`, `mom`, and `other`. Each type definition MUST include a name, a description of its intended use, a routing target (the distilled file it maps to), and at least one illustrative example.
- **FR-003a**: System MUST reload the type registry from `config/types.yaml` without requiring a restart; adding or modifying a type MUST take effect immediately.
- **FR-003b**: When presenting type options during capture or refinement, system MUST display each type's configured description alongside its name — not the bare identifier alone.
- **FR-004**: System MUST validate each captured item's envelope at intake and reject items with missing required fields, reporting which fields are absent.
- **FR-005**: System MUST never require the user to hand-author the structured envelope format; the system generates it.
- **FR-006**: When capture type is genuinely ambiguous, system MUST ask the user to confirm the type; when type can be inferred with high confidence, system MUST NOT prompt.
- **FR-007**: System MUST process documents above the large document threshold by chunking them at logical boundaries and storing chunk references alongside a summary in the relevant distilled file.

**Refine**

- **FR-008**: System MUST autonomously perform deduplication, summarisation, normalisation, aggregation, routing of `type: other`, and archiving of processed raw items when confidence is high.
- **FR-009**: System MUST pause and request human approval before writing any normative content: new responsibilities, low confidence conflict resolution, task promotion to requirement, new ADR creation, or deprecation of existing entries.
- **FR-010**: System MUST present governed decisions one at a time; it MUST NOT batch multiple questions in a single prompt.
- **FR-011**: Every governed decision MUST include "flag as unresolved" as a valid option.
- **FR-012**: System MUST accept and correctly interpret natural language responses to governed decisions, not only single-letter option codes.
- **FR-013**: System MUST allow a refine session to be paused at any point, leaving unprocessed raw items in the queue for a future session.
- **FR-014**: System MUST append a structured changelog entry at the end of every refine session, recording all autonomous actions and all governed decisions including the human's rationale.
- **FR-015**: Unresolved ambiguities MUST be stored as open ADR entries in the decisions file and remain queryable.

**Reason**

- **FR-016**: Before retrieving any content, system MUST classify each query by topic scope (which knowledge files are candidates) and reasoning mode.
- **FR-017**: System MUST support five reasoning modes: `gap-analysis`, `design-proposal`, `diagram`, `stakeholder-query`, and `decision-recall`.
- **FR-018**: System MUST restrict retrieval to candidate files determined by the query classification; non-candidate files MUST NOT be loaded.
- **FR-019**: Retrieved context MUST be assembled with source labels (file name and entry title) so the system can produce cited answers.
- **FR-020**: System MUST enforce a hard ceiling on the number of retrieved chunks and notify the user when the ceiling is reached rather than silently truncating.
- **FR-021**: When retrieval is insufficient to answer well, system MUST identify the specific missing knowledge and offer to initiate a capture for it.
- **FR-022**: Second-stage retrieval against large source document chunks MUST be triggered for precision reasoning modes (`design-proposal`) and suppressed for structural overview modes (`diagram`, `gap-analysis`).
- **FR-023**: System MUST adapt its retrieval strategy based on the size of the distilled knowledge base: in-context loading for small domains (≤50 distilled entries), local index for medium domains (51–500 entries), and hosted index for large domains (>500 entries).

### Technical Constraints

- **Delivery mechanism**: Domain Brain MUST be delivered as an extension to an existing AI
  assistant — not as a standalone application. All user-facing capabilities are exposed as
  commands, skills, and subagents. For v1, Claude is the host AI.
- **Command surface**: `/capture` (intake a raw knowledge item), `/refine` (run a refine
  session), `/query` (reason against the distilled knowledge base). Each is a Claude
  command or skill; the refine agent is a subagent orchestrated by the host.
- **Storage format**: All knowledge files use Markdown with YAML frontmatter. The structured
  envelope fields are stored in YAML frontmatter; the free-form body is Markdown. Files
  live in a version-controlled repository and MUST be human-readable without tooling.
- **Host AI**: Claude (v1). Multi-assistant support is a future iteration.

### Key Entities

- **Raw Item**: An unprocessed knowledge capture consisting of a mandatory structured envelope (id, source, type, domain, optional tags, timestamp, author, status) and a completely free-form body. Status progresses from `raw` → `refined` → `archived`. The `id` field follows the format `<domain>-<YYYYMMDD>-<4-char hex>` (e.g., `payments-20260305-a3f2`), auto-generated at capture time. The `source` field is structured: `tool` (e.g., `claude-code`, `chat`) plus an optional `location` (file path, URL, or channel name); both sub-fields are auto-populated by the system from capture context.
- **Capture Type**: A classification assigned at capture time that routes the raw item to the correct distilled knowledge file and governs how the refine agent interprets the content.
- **Distilled Entry**: A refined, structured knowledge record stored in one of the domain knowledge files (domain, codebases, interfaces, requirements, stakeholders, decisions, backlog). Each entry is the result of one or more governed or autonomous refine actions.
- **Refine Session**: A bounded working session that processes the raw item queue, producing a mix of autonomous changes and governed decisions, and concluding with a changelog entry.
- **ADR (Architecture Decision Record)**: A normative decision entry in the decisions file, with status `open` (options listed, pending resolution) or `resolved` (decision made, rationale recorded).
- **Reasoning Query**: A user question classified by topic scope and reasoning mode, answered from retrieved knowledge chunks assembled into a labelled context block.
- **Knowledge Chunk**: A bounded, retrievable unit of distilled knowledge with source attribution (file and entry title), serving as the unit of retrieval and context assembly.
- **Large Document**: A source document above the size threshold that is processed into individually retrievable chunks stored in a separate index, referenced from the distilled entry by chunk IDs.
- **Type Registry**: The `config/types.yaml` file defining the canonical set of capture types for a domain instance. Each entry specifies: `name` (identifier), `description` (intended use), `routes_to` (distilled file path), and `example` (illustrative sentence). The registry is loaded at runtime and hot-reloaded on change.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A domain expert can submit a new capture item in under 30 seconds from the moment they decide to capture something, without leaving their current tool.
- **SC-002**: At least 70% of raw items in a typical refine session are processed autonomously with no human prompt required.
- **SC-003**: Each governed decision in a refine session is resolved in at most 2 exchanges: one to present options, one to receive the answer.
- **SC-004**: A reasoning query against a domain with fewer than 500 distilled entries returns a cited, grounded answer in under 60 seconds.
- **SC-005**: When the system cannot answer a query, it identifies the specific missing knowledge in 100% of cases rather than speculating or returning a vague response.
- **SC-006**: Every normative change to any distilled file is traceable to a specific human decision and rationale in the changelog, with no exceptions.
- **SC-007**: All open architecture decisions are discoverable via a single natural language query about pending decisions.
- **SC-008**: A new team member with no prior context can correctly identify domain ownership, active interfaces, and unresolved decisions using queries alone, without reading raw items.

## Assumptions

- The primary users are software engineers, tech leads, and architects working within a defined software domain in the Team Topology sense.
- The system operates per-domain; one team or service area constitutes one domain brain instance.
- The distilled knowledge base is intentionally kept small and opinionated — a large or growing distilled set is a quality signal problem in the refine layer, not a scaling target.
- Authentication and access control within the knowledge repository are out of scope for v1; all contributors are trusted team members.
- The system supports one generalist refine agent in v1; specialist subagents (security, compliance, cross-domain consistency) are a future iteration.
- Cross-domain federation — queries spanning multiple domain brains — is out of scope for v1.
- Automated capture triggers from CI/CD pipelines or third-party integrations (issue trackers, wikis, messaging platforms) are out of scope for v1.
- The large document size threshold is a sensible default (~10 pages); exact calibration is an implementation detail.
- Knowledge persists as human-readable, diffable files in a version-controlled repository; this is a constraint, not an assumption.
- All knowledge files (raw item queue and distilled files) use **Markdown with YAML frontmatter**: the structured envelope fields are stored in YAML front matter, and the free-form body is written in Markdown. This ensures files are human-readable, diff-friendly in Git, and machine-parseable.

## Clarifications

### Session 2026-03-05

- Q: What file format should distilled knowledge files and the raw item queue use? → A: Markdown with YAML frontmatter (envelope fields in YAML front matter; free-form body in Markdown).
- Q: Is `compliance` in FR-021 a distinct 6th reasoning mode or a synonym for `design-proposal`? → A: `compliance` is a sub-mode/synonym of `design-proposal`; FR-021 updated to reference `design-proposal` only.
- Q: What entry-count thresholds define small/medium/large domains for FR-022 retrieval strategy switching? → A: small = ≤50 entries, medium = 51–500, large = >500.
- Q: What happens when a distilled file grows too large to fit within retrieval limits? → A: System automatically splits the file into sub-files (by type or time range) as a governed action requiring user confirmation.
- Q: What happens when a query matches chunks from many files equally and the chunk cap is reached with no clear ranking? → A: Break ties by entry recency (most recent first), apply the cap, and notify the user to narrow the query.

### Session 2026-03-05 (continued)

- Q: Duplicate FR-007 number — which section's FR-007 should be renumbered? → A: Keep Capture FR-007; renumber Refine FR-007→FR-008 and cascade (Refine now FR-008–FR-015, Reason now FR-016–FR-023).
- Q: What is the structure of the `source` field in the Raw Item envelope? → A: Structured field with `tool` (e.g., `claude-code`, `chat`) and optional `location` (file path, URL, or channel); both auto-populated from capture context.
- Q: What format should the Raw Item `id` field use? → A: `<domain>-<YYYYMMDD>-<4-char hex>` (e.g., `payments-20260305-a3f2`), auto-generated at capture time.
