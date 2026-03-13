# Feature Specification: Backlog Lifecycle Support

**Feature Branch**: `004-backlog-lifecycle`
**Created**: 2026-03-12
**Status**: Draft
**Input**: Backlog lifecycle support for Domain Brain — a /triage command with priority management (direct assignment, hint-driven AI re-ranking, and persistent guidelines file), status tracking (open/in-progress/done), a task-management query mode in /query, and speckit handoff for starting work on items.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — View and Prioritise the Backlog (Priority: P1)

A domain steward invokes `/triage` and immediately sees the full backlog organised by priority and status. They can directly set the priority of any item in a single interaction. This is the foundational view-and-control operation — everything else builds on it.

**Why this priority**: A backlog with no visible priority ordering and no way to change it offers no more value than a plain list. This story delivers the minimum: "I know what's there and what order to work in."

**Independent Test**: Invoke `/triage` with a populated `backlog.md` containing items of mixed priorities. Verify the display groups items correctly and that "set item 3 to high" immediately changes the priority field on that entry.

**Acceptance Scenarios**:

1. **Given** a backlog with open items of mixed priority, **When** a user invokes `/triage`, **Then** items are displayed grouped as: in-progress first, then high / medium / low, with item numbers for reference.
2. **Given** the backlog is displayed, **When** the user says "set 4 to high", **Then** item 4's priority is updated to `high` immediately, with no further confirmation required.
3. **Given** the backlog is displayed, **When** the user says "show done", **Then** the Done section is listed.
4. **Given** an empty backlog, **When** a user invokes `/triage`, **Then** a friendly message is shown ("Backlog is empty — capture some items first with /capture") with no error.

---

### User Story 2 — AI-Assisted Reprioritisation (Priority: P2)

A domain steward gives a natural language hint ("focus on enterprise integration" or "prioritise anything closely related to task 5") and receives a proposed priority re-ranking from the system. The proposed changes are presented as a table before any modification is made. The user confirms or rejects before anything is written.

**Why this priority**: Manual individual-item priority changes (US1) require the user to evaluate every item themselves. This story adds leverage: one strategic hint repositions the relevant items automatically. The "confirm before apply" gate keeps the user in control.

**Independent Test**: Invoke `/triage`, give the hint "elevate anything related to the query system". Verify the system proposes priority changes for matching items and does not apply them until the user confirms.

**Acceptance Scenarios**:

1. **Given** a populated backlog, **When** the user says "elevate enterprise integration stuff", **Then** the system proposes priority changes for relevant items as a readable table (showing item, current priority, proposed priority) and waits for confirmation.
2. **Given** the proposed changes are displayed, **When** the user says "yes" or "apply", **Then** all proposed changes are written to `backlog.md` in a single operation.
3. **Given** the proposed changes are displayed, **When** the user says "no" or "cancel", **Then** no changes are made and the backlog is unchanged.
4. **Given** a hint that matches no items, **When** the system evaluates it, **Then** the system says no items matched the hint and asks if the user wants to rephrase.
5. **Given** the user says "reprioritise everything" or "apply guidelines", **When** a priority guidelines document exists, **Then** the system proposes a full re-ranking based on the guidelines before applying.

---

### User Story 3 — Start Work on an Item (Priority: P2)

A domain steward picks a backlog item to work on. The system marks it `in-progress`, then offers to automatically hand off into the feature spec workflow with the item's description pre-loaded. One confirmation fires the handoff.

**Why this priority**: The whole purpose of prioritising the backlog is to know what to work on next. This story closes the loop between "deciding what's next" and "actually starting". Without a clean handoff to the spec workflow, the backlog is still disconnected from development.

**Independent Test**: Invoke `/triage` with open items. Say "start 3". Verify item 3 is marked `in-progress`, the system shows what will be passed to the spec workflow, and after confirmation the spec workflow launches with the item body pre-populated.

**Acceptance Scenarios**:

1. **Given** an open item at position 3, **When** the user says "start 3", **Then** the system shows the item's title and description, marks it `in-progress`, and asks "Ready to start speccing?".
2. **Given** the confirmation prompt is shown, **When** the user says "yes", **Then** the spec workflow is automatically launched with the item's description pre-loaded as the feature input.
3. **Given** an item that is already `in-progress`, **When** the user says "start N" for that item, **Then** the system notes it is already in progress and asks if the user wants to continue speccing it anyway.
4. **Given** the confirmation prompt is shown, **When** the user says "not yet", **Then** the item remains `in-progress` but the spec workflow is not launched.

---

### User Story 4 — Close or Drop a Completed Item (Priority: P3)

