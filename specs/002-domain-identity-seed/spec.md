# Feature Specification: Domain Identity and Knowledge Seeding

**Feature Branch**: `002-domain-identity-seed`
**Created**: 2026-03-06
**Status**: Draft
**Input**: User description: "Domain identity framing (/frame command) and knowledge seeding from existing sources (/seed command) — defines what a domain is and imports existing knowledge from docs/PDFs/URLs, filtering by scope"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Frame the Domain Identity (Priority: P1)

A domain steward runs `/frame` when initialising a new domain brain, or at any time to update
what the domain is about. The command collects the domain's one-line headline, a 3–5 sentence
pitch, an explicit "in scope" list, and an equally explicit "out of scope" list. Without this
framing, the domain brain has no way to judge whether captured or seeded knowledge belongs here
or elsewhere.

**Why this priority**: Every other feature in this release — seeding, out-of-scope detection,
query framing — depends on the identity document existing. It is the gating prerequisite.

**Independent Test**: Run `/frame` on an initialised domain brain. Verify `config/identity.md`
is created with all required sections populated, that re-running `/frame` updates the file
rather than failing, and that a non-interactive invocation with all fields provided produces a
valid file without user prompts.

**Acceptance Scenarios**:

1. **Given** a domain brain with no `config/identity.md`, **When** the user runs `/frame`,
   **Then** the command interactively collects headline, pitch, in-scope items, and out-of-scope
   items, and writes a complete `config/identity.md` with domain name auto-populated from the
   directory and steward auto-populated from git user.

2. **Given** a domain brain with an existing `config/identity.md`, **When** the user runs
   `/frame` again, **Then** the command presents the current values for each field and allows
   the user to update them, then overwrites the file with the new values.

3. **Given** a domain brain, **When** the user runs `/frame` with inline arguments providing
   all required fields, **Then** the command writes `config/identity.md` without asking
   interactive questions.

---

### User Story 2 - Seed Knowledge from Existing Sources (Priority: P2)

A domain steward runs `/seed <source>` to import existing team knowledge — design documents,
runbooks, decision logs, exported wiki pages — into the raw queue. Rather than manually
re-typing knowledge that already exists, `/seed` reads the source, segments it into atomic
items, and uses the domain identity to pre-filter relevance before writing raw items.

**Why this priority**: The primary adoption barrier is that teams already have years of
knowledge in other tools. Without seeding, adopting this tool requires starting from scratch.
Seeding removes that barrier while the domain identity filter prevents importing noise.

**Independent Test**: Run `/seed` against a multi-section Markdown document that contains a
mix of clearly in-scope sections, clearly out-of-scope sections (matching the "Out of scope"
list in identity.md), and ambiguous sections. Verify: in-scope sections produce standard raw
items; out-of-scope sections are skipped and logged; ambiguous sections produce raw items
flagged with `seed-note: Relevance uncertain`. Verify the seed session summary reports all
three counts correctly.

**Acceptance Scenarios**:

1. **Given** a domain brain with a complete `config/identity.md`, **When** the user runs
   `/seed path/to/document.md`, **Then** the command reads the document, segments it at
   logical section boundaries, creates one raw item per in-scope segment (with
   `source.tool: seed` and `source.location` pointing to the origin), skips out-of-scope
   segments, flags ambiguous segments, and reports a session summary.

2. **Given** a domain brain with a complete `config/identity.md`, **When** the user runs
   `/seed https://example.com/docs/page`, **Then** the command fetches the page, segments it,
   applies the same relevance filter, and produces raw items with the URL as
   `source.location`.

3. **Given** a domain brain with a complete `config/identity.md`, **When** the user runs
   `/seed path/to/docs/` (a directory), **Then** the command processes every Markdown and PDF
   file in the directory through the same pipeline, reporting a combined session summary.

4. **Given** a domain brain with **no** `config/identity.md`, **When** the user runs `/seed`,
   **Then** the command stops immediately with a clear error directing the user to run
   `/frame` first.

5. **Given** a source document with no detectable heading structure, **When** the user runs
   `/seed`, **Then** the command falls back to splitting at paragraph breaks and warns the
   user that the segment boundaries may be imprecise.

---

### User Story 3 - Refine Seeded Items with Scope Awareness (Priority: P3)

