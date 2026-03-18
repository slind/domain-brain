# Feature Specification: Explicit Subagents — Move to Separate Files

**Feature Branch**: `001-explicit-subagents`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "Make subagents explicit — move to separate files — so that they are easier to maintain by hand. This reduces the risk of accidental regressions when editing the refine command and improves the overall maintainability of the refinement pipeline."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Edit Subagent Instructions Without Touching the Refine Command (Priority: P1)

A maintainer wants to tune the subagent's classification rules or update the output format contract without having to navigate the full 700-line refine command. With subagent instructions extracted to their own file, they can open, edit, and review just the subagent content — no risk of inadvertently modifying the host command's step logic.

**Why this priority**: This is the primary motivation for the feature. Today the entire refine pipeline is a single monolithic file; any edit requires the maintainer to navigate the full file, increasing the risk of accidental side-effects. Separating subagent instructions is the direct fix.

**Independent Test**: Can be tested by updating the subagent's output format rules in the dedicated file and running `/refine` to confirm the updated instructions are used — without ever opening `refine.md`.

**Acceptance Scenarios**:

1. **Given** the subagent instructions are in a separate file, **When** a maintainer edits only that file to add a new autonomous action type, **Then** the next `/refine` session uses the updated instructions with no changes to the host command file.
2. **Given** the subagent instructions are in a separate file, **When** a maintainer opens `refine.md` to adjust the step 6.5 pre-filtering logic, **Then** the subagent instructions file is not opened or modified.

---

### User Story 2 - Subagent Files Are Discoverable and Self-Describing (Priority: P2)

A maintainer new to the codebase wants to understand which subagents the refine pipeline uses and what each one does. The separate subagent files should be named and located so that their purpose is immediately clear without requiring the maintainer to read the full host command.

**Why this priority**: Discoverability compounds the value of separation. A file named `refine-subagent.md` in a predictable location communicates its purpose at a glance; a buried section heading inside a 700-line file does not.

**Independent Test**: Can be tested by listing the command files directory and confirming subagent files appear with names that describe their role in the pipeline.

**Acceptance Scenarios**:

1. **Given** the refine pipeline is in place, **When** a maintainer lists the command files, **Then** the subagent file(s) are visible and their names describe their role (e.g., `refine-subagent.md`).
2. **Given** a subagent file exists, **When** a maintainer reads it, **Then** its header or opening paragraph identifies which command invokes it and what its output contract is.

---

### User Story 3 - Host Command References Subagent File, Not Inline Block (Priority: P3)

When `/refine` invokes a specialist subagent via the Agent tool, it loads the subagent's instructions from the dedicated file rather than embedding them inline. This keeps the host command lean and ensures a single source of truth for subagent behaviour.

**Why this priority**: This is the structural change that enables P1 and P2, and it is the most technically specific story — it depends on the Agent tool's instruction-passing mechanism and needs to be verified.

**Independent Test**: Can be tested by inspecting `refine.md` after the change and confirming that no `### SUBAGENT INSTRUCTIONS — REFINE AGENT` inline block is present; instead the host command loads and passes the file contents at invocation time.

**Acceptance Scenarios**:

1. **Given** the refine command has been updated, **When** a maintainer reads `refine.md`, **Then** no inline subagent instructions section is present.
2. **Given** the refine command invokes a subagent, **When** the session runs, **Then** the subagent receives the same instructions it received when they were inline — behaviour is unchanged.
3. **Given** the subagent file is missing or unreadable at session start, **When** `/refine` is invoked, **Then** the command surfaces an error identifying the missing file before attempting any processing.

---

### Edge Cases

