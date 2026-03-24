---
type: prd
issue: 1
---

## Problem Statement

The Ralph agent system (`afk.sh`, `once.sh`, `prompt.md`) currently works by reading a local PRD file passed as a command-line argument. There is no connection between Ralph's work and GitHub issues, so there is no shared, visible record of what is planned, in progress, or complete. The `write-a-prd` skill saves PRDs only as local files with no GitHub presence. The `prd-to-issues` skill creates child issues but has no reliable way to reference the parent PRD issue. The result is a fragmented workflow where the PRD, the issue tracker, and the agent are not connected.

## Solution

Connect the three components into a single GitHub-centric workflow:

1. `write-a-prd` creates the PRD as a local markdown file AND opens a GitHub issue (labeled `prd`) that references it. The issue number is written back into the PRD's YAML frontmatter, binding them permanently.
2. `prd-to-issues` accepts a GitHub issue number, reads the linked PRD file via its frontmatter, and creates child issues with the parent already populated.
3. Ralph (`afk.sh`, `once.sh`, `prompt.md`) is rewritten to query GitHub for open `prd`-labeled issues, read the linked PRD files, manage child issues as a task queue, and track progress through issue state rather than only through git commits.

Ralph never closes the parent PRD issue — only child issues are closed by Ralph, and only when work is committed and complete.

## User Stories

1. As a developer, I want `write-a-prd` to automatically open a GitHub issue when I finish writing a PRD, so that the PRD is immediately visible in the issue tracker without manual steps.
2. As a developer, I want the GitHub issue created by `write-a-prd` to contain a link to the local PRD file, so that anyone reading the issue can find the full specification.
3. As a developer, I want the PRD markdown file to store its GitHub issue number in frontmatter, so that other tools can reliably find the associated issue without searching.
4. As a developer, I want to invoke `prd-to-issues` with a GitHub issue number instead of a file path, so that the parent PRD reference is automatically populated in every child issue.
5. As a developer, I want `prd-to-issues` to read the PRD file path from the issue's linked frontmatter, so that I don't have to remember or type the file path manually.
6. As a developer, I want to run `ralph-afk <max-iterations>` with no other arguments and have Ralph automatically discover all open PRD issues in the repo, so that I don't have to manage which PRD Ralph is working on.
7. As a developer, I want to run `ralph-afk #42 <max-iterations>` to target a specific PRD issue, so that I can direct Ralph's focus when I have multiple open PRDs.
8. As a developer, I want Ralph to detect whether child issues already exist for a PRD before breaking it down, so that Ralph doesn't duplicate work when `prd-to-issues` has already been run.
9. As a developer, I want Ralph to break down a PRD into all child issues in a single pass (when none exist), so that the full plan is visible on GitHub before implementation begins.
10. As a developer, I want Ralph to respect `Blocked by:` dependencies in child issues and skip blocked issues, so that Ralph works in a valid dependency order.
11. As a developer, I want Ralph to create a child GitHub issue before starting work on a task, so that in-progress work is visible on GitHub.
12. As a developer, I want Ralph to close the child issue when it commits the completed task, so that issue state and git history stay in sync.
13. As a developer, I want Ralph to leave a blocked child issue open with a comment explaining the blocker, so that I can see what is stuck and why.
14. As a developer, I want Ralph to post a comment on the parent PRD issue when all child issues are closed, so that I know the implementation is complete without having to count issues manually.
15. As a developer, I want Ralph to never close the parent PRD issue, so that I retain full control over when a feature is considered done and released.
16. As a developer, I want Ralph's commit messages to reference both the child issue and the parent PRD issue, so that the git log is navigable from either direction.
17. As a developer, I want Ralph to read the last 10 commits as context, so that it avoids duplicating work already merged.
18. As a developer, I want Ralph to explore the relevant parts of the codebase before starting a task, so that implementation decisions are grounded in the actual state of the code.
19. As a developer, I want Ralph to abort an iteration cleanly when blocked mid-task (rather than producing broken commits), so that the repository always stays in a working state.
20. As a developer, I want `ralph-once` to support the same GitHub-centric flow as `ralph-afk`, so that single-iteration and looping invocations behave consistently.

## Implementation Decisions

### Modules to modify