When a domain steward runs `/refine` after a seed session, the refine agent has access to the
domain identity and treats seeded items appropriately. Items clearly outside the domain's
stated scope are archived autonomously without requiring a governed decision. Items flagged as
uncertain are surfaced as governed decisions that confirm both type and relevance.

**Why this priority**: Seeding without scope-aware refinement would flood the distilled base
with noise. The value of seeding is only realised if the refine step correctly filters what
was imported.

**Independent Test**: Seed a source that mixes in-scope and out-of-scope content. Run
`/refine`. Verify: items matching the "Out of scope" list are archived with a log entry but no
governed decision prompt; items flagged `seed-note: Relevance uncertain` produce governed
decisions that include a "not relevant — archive" option; the changelog records all outcomes.

**Acceptance Scenarios**:

1. **Given** a raw queue containing a seeded item whose content matches a term on the
   `config/identity.md` "Out of scope" list with high confidence, **When** the user runs
   `/refine`, **Then** the refine agent archives the item autonomously as an `out_of_scope`
   action, logs it in the changelog, and does not present it as a governed decision.

2. **Given** a raw queue containing a seeded item flagged with `seed-note: Relevance
   uncertain`, **When** the user runs `/refine`, **Then** the refine agent presents it as a
   governed decision including both type options and a "not relevant — archive" option, and
   records the user's choice in the changelog.

3. **Given** a raw queue containing a seeded item with no `seed-note` flag and content
   clearly in scope, **When** the user runs `/refine`, **Then** the item is processed
   identically to a manually captured item of the same type.

---

### User Story 4 - Query with Domain Context (Priority: P4)

When anyone queries the domain brain via `/query`, the response is framed within the domain's
identity — opening with a statement of what the domain owns and why it exists. New team
members and colleagues from other domains get immediate orientation, not just isolated facts.

**Why this priority**: This enhances an existing command. It improves answer quality once the
identity exists but does not introduce a new workflow. Value depends on P1 being done first.

**Independent Test**: Populate `config/identity.md` with a complete identity. Run `/query`
with any question. Verify every response begins with a domain framing statement derived from
the one-line description. Verify that without `config/identity.md`, queries proceed normally
without error.

**Acceptance Scenarios**:

1. **Given** a domain brain with a complete `config/identity.md`, **When** the user runs any
   `/query`, **Then** the response header includes the domain one-line description to orient
   the reader before presenting the answer.

2. **Given** a domain brain with **no** `config/identity.md`, **When** the user runs
   `/query`, **Then** the command proceeds normally without error and without a framing line.

---

### Edge Cases

- What if `/seed` is run on a URL that requires authentication? The command stops for that
  URL, logs it as inaccessible in the session summary, and continues with remaining sources.
- What if `config/identity.md` has an empty "Out of scope" list? All segments are treated as
  ambiguous — no out-of-scope filtering is performed and the session summary warns the user.
- What if a seeded item is identical to an existing raw item? Standard duplicate detection
  in `/refine` handles it; no special seeding logic needed.
- What if the user re-runs `/seed` on the same source after a prior refine cycle? New raw
  items are created; `/refine` deduplication merges or archives the duplicates.
- What if `/frame` is run on a domain that already has distilled knowledge or seeded raw items?
  The command writes the identity file normally. If seeded raw items exist in the queue,
  `/frame` warns the user that their scope classifications may be stale and recommends a
  `/refine` pass. If distilled entries exist, `/frame` warns similarly that they were not
  reclassified against the new scope.
- What if a source directory contains unsupported file formats (`.docx`, `.xlsx`)? The
  command skips them, lists the skipped files in the session summary, and tells the user to
  export them to Markdown or PDF first.

---

## Clarifications

### Session 2026-03-06

- Q: What is the minimum segment size for a segment to become a raw item? → A: Complete-thought minimum — Claude assesses whether the segment contains at least one complete, standalone knowledge claim. No fixed word count. Segments that are only a heading or a single phrase are merged with the next segment or skipped.
- Q: What is the basis for classifying a segment as in-scope, out-of-scope, or ambiguous? → A: Semantic judgment — Claude evaluates the segment's topic against the identity's pitch and scope lists holistically, not by keyword matching. Term matching alone is insufficient.
- Q: Where does a seeded raw item's title come from? → A: Hybrid — use the nearest section heading as the title when one exists; infer a ≤10-word title from segment content when no heading is present.
- Q: What should /seed do when a session would produce more raw items than a practical limit? → A: Warn and cap at 100 raw items per run (default). Stop after the cap, report how many segments remain unprocessed, and invite the user to re-run.
- Q: When /frame updates the identity, what happens to seeded raw items already in the queue? → A: Warn only — /frame checks for existing raw items with source.tool: seed and, if any are found, tells the user their scope classifications may be stale under the new identity and recommends a /refine pass to review them. No automatic re-flagging.