- What happens if the subagent file is accidentally deleted? The host command must detect the missing file at start-up and report an actionable error rather than invoking the Agent tool with empty instructions.
- What if a maintainer edits both the host command and the subagent file in the same change? Changes to each file are independent; no coupling or merge logic is required.
- What if multiple specialist subagent types are introduced in a future feature? The file structure should accommodate additional subagent files without requiring changes to the naming convention.
- What if the subagent instructions contain context injected by the host (e.g., `priority_guidelines`)? The separation must preserve the host's responsibility for assembling the full Agent tool invocation payload; the subagent file contains only the static instruction text.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block currently embedded in `refine.md` MUST be extracted to one or more dedicated subagent instruction files.
- **FR-002**: Each subagent instruction file MUST be stored in `.claude/agents/` — a dedicated directory separate from host commands in `.claude/commands/`.
- **FR-003**: The `/refine` host command MUST load the subagent instruction file(s) at session start and use their contents when invoking the Agent tool — no inline instruction text remains in `refine.md`.
- **FR-004**: If a required subagent instruction file is absent or unreadable, the host command MUST stop and output an error message that identifies the missing file by path before any processing begins.
- **FR-005**: The `/refine` command's observable behaviour — types processed, output format, governed decision flow, changelog entries — MUST be identical before and after this change.
- **FR-006**: Each subagent instruction file MUST open with a plain Markdown prose header (no YAML frontmatter) identifying: the command that invokes it, the types of items it processes, and the output contract it must satisfy.

### Technical Constraints

- **Delivery mechanism**: Claude command file modification — no new programming language or runtime required.
- **Command surface**: `/refine` is the only command affected; no new commands or skills are exposed.
- **Storage format**: Markdown files; host commands in `.claude/commands/`, subagent instruction files in `.claude/agents/`.
- **Host AI**: Claude (claude-sonnet-4-6+); the Agent tool is used to invoke subagents and is the mechanism for passing instruction content.

### Key Entities

- **Host command** (`refine.md`): Orchestrates the full refine pipeline — loads context, pre-filters, routes, invokes subagents, executes plans, writes files. After this change it references subagent files rather than embedding their content.
- **Subagent instruction file** (e.g., `.claude/agents/refine-subagent.md`): Contains the static instruction text for the refine subagent — output format contract, action types, governed decision triggers, and ADR format. Stored in `.claude/agents/`. Read by the host at session start and passed to the Agent tool as part of the invocation payload.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After the change, `refine.md` contains no inline subagent instructions section — a search of the file for the `SUBAGENT INSTRUCTIONS` heading returns no matches.
- **SC-002**: A `/refine` session run against a representative batch produces the same autonomous actions, governed decision prompts, and changelog output as the pre-change baseline — zero behavioural regressions.
- **SC-003**: All subagent instruction files are locatable by listing `.claude/agents/` — a maintainer can find every subagent file without reading `refine.md`.
- **SC-004**: Editing the subagent instruction file and running `/refine` uses the updated instructions without any modification to `refine.md`.

## Assumptions

- The Claude Agent tool supports passing instruction content loaded from a file at invocation time; no platform constraint prevents this.
- The single `### SUBAGENT INSTRUCTIONS — REFINE AGENT` block is the complete set of inline subagent instructions to extract; no other embedded subagent blocks exist in the current `refine.md`.
- Specialist cluster routing (requirements, interfaces, decisions, codebase, responsibility) all use the same shared instruction block — a single subagent file is sufficient for this feature. Splitting by specialist type is out of scope.
- No other command files currently embed subagent instructions that need to be extracted as part of this feature.

## Clarifications

### Session 2026-03-17

- Q: Where should subagent files be stored? → A: `.claude/agents/` to maintain conventions
- Q: What format should the subagent file header take? → A: Plain Markdown prose header (no YAML frontmatter)

## Scope Boundary Decisions

- **In scope**: Extracting the refine subagent instructions to a separate file; updating `refine.md` to load and reference it.
- **Out of scope**: Creating separate instruction files per specialist type (future feature); extracting instruction blocks from commands other than `/refine`; changing the content of the subagent instructions beyond what is necessary for the extraction.
