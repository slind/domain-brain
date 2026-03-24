---
type: prd
issue: 2
---

## Problem Statement

Domain Brain has an implicit hard dependency on Speckit — a separate feature-planning framework — embedded in its commands, configuration, and distilled knowledge base. This dependency is undesirable because:

- Nine `speckit.*` command files live inside the Domain Brain repository but belong to the Speckit framework, creating confusion about what is part of Domain Brain and what is not.
- The `/triage` "start N" workflow automatically hands off to `/speckit.specify`, meaning that starting work on a backlog item requires Speckit to be installed. If Speckit is absent, the handoff silently fails.
- The `.specify/` directory (templates, scripts, `memory/constitution.md`) is Speckit infrastructure that has no role in Domain Brain's knowledge-management pipeline.
- References to Speckit in `decisions.md`, `config/priorities.md`, and `distilled/backlog.md` cause readers to treat Speckit as a normative part of Domain Brain's design, which it is not.

The result is a blurred boundary between two separate systems, a broken user experience when Speckit is not present, and dead infrastructure that accumulates in the repository.

## Solution

Remove all Speckit command files and infrastructure from the Domain Brain repository. Update the `/triage` "start N" workflow to display a concise work-item summary the user can carry into any planning workflow of their choice, instead of auto-firing a Speckit command. Clean up all normative references to Speckit in the distilled knowledge base and configuration files.

After this change, Domain Brain has zero runtime coupling to Speckit. Historical specification files under `specs/` are frozen documentation and are left untouched.

## User Stories

1. As a Domain Brain user, I want `start N` in `/triage` to mark a backlog item in-progress and display its full description as a clean work summary, so I can take it into any planning tool or workflow without needing Speckit installed.
2. As a Domain Brain user, I want the "yes/ready/go" confirmation in "start N" to output the item body verbatim, so I can copy it into an issue tracker, a spec doc, or a chat thread with no reformatting.
3. As a Domain Brain user, I want the triage session to continue after I acknowledge the work summary, so I can start another item or perform other triage operations in the same session.
4. As a Domain Brain maintainer, I want the `.specify/` directory absent from the repository, so there is no dead Speckit infrastructure cluttering the tree.
5. As a Domain Brain maintainer, I want all nine `speckit.*` command files removed from `.claude/commands/`, so the command palette contains only Domain Brain commands.
6. As a Domain Brain maintainer, I want `domain/config/priorities.md` to have no reference to an active `/speckit.specify` session, so priority guidelines are fully self-contained.
7. As a developer reading `decisions.md`, I want ADR-008 to describe the command-file schema pattern in Domain Brain's own terms (not attributed to Speckit), so the ADR remains accurate after Speckit is removed.
8. As a developer reading `decisions.md`, I want the ADR-015 implementation table row for "Speckit handoff" to be updated to reflect the new standalone summary behaviour, so the ADR accurately describes the implemented `/triage` design.
9. As a new contributor, I want the repository to contain only Domain Brain files, so I can understand the project without needing to understand Speckit.
10. As a Domain Brain user, I want the "not yet" path in "start N" to continue working exactly as before, so cancelling the start still keeps the item in-progress without side effects.
11. As a Domain Brain user, I want `write-a-prd` and `prd-to-issues` (global skills) to be unaffected, so my PRD and issue-creation workflows continue working normally.

## Implementation Decisions

### Files to delete

- All nine Speckit command files: `speckit.specify`, `speckit.plan`, `speckit.tasks`, `speckit.analyze`, `speckit.clarify`, `speckit.checklist`, `speckit.constitution`, `speckit.implement`, `speckit.taskstoissues` — all under `.claude/commands/`
- The entire `.specify/` directory and all its contents (templates, scripts, `memory/constitution.md`)

### Triage "start N" — new behaviour

The "start N" intent currently has two confirmation paths:
- "yes/ready/go" → invoke speckit handoff
- "not yet/no" → keep in-progress, re-prompt

After this change, the "yes" path becomes:

> Display the item's full body text under a `Work item summary:` heading, with a brief note that the item is ready to begin. Then re-prompt for the next triage action.

No external command is invoked. The user receives the body verbatim and decides what to do with it. The "not yet" path is unchanged.

The `handoffs` frontmatter entry in `triage.md` that references `speckit.specify` is removed.

### `triage.md` frontmatter

The `handoffs` block in `triage.md`'s YAML frontmatter contains an entry: `agent: speckit.specify`. This entry is removed. No other handoffs entries are affected.

### `domain/config/priorities.md`

The bullet "Items linked to an active `/speckit.specify` session" under "Elevate to High" is removed. The remaining bullets are preserved verbatim.

### `domain/distilled/decisions.md` — ADR-008

ADR-008 currently attributes the `description`/`handoffs` command-file schema to Speckit. The decision text is updated to describe the schema as Domain Brain's own command-file pattern. The rationale is updated accordingly. The decision outcome (use `description` and `handoffs` frontmatter) is unchanged.

### `domain/distilled/decisions.md` — ADR-015 implementation table

The row "Speckit handoff | `/triage` treats the speckit.specify workflow as an available handoff target when starting work on a backlog item" is replaced with a row that describes the new standalone summary behaviour.

### Files explicitly not changed

- `specs/*/checklists/*.md`, `specs/*/plan.md`, `specs/*/tasks.md` — frozen historical documentation; references to speckit commands in these files are accurate records of what was planned/used at the time.
- `write-a-prd` and `prd-to-issues` global skills — not Domain Brain files; not touched.
- `prds/ralph-github-issue-workflow.md` — references `write-a-prd` and `prd-to-issues`, not speckit commands; left untouched.

## Testing Decisions

A good test for this change verifies observable behaviour through the command interface, not internal file structure.

### What makes a good test here

- Invoke `/triage`, load the backlog, run "start N" for an open item, confirm with "yes", and verify the output contains the item body and does not mention speckit.
- Verify the repository tree contains no `speckit.*` files under `.claude/commands/` and no `.specify/` directory.
- Verify `/triage` loads and displays the backlog correctly after the frontmatter change.
- Verify `domain/config/priorities.md` does not mention speckit.
- Verify `domain/distilled/decisions.md` ADR-008 and ADR-015 no longer reference speckit as a runtime dependency.

### Modules to verify

- `triage.md` — "start N" flow (both yes and not-yet paths)
- `domain/config/priorities.md` — content review
- `domain/distilled/decisions.md` — ADR-008 and ADR-015 table row

## Out of Scope

- Removing or modifying `write-a-prd` and `prd-to-issues` global skills
- Updating historical `specs/` documentation files
- Replacing Speckit's planning workflow with a new equivalent built into Domain Brain (a separate future feature if needed)
- Removing other references to Speckit in comments or research notes that are purely historical/comparative (e.g. `specs/001-domain-brain/research.md` lines comparing Domain Brain to Speckit as an architectural reference point)

## Further Notes

The `description` and `handoffs` frontmatter schema introduced in ADR-008 remains in use. The schema itself is sound and is Domain Brain's own convention — the change is only to remove Speckit's name from the attribution in that ADR, not to retire the schema.

The `.specify/memory/constitution.md` file mentions Speckit as an example of an extension pattern. Since the entire `.specify/` directory is deleted, this reference disappears automatically.
