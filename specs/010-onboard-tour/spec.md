# Feature Specification: Domain README — Consolidate Command

**Feature Branch**: `010-onboard-tour`
**Created**: 2026-03-18
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Steward Generates Domain README (Priority: P1)

The steward runs `/consolidate` for the first time in a domain brain project. A human-readable `domain/README.md` is created, containing: the domain's one-liner and pitch, the interfaces the domain exposes, a brief guide to using the domain brain, and the current top open priorities from the backlog. Stakeholders and new contributors can now read a single document to understand the domain — no AI interaction required.

**Why this priority**: Without this, the domain brain's distilled knowledge is only accessible through AI queries. This feature makes the knowledge base legible to anyone with access to the repository.

**Independent Test**: Can be fully tested by running `/consolidate` in a populated domain brain and verifying the README file exists and contains all four content sections.

**Acceptance Scenarios**:

1. **Given** `domain/README.md` does not exist, **When** the steward runs `/consolidate`, **Then** the file is created with four labelled sections: Domain Summary, Exposed Interfaces, Intended Usage, and Top Priorities.
2. **Given** `config/identity.md` exists with a domain name, one-liner, and pitch, **When** `/consolidate` runs, **Then** the Domain Summary section reflects the current identity file content verbatim (no paraphrasing).
3. **Given** a changelog entry for the consolidate run is expected, **When** `/consolidate` completes, **Then** an entry is appended to `distilled/changelog.md` recording the date and a summary of the sections written.

---

### User Story 2 — New Team Member Reads the README (Priority: P2)

A new developer joins the team, clones the repository, and opens `domain/README.md` in their git browser (GitHub, GitLab, etc.). Without running any command or interacting with the AI, they can read the domain's purpose, see which interfaces exist, understand how to query the domain brain, and identify what the team is currently working on.

**Why this priority**: Achieves the original intent of the onboarding feature (SC-008 equivalent) but through a static, always-available document rather than a live command.

**Independent Test**: Can be fully tested by reading the generated README in a standard Markdown renderer without any AI tooling present.

**Acceptance Scenarios**:

1. **Given** a generated `domain/README.md`, **When** a reader opens it in a git browser, **Then** all content is readable as standard Markdown — no raw YAML, no tool output, no broken formatting.
2. **Given** the domain has open high-priority backlog items, **When** a reader reads the Top Priorities section, **Then** they see item titles and a one-line description for each, ordered high → medium priority.
3. **Given** the domain has active interface contracts, **When** a reader reads the Exposed Interfaces section, **Then** they see each interface contract title listed — enough to know what the domain exposes without needing to open `interfaces.md`.

---

### User Story 3 — README Stays Current After Domain Changes (Priority: P3)

After the team closes several backlog items and adds a new interface contract, the steward runs `/consolidate` again. The existing `domain/README.md` is updated — new priorities surface, the new interface appears, and outdated content is replaced. The README reflects the domain's current state as of the consolidate run.

**Why this priority**: A stale README is worse than no README. Ensuring `/consolidate` overwrites rather than appends is essential for the document's trust.

**Independent Test**: Can be fully tested by verifying that after a second `/consolidate` run following a change to the backlog or interfaces, the README reflects the change — with no duplication of the previous content.

**Acceptance Scenarios**:

1. **Given** `domain/README.md` already exists, **When** the steward runs `/consolidate`, **Then** the existing file is fully overwritten (not appended to) with fresh content.
2. **Given** a backlog item was closed between two consolidate runs, **When** `/consolidate` runs again, **Then** the closed item does not appear in the Top Priorities section.
3. **Given** a new interface contract was added since the last consolidate run, **When** `/consolidate` runs again, **Then** the new interface appears in the Exposed Interfaces section.

---

### Edge Cases

