<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0 (initial ratification)

Added principles:
  I.   Extension-First
  II.  Eager Junior Architect Persona
  III. Human Authority Over Normative Content
  IV.  Knowledge as Code
  V.   Minimal Friction Capture

Added sections:
  - Core Principles (I–V)
  - Delivery Constraints
  - Governance

Templates updated:
  ✅ .specify/templates/plan-template.md  — Constitution Check gates populated
  ✅ .specify/templates/spec-template.md  — Technical Constraints section added
  ⚠  .specify/templates/tasks-template.md — no changes required; structure already compatible

Deferred items:
  - Multi-assistant support (beyond Claude) deferred to future iteration; noted in Delivery Constraints.
-->

# Domain Brain Constitution

## Core Principles

### I. Extension-First

Domain Brain should be considered an extension to an existing AI assistant. The system should predominantly exposes its
capabilities as commands (e.g., `/capture`, `/refine`, `/query`), skills, and subagents —
following the same extension pattern as tools like speckit that augment an AI assistant's
behaviour. No standalone UI, no separate application binary. The AI assistant IS the
interface.

- Every user-facing capability MUST be reachable via a command or skill invocation.
- Subagents handle bounded, delegatable work (e.g., the refine agent); the host AI
  orchestrates them.
- Implementation artefacts are Claude command files, skill definitions, and agent prompts —
  not server processes or web apps.

### II. Eager Junior Architect Persona

The system tries to mimick an eager, proactive junior architect: take initiative on all
routine and high-confidence tasks without waiting to be asked; generate structure
automatically so the human never hand-authors envelopes or schema; never ask unnecessary
clarifying questions. At the same time, it MUST defer to the human for all normative
decisions — it knows the limits of its own authority.

- Proactive: the system acts, it does not wait for instructions on things it can determine
  itself.
- Opinionated on process, never on content: it decides *how* to structure and route
  knowledge, not *what* the knowledge means.
- Deferential on authority: when a decision has normative consequences, it presents options
  and waits — it never commits normative content unilaterally.

### III. Human Authority Over Normative Content

Normative change to distilled knowledge MUST require explicit human approval before it
is committed. Normative changes include: asserting new team responsibilities, resolving
conflicting captures, creating ADRs, promoting tasks to requirements, and deprecating
existing entries.

- Autonomous processing is permitted only when confidence is demonstrably high AND the
  action is non-normative (deduplication, archiving, type routing, summarisation).
- Every normative decision MUST be recorded in the changelog with the human's rationale.
- The system MUST present governed decisions one at a time and MUST always offer
  "flag as unresolved" as a valid option.

### IV. Knowledge as Code

All knowledge MUST persist as human-readable, diffable files in a version-controlled
repository. File format: Markdown with YAML frontmatter (structured envelope in
frontmatter, free-form body in Markdown). No opaque databases, no proprietary binary
formats, no AI-provider lock-in for storage.

- Knowledge files MUST be readable and editable by a human without running any tool.
- The version-controlled repository is the single source of truth; no shadow state in
  external services.
- File splits, renames, and structural changes are governed actions requiring human
  confirmation.

## Governance

Individual feature specifications can overrule these principles, but when doing so should provide:

1. A documented rationale for the change.
2. A version bump per semantic versioning rules (MAJOR: principle removal/redefinition;
   MINOR: new principle or section added; PATCH: clarifications and wording).
3. Propagation to all dependent templates: `plan-template.md`, `spec-template.md`,
   `tasks-template.md`.
4. Review of open specs and plans for alignment with amended principles.

All implementation plans MUST include a Constitution Check gate (Principles I–V) that
passes before Phase 0 research proceeds and is re-checked after Phase 1 design.

**Version**: 1.0.0 | **Ratified**: 2026-03-05 | **Last Amended**: 2026-03-05