---

## Requirements *(mandatory)*

### Functional Requirements

#### /frame command

- **FR-001**: The system MUST provide a `/frame` command that creates or updates
  `config/identity.md` in the domain brain root.
- **FR-002**: `config/identity.md` MUST contain: domain name, one-line description (≤15 words),
  pitch (3–5 sentences), in-scope list (≥1 item), out-of-scope list (≥1 item), steward name,
  and creation date.
- **FR-003**: The domain name MUST be auto-populated from the domain brain root directory name
  without prompting the user.
- **FR-004**: The steward name MUST be auto-populated from the git user name; if unavailable,
  the user is prompted once.
- **FR-005**: When re-running `/frame` on a domain with an existing `config/identity.md`, the
  command MUST present current field values and allow selective updates rather than restarting
  from scratch.
- **FR-005a**: After updating `config/identity.md`, if any raw items with `source.tool: seed`
  exist in the raw queue, `/frame` MUST warn the user that those items were classified under
  the previous identity and recommend running `/refine` to review them. No automatic
  re-flagging of existing raw items.
- **FR-006**: `config/identity.md` MUST be a human-readable Markdown file that users can edit
  directly without running any command.

#### /seed command

- **FR-007**: The system MUST provide a `/seed <source>` command where `<source>` is a local
  file path, a web URL, or a directory path.
- **FR-008**: `/seed` MUST stop immediately with a clear error if `config/identity.md` does
  not exist, directing the user to run `/frame` first.
- **FR-009**: The command MUST segment source content at logical boundaries: Markdown
  documents split at `##` headings (falling back to `###` or paragraph breaks for long
  sections); PDFs split at detected headings or page boundaries; web pages split by heading
  structure. A segment is only eligible to become a raw item if it contains at least one
  complete, standalone knowledge claim — segments that are only a heading, a single phrase,
  or boilerplate (e.g., table of contents, footer) are merged with the adjacent segment or
  discarded.
- **FR-010**: For directory sources, the command MUST process every Markdown and PDF file in
  the directory through the same segmentation and filtering pipeline.
- **FR-011**: For each segment, the command MUST classify relevance against the domain identity
  using semantic judgment — evaluating the segment's topic against the identity's pitch and
  scope lists holistically (not by keyword matching alone):
  - **Clearly in scope** (topic clearly aligns with the "In scope" list and pitch): create raw item, no flag
  - **Clearly out of scope** (topic clearly aligns with the "Out of scope" list): skip, log with reason
  - **Ambiguous** (neither clearly in nor out, or the identity scope lists are insufficient to judge): create raw item with `seed-note: Relevance uncertain` in YAML frontmatter
- **FR-012**: Every created raw item MUST have `source.tool: seed` and `source.location` set
  to the origin file path or URL.
- **FR-012a**: The title of each seeded raw item MUST be derived from the nearest section
  heading if one exists; if no heading is present, Claude MUST infer a ≤10-word title from
  the segment content. The title MUST NOT be left blank.
- **FR-013**: A single `/seed` session MUST NOT produce more than 100 raw items (default cap).
  When the cap is reached, the command MUST stop, report the count of unprocessed segments
  remaining, and prompt the user to re-run `/seed` to continue. The cap MAY be overridden by
  passing `--limit N` to the command.
- **FR-013a**: At session end, the command MUST output a summary reporting: items created
  (in-scope), items skipped (out-of-scope), items flagged (ambiguous), files or URLs that
  could not be read, and — if the cap was reached — the number of unprocessed segments
  remaining.
- **FR-014**: Unsupported file formats (e.g., `.docx`, `.xlsx`) MUST be skipped with a log
  entry instructing the user to export to Markdown or PDF.
- **FR-015**: Inaccessible URLs MUST be logged in the session summary rather than stopping
  the whole seed session.

#### /refine enhancements

- **FR-016**: The refine subagent MUST read `config/identity.md` (if it exists) as part of
  its context to inform scope judgements.