A domain steward closes a finished item or removes a cancelled one. The system requires a brief rationale before making the change, then records the closure in the audit log. Done items remain visible in a dedicated section rather than disappearing entirely.

**Why this priority**: Closing items is important for hygiene but does not block any other workflow. The audit trail requirement means closures must be deliberate, not silent.

**Independent Test**: Invoke `/triage`, say "close 2". Verify the system asks for a rationale, then marks item 2 as `done`, moves it to the Done section, and appends a changelog entry. Verify "drop 2" triggers a governed decision with multiple options.

**Acceptance Scenarios**:

1. **Given** an open item at position 2, **When** the user says "close 2", **Then** the system asks for a one-line rationale before making any change.
2. **Given** the rationale is provided, **Then** item 2 is marked `done`, moved to the Done section in `backlog.md`, and a changelog entry is appended recording the item id, title, and rationale.
3. **Given** an open item, **When** the user says "drop 2" or "remove 2", **Then** a governed decision is presented with at least two options (e.g., mark as done with "dropped" reason, or de-prioritise to low and keep open) plus "flag as unresolved".
4. **Given** option "mark as done — dropped" is chosen, **Then** the item is moved to Done with reason recorded, same as a regular close.

---

### User Story 5 — Maintain Priority Guidelines (Priority: P3)

A domain steward creates or updates a persistent priority guidelines document that describes what kinds of items should be elevated, kept at medium, or deferred to low. When new items arrive via the refine pipeline, the system automatically assigns their initial priority based on these guidelines. The steward can also trigger a bulk re-ranking of the existing backlog against updated guidelines.

**Why this priority**: Guidelines close the automation loop — without them, every new item defaults to `medium` and requires manual attention. With them, strategic decisions are encoded once and applied automatically. This is high-leverage but not blocking (the system works with manual priority in the meantime).

**Independent Test**: Create a guidelines document saying "scale-related items → high". Capture and refine a new task about "scaling the hosted index". Verify it arrives in `backlog.md` with `**Priority**: high` already set.

**Acceptance Scenarios**:

1. **Given** no guidelines document exists, **When** the user says "update guidelines" in `/triage`, **Then** the system presents a template and collects the user's rules in a single exchange, then writes `config/priorities.md`.
2. **Given** a guidelines document exists, **When** the user says "update guidelines", **Then** the system shows the current content and allows selective updates.
3. **Given** a guidelines document exists, **When** a new task item is processed by `/refine`, **Then** the resulting backlog entry's `**Priority**` field is set according to the guidelines (not always `medium`).
4. **Given** no guidelines document exists, **When** a new task item is processed by `/refine`, **Then** the resulting backlog entry defaults to `**Priority**: medium`.
5. **Given** guidelines are updated, **When** the user says "apply guidelines" in `/triage`, **Then** the system proposes re-rankings for all open items against the new guidelines and waits for confirmation before applying.

---

### User Story 6 — Query Backlog via Natural Language (Priority: P3)

Anyone can ask natural language questions about the backlog state ("what's on the backlog?", "what should we work on next?", "what's in progress?") via `/query` and receive a grounded, prioritised answer without needing to invoke `/triage`.

**Why this priority**: `/query` is the read-only window into all domain knowledge. Making the backlog queryable means team members who just want to understand status don't need to know about `/triage`.

**Independent Test**: Invoke `/query "what should we work on next?"`. Verify the response lists high-priority open items first, is grouped by priority, and cites `backlog.md` as the source.

**Acceptance Scenarios**:

1. **Given** a populated backlog, **When** the user asks "what's on the backlog?", **Then** `/query` classifies this as `task-management` mode and returns open items grouped by priority.
2. **Given** an item is in-progress, **When** the user asks "what are we working on?", **Then** the in-progress item is highlighted in the response.
3. **Given** the user asks "what's done?", **Then** `/query` returns the Done section from `backlog.md`.

---

### Edge Cases

- **Empty backlog**: `/triage` shows a helpful message rather than an error or blank output.
- **All items in-progress or done**: `/triage` reports "no open items" and shows the in-progress / done sections.
- **Hint matches no items**: System reports no matches and offers to rephrase rather than silently applying no changes.
- **Guidelines file missing**: `/refine` defaults new items to `medium`; `/triage` hint-driven reprioritisation works without guidelines by asking the user to describe their intent more specifically.
- **User starts an already-in-progress item**: System notes the item is already in-progress and asks whether to re-launch the spec workflow.
- **User provides no rationale on close**: System asks once. If still no rationale, defaults to "no rationale provided" and proceeds — does not block the close.
- **Conflict between hint and explicit priority**: If a user previously set an item to `high` manually, a hint-driven proposal to lower it is clearly flagged as "overriding a manual assignment" in the proposal table.