**`write-a-prd` skill (SKILL.md)**
- After saving the PRD markdown file to `./prds/`, run `gh issue create` with label `prd`, title from the PRD heading, and body containing a one-paragraph summary plus the relative path to the PRD file.
- Parse the issue URL/number from the `gh` output and write it back into the PRD file's YAML frontmatter as `issue: <number>`.
- The GitHub issue body is intentionally short — the file is the source of truth, not the issue body.

**`prd-to-issues` skill (SKILL.md)**
- Change the invocation contract: the skill accepts a GitHub issue number (e.g. `#42`) rather than a file path.
- Fetch the issue body with `gh issue view <number>` to extract the PRD file path.
- Read the PRD file. The frontmatter `issue:` field confirms the binding.
- When creating child issues, populate `Parent PRD: #<number>` automatically — no longer left blank.

**`ralph/afk.sh`**
- Change signature from `afk.sh <path-to-prd> <max-iterations>` to `afk.sh [#issue] <max-iterations>`.
- When no issue is given, run `gh issue list --label prd --state open --json number` to collect all candidate PRD issue numbers.
- Pass the list of issue numbers (or the single targeted number) into the Claude invocation as context instead of a file path.

**`ralph/once.sh`**
- Same signature and discovery changes as `afk.sh`.

**`ralph/prompt.md`**
- Complete rewrite. New iteration loop:
  1. Receive one or more PRD issue numbers.
  2. For each PRD issue: fetch the issue, read the PRD file path from the body, read the file.
  3. Run `gh issue list` to find open child issues referencing each PRD (by "Parent PRD: #" in body).
  4. If no child issues exist for a PRD: break the PRD down into all tasks at once (using the same vertical-slice format as `prd-to-issues`), create all child issues, then proceed.
  5. Filter out child issues where `Blocked by:` references an open issue — skip those.
  6. If no open unblocked child issues remain across all PRDs: post a completion comment on each parent PRD issue, emit `<promise>NO MORE TASKS</promise>`, stop.
  7. Pick one open unblocked child issue. Explore the codebase for relevant context.
  8. If blocked mid-task: post a comment on the child issue explaining the blocker, stop the iteration without committing.
  9. Implement the task. Commit with message referencing both `Closes #<child>` and `Ref #<prd>`.

### Architectural decisions

- **File is source of truth, issue is tracker**: PRD content lives in the markdown file. The GitHub issue body is intentionally minimal (summary + path). This makes editing easy and keeps the file and code co-located.
- **Frontmatter as the binding**: `issue: <number>` in the PRD frontmatter is the canonical link between file and issue. Both `prd-to-issues` and Ralph read this field.
- **Child issues as task queue**: Ralph treats open, unblocked child issues as its work queue. Closed = done. Open = todo or in-progress. This replaces the previous pattern of inferring progress solely from git commits (git log is still read as supplementary context).
- **All-or-nothing breakdown**: When Ralph breaks down a PRD, it creates all child issues in one pass so the full plan is visible before any code is written. It does not create issues one-by-one as it goes.
- **Equal priority across PRDs**: When multiple PRD issues are open, Ralph treats all unblocked child issues as equal priority. No round-robin guarantee; ordering is opportunistic.

## Testing Decisions

These modules are shell scripts and markdown skill definitions — they have no unit-testable logic in isolation. Testing is end-to-end and manual:

- A good test verifies observable behavior: the correct GitHub issues are created with the correct fields, Ralph commits reference the correct issue numbers, and blocked issues are skipped.
- Manual test path: create a PRD with `write-a-prd`, verify issue created and frontmatter updated; run `prd-to-issues #<n>`, verify child issues have correct parent; run `ralph-once #<n>`, verify one child issue is closed and commit references both issue numbers.

## Out of Scope

- Ralph closing the parent PRD issue under any circumstances.
- Priority or ordering guarantees when multiple PRDs are active.
- Authentication or access control for the GitHub CLI.
- Any changes to the PRD template format itself.
- CI/CD integration (Ralph is always invoked manually).
- The `ralph/prompt.md` child issue format is intentionally the same as `prd-to-issues` — no new template design needed.

## Further Notes

- The `gh` CLI must be authenticated and the repo must have a remote pointing to GitHub for all of this to work. This is an assumed precondition, not something Ralph validates.
- The `prd` label must exist in the target GitHub repo. `write-a-prd` should create it if absent (`gh label create prd --color 0075ca` or similar).
- Child issues created by Ralph during breakdown should follow the same issue body template currently used by `prd-to-issues` for consistency.