- **FR-017**: When a raw item's content clearly matches a term on the "Out of scope" list
  in `config/identity.md` with high confidence, the refine subagent MUST classify it as an
  `out_of_scope` autonomous action and archive it without a governed decision.
- **FR-018**: The `out_of_scope` autonomous action MUST be recorded in the session changelog,
  including the item id, the matched out-of-scope term, and the archive outcome.
- **FR-019**: When a raw item has `seed-note: Relevance uncertain` in its frontmatter, the
  refine subagent MUST present it as a governed decision that includes both type options and
  a "not relevant — archive" option.

#### /query enhancements

- **FR-020**: `/query` MUST read `config/identity.md` as the first context element (before
  any distilled files) if the file exists.
- **FR-021**: When `config/identity.md` exists, every query response MUST include a one-line
  domain framing statement derived from the identity's one-line description.
- **FR-022**: When `config/identity.md` does not exist, `/query` MUST proceed normally
  without error and without a framing statement.

### Technical Constraints

- **Delivery mechanism**: Claude command files (`.claude/commands/*.md`) — no standalone app,
  no external services, no compilation step.
- **Command surface**: `/frame` (new), `/seed` (new); `/refine`, `/query` (enhanced).
- **Storage format**: All outputs are Markdown files with YAML frontmatter in the
  version-controlled domain brain directory.
- **Supported source types**: Local Markdown files, local PDFs, public web URLs. Authenticated
  enterprise APIs (Confluence REST, Notion API, SharePoint) are deferred to a future release.
- **Host AI**: Claude Code via Claude command files; built-in tools only (Read, Write, Edit,
  Glob, Grep, Bash for git).

### Key Entities

- **Domain Identity**: A structured document (`config/identity.md`) capturing the domain's
  name, headline description, pitch, explicit scope lists, steward, and creation date.
  Consulted by `/seed`, `/refine`, and `/query`.

- **Seeded Raw Item**: A standard raw item produced by `/seed`, identical in format to a
  manually captured item, with `source.tool: seed`, `source.location` set to the origin, and
  optionally `seed-note: Relevance uncertain` for items requiring relevance confirmation.

- **Seed Session**: A single `/seed` invocation against one or more sources. Produces an
  end-of-session summary (counts of created, skipped, flagged items). Not persisted to a file.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A domain steward can produce a complete `config/identity.md` for a new domain
  in under 3 minutes using `/frame`.
- **SC-002**: Running `/seed` against a 50-page source document produces categorised raw items
  in under 2 minutes, with no manual segmentation required. Sessions producing more than 100
  raw items stop cleanly at the cap and report remaining segments.
- **SC-003**: At least 75% of seeded segments are correctly classified as in-scope,
  out-of-scope, or uncertain relative to a human reviewer's independent classification of the
  same document against the same identity.
- **SC-004**: After a seed-and-refine cycle, zero out-of-scope items (per identity.md) appear
  in any distilled file.
- **SC-005**: Every `/query` response for a domain with a complete identity includes a domain
  framing statement that a new team member could use to orient themselves without prior
  knowledge of the domain.
- **SC-006**: A domain steward can onboard an existing knowledge base of 5 documents (mixed
  types, ~200 pages total) into the raw queue using only `/frame` and `/seed`, without writing
  a single raw item manually.

---

## Assumptions

1. Users are expected to run `/frame` before running `/seed` or `/capture` for the first
   time. The quickstart guide will be updated to reflect this as the recommended first step.
2. Web URLs are publicly accessible without authentication. Authenticated sources require
   manual export to a local file in this release.
3. The relevance filter uses Claude's language understanding to match segment content against
   the identity scope lists — no external classifier or embedding model is required.
4. A single `config/identity.md` per domain brain instance covers all v1 needs; multiple
   stewards and delegated ownership are deferred.
5. Re-seeding the same source after a prior refine cycle is a valid workflow; `/refine`
   deduplication handles the resulting duplicate raw items.
6. The `seed-note` frontmatter field is a new convention introduced by this feature and
   understood by the enhanced `/refine` subagent.

---

## Out of Scope

- Authenticated enterprise API integration (Confluence REST, Notion API, Jira, SharePoint)
- Automated or scheduled seeding without manual invocation
- Cross-domain seeding (importing content tagged for a different domain brain instance)
- Versioning or diffing of `config/identity.md` beyond what git provides natively
- Multiple identity documents or sub-domain framing within a single domain brain instance