---

## Requirements *(mandatory)*

### Functional Requirements

#### /triage command

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

#### Priority guidelines

- **FR-012**: System MUST support a persistent priority guidelines document (`config/priorities.md`) describing what types of items should be elevated, kept at medium, or deferred to low.
- **FR-013**: `/triage` MUST provide a guided single-exchange interaction for creating or updating the guidelines document.
- **FR-014**: When guidelines are updated, `/triage` MUST offer to re-rank the existing open backlog against the new guidelines (with confirmation gate before applying).

#### /refine integration

- **FR-015**: When `/refine` routes a new task item to `backlog.md`, the resulting entry MUST include `**Status**: open` and `**Priority**: <value>`.
- **FR-016**: If `config/priorities.md` exists, `/refine` MUST use a subagent to evaluate the new item against the guidelines and assign an appropriate priority. If the file does not exist, priority defaults to `medium`.

#### /query integration

- **FR-017**: `/query` MUST support a `task-management` reasoning mode triggered by questions about backlog state ("what's open", "what's in progress", "what should we work on", "what's done").
- **FR-018**: The `task-management` mode MUST return items grouped by priority (high → medium → low) with in-progress items highlighted.
- **FR-019**: The `task-management` mode MUST load only `backlog.md` (no other distilled files).

#### Schema

- **FR-020**: Every backlog entry MUST carry a `**Status**` field with values `open`, `in-progress`, or `done`.
- **FR-021**: Every backlog entry MUST carry a `**Priority**` field with values `high`, `medium`, or `low`.
- **FR-022**: All 12 existing backlog entries MUST be backfilled with `**Status**: open` and `**Priority**: medium` as the initial migration.

### Technical Constraints

- **Delivery mechanism**: Claude command file (`.claude/commands/triage.md`) — no standalone application, no external services.
- **Command surface**: `/triage` (new), `/query` (extended with `task-management` mode), `/refine` (extended with priority assignment and updated entry format).
- **Storage format**: Markdown with YAML frontmatter in version-controlled repository; all files human-readable and directly editable.
- **Host AI**: Claude (claude-sonnet-4-6+); priority subagent is an Agent tool invocation orchestrated by the `/triage` host.
- **No new dependencies**: Only built-in tools (Read, Write, Edit, Glob, Grep) and the Agent tool.

### Key Entities

- **Backlog Entry**: A task-typed knowledge item with `Status` (`open` | `in-progress` | `done`) and `Priority` (`high` | `medium` | `low`) fields, stored in `distilled/backlog.md`. The Done section is a structural divider within the same file.
- **Priority Guidelines**: A persistent steward-maintained document (`config/priorities.md`) encoding strategic focus as human-readable rules. Read by the priority subagent and by `/refine` when processing new task items.
- **Triage Session**: A single conversational `/triage` invocation. May span multiple user turns (view → confirm priority change → close item). Each session that closes or drops items appends to the changelog.

### Assumptions

1. `distilled/backlog.md` already exists (created by the existing `/refine` pipeline).
2. The feature spec workflow (speckit) is already installed and accessible; `/triage` treats it as an available handoff target.
3. Priority inference at `/refine` time uses the same AI-judgment approach as scope classification — heuristic, not keyword matching.
4. "Drop" (cancel without completion) is treated as a governed decision because it is potentially irreversible and audit-worthy. "Close" (completed) requires only a rationale.
5. The `## Done` section is a conventional divider in `backlog.md` — not a separate file. This keeps the backlog as one human-readable document.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can view the full prioritised backlog and make at least one priority change in under 2 minutes from invoking `/triage`.
- **SC-002**: 100% of priority changes proposed by AI (hint-driven or guidelines-driven) require explicit user confirmation before being written — zero silent modifications.
- **SC-003**: A user can go from "start item N" to an active feature spec session in a single `/triage` interaction, with zero manual copy-paste of the item description.
- **SC-004**: 100% of close and drop actions produce a changelog entry — zero silent removals from the active backlog.
- **SC-005**: When a priority guidelines document exists, 100% of new task items processed by `/refine` arrive in `backlog.md` with a priority field set by the guidelines (not always defaulting to `medium`).
- **SC-006**: A user can update priority guidelines and see a proposed full re-ranking of the existing backlog within the same `/triage` session.
- **SC-007**: All common backlog status queries ("what's open?", "what's in progress?", "what should we work on?") return a cited answer via `/query` without invoking `/triage`.