- What happens when `config/identity.md` does not exist? → `/consolidate` MUST error with a message directing the steward to run `/frame` first. The README is not created or modified.
- What happens when `distilled/interfaces.md` does not exist? → The Exposed Interfaces section displays "No interfaces defined yet." The command does not error.
- What happens when `distilled/backlog.md` has no open items? → The Top Priorities section displays "No open items." The command does not error.
- What if the backlog has only low-priority items (no high or medium)? → Include the top 5 open items regardless of priority level, with their priority shown.
- What if there are more than 5 high-priority items? → Show the top 5 by priority tier (high first, then medium), and append "… and N more open items — run /query for the full list."
- What if `distilled/changelog.md` does not exist? → `/consolidate` creates it before appending the session entry.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `/consolidate` MUST create `domain/README.md` if it does not exist.
- **FR-002**: `/consolidate` MUST fully overwrite `domain/README.md` if it already exists — never append to the previous content.
- **FR-003**: The README MUST include a **Domain Summary** section containing the domain one-liner, pitch, and steward name sourced from `config/identity.md`.
- **FR-004**: The README MUST include an **Exposed Interfaces** section listing all interface contract titles from `distilled/interfaces.md`. If the file does not exist or has no entries, the section MUST display "No interfaces defined yet."
- **FR-005**: The README MUST include an **Intended Usage** section that describes the primary commands available (`/capture`, `/seed`, `/refine`, `/query`) and when to use each — as static prose, not sourced from a file.
- **FR-006**: The README MUST include a **Top Priorities** section listing up to 5 open backlog items from `distilled/backlog.md`, ordered by priority (high first, then medium, then low). Each item MUST show its title and a one-line description. If there are no open items, the section MUST display "No open items."
- **FR-007**: The README MUST be valid, human-readable Markdown renderable in standard git hosting interfaces (e.g., GitHub, GitLab) without any preprocessing.
- **FR-008**: `/consolidate` MUST append an entry to `distilled/changelog.md` at the end of each run, recording the date, the sections written, and a note of the item counts (e.g., "3 interfaces, 5 priorities").
- **FR-009**: If `config/identity.md` does not exist, `/consolidate` MUST stop with a clear error message — "Domain identity not found. Run /frame first." — and MUST NOT create or modify `domain/README.md`.
- **FR-010**: The README output MUST include a footer line indicating when it was last generated (e.g., "Generated: 2026-03-18 by /consolidate").

### Technical Constraints

- **Delivery mechanism**: Claude command file (`.claude/commands/consolidate.md`) — no standalone application, no external services.
- **Command surface**: `/consolidate` (new command); no modifications to existing commands.
- **Output file**: `domain/README.md` — a standard Markdown file in the domain root directory.
- **Host AI**: Claude (claude-sonnet-4-6+); no dependencies beyond built-in Read, Write, Glob tools.
- **Context loading**: Reads only `config/identity.md`, `distilled/interfaces.md`, `distilled/backlog.md`. MUST NOT load changelog, raw items, decisions, or requirements files.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A person who has never interacted with the domain brain can correctly identify the domain's purpose, at least one exposed interface, and the team's current top priority by reading `domain/README.md` alone — zero AI interaction required.
- **SC-002**: `/consolidate` completes and produces a complete, valid README in a single invocation with no follow-up prompts.
- **SC-003**: After running `/consolidate` a second time following any change to backlog or interfaces, the README accurately reflects the current state — zero stale content.
- **SC-004**: The generated README renders without broken formatting in at least two standard git hosting interfaces (GitHub-style Markdown).
- **SC-005**: The Top Priorities section always reflects the current open backlog state — no closed or dropped items appear after a consolidate run.

## Assumptions

- The output file path is always `domain/README.md` (relative to the domain brain root, not the repository root). This places the README alongside the domain's other configuration and distilled files.
- The Intended Usage section is static prose describing the four primary commands; it does not vary by domain and does not require reading from any file.
- `/consolidate` is invoked manually by the steward — there is no automatic trigger from other commands (e.g., closing a backlog item does not auto-run consolidate). Automation is deferred.
- The "top 5 priorities" cap is fixed (not configurable in v1). A future iteration may add a `--top N` flag.
- Interface contracts are listed by title only in the README — no body content is included. Full contracts remain in `distilled/interfaces.md`.
- The command does not validate the content of `config/identity.md` beyond confirming the file exists.
