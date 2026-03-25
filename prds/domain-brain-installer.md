---
type: prd
issue: 8
---

## Problem Statement

There is no automated mechanism to install Domain Brain into a new or existing project. A user who wants to adopt Domain Brain must manually copy `.claude/commands/`, `.claude/agents/`, `.claude/skills/`, and `domain/config/` files — with no documented procedure and no way to keep their installation up to date. Adoption is blocked at step zero.

Additionally, all Domain Brain commands and skills are currently unprefixed (`/capture`, `/refine`, etc.), meaning they collide with commands from any other Claude Code extension the user has installed. There is no way to tell at a glance which commands belong to Domain Brain.

## Solution

A single bash script (`install.sh`) hosted in this repository on `main`. The script creates the Domain Brain scaffold in a new or existing project by fetching commands, agents, and skills directly from GitHub. A `--update` flag re-fetches only the Domain Brain-owned files, leaving the user's domain knowledge and any other installed extensions untouched.

As part of this work, all commands and skills are renamed with a `domain:` namespace prefix, following Claude Code conventions. Users invoke `/domain:capture`, `/domain:refine`, etc. This makes Domain Brain commands unambiguous in any project.

## User Stories

1. As a new Domain Brain user, I want to run a single shell command that sets up a new project folder, so that I don't have to manually copy files or figure out the directory structure.
2. As an existing project owner, I want to run the installer in my current repo, so that Domain Brain integrates into the project without disrupting my existing `.claude/` setup.
3. As a user, I want the installer to fetch the latest command files from GitHub, so that I always start with an up-to-date install without cloning the whole domain-brain repo.
4. As a user, I want the installer to create a `.domain-brain-root` marker file, so that all Domain Brain commands reliably locate the domain root without manual configuration.
5. As a user, I want `domain/config/types.yaml` written for me on first install, so that the type routing system works immediately without manual setup.
6. As a user, I want `domain/raw/`, `domain/distilled/`, and `domain/index/` to be created automatically on first use, so that the installer stays minimal and I'm not confronted with empty placeholder directories.
7. As a user, I want the first thing I do after install to be running `/domain:frame`, so that I have a clear, guided starting point for defining my domain.
8. As a user, I want all Domain Brain commands prefixed with `domain:`, so that I can instantly identify them and they don't clash with commands from other extensions.
9. As a user, I want to run `install.sh --update` to upgrade my Domain Brain commands and skills to the latest version, so that I can pull improvements without reinstalling from scratch.
10. As a user, I want the update to leave my `domain/` folder completely untouched, so that I never risk losing my captured or distilled knowledge during an upgrade.
11. As a user, I want the update to leave `domain/config/types.yaml` untouched, so that any custom types I've added are preserved across upgrades.
12. As a user, I want the update to leave any non-Domain Brain skills and commands in `.claude/` untouched, so that upgrading Domain Brain doesn't affect other installed extensions.
13. As a user, I want the installer to print a clear success message with the next step (`/domain:frame`), so that I know the install succeeded and what to do next.
14. As a user, I want the update script to report which files were added, updated, or removed, so that I know what changed after an upgrade.
15. As a user, I want to be able to install Domain Brain into any directory, so that I can adopt it in any project regardless of its existing structure.
16. As a developer referencing other Domain Brain commands from within a command file, I want the cross-references to use the `domain:` prefix, so that internal references are consistent with what users actually type.

## Implementation Decisions

### Module 1 — `install.sh` (new file at repo root)

A single bash script with two modes, distinguished by the `--update` flag.

**Install mode** (default):
- Accepts an optional positional argument `<project-name>`. If provided, creates a new subdirectory at the current location and operates inside it. If omitted, operates in the current directory.
- Fetches all `domain:*` command files, `domain-*` agent files, and `domain-*/SKILL.md` skill files from the GitHub `main` branch using `curl`.
- Creates `.domain-brain-root` containing the relative path `domain/`.
- Writes `domain/config/types.yaml` only if it does not already exist.
- Does NOT run `git init`, create `domain/raw/`, `domain/distilled/`, or `domain/index/`.
- Prints: `Domain Brain installed. Run /domain:frame to define your domain.`

**Update mode** (`--update` flag):
- Re-fetches all files matching the Domain Brain ownership pattern from GitHub `main`.
- Overwrites existing Domain Brain-owned files in `.claude/commands/`, `.claude/agents/`, `.claude/skills/`.
- Never touches `domain/`, `.domain-brain-root`, or `domain/config/types.yaml`.
- Leaves any non-Domain Brain files in `.claude/` untouched.
- Reports each file as `added`, `updated`, or `removed`.

**Ownership pattern** (used by update to identify Domain Brain files):
- Commands: filenames matching `domain:*.md` in `.claude/commands/`
- Agents: filenames matching `domain-*.md` in `.claude/agents/`
- Skills: directories matching `domain-*/` in `.claude/skills/`

### Module 2 — Namespace rename (changes to existing files in this repo)

All existing command files, skill directories, and the agent file are renamed with the `domain:` prefix:

- Commands: `capture.md` → `domain:capture.md`, same for `frame`, `refine`, `query`, `triage`, `consistency-check`
- Skills: `capture/` → `domain-capture/`, `seed/` → `domain-seed/`; `name:` frontmatter field updated to `domain:capture` and `domain:seed`
- Agent: `refine-subagent.md` → `domain-refine-subagent.md`

### Module 3 — Cross-reference updates (changes to existing command/skill content)

All 13 internal cross-references across command and skill files are updated from unprefixed form (`/capture`, `/refine`, etc.) to prefixed form (`/domain:capture`, `/domain:refine`, etc.). Affected files:

- `domain:capture` skill: references `/domain:refine`
- `domain:seed` skill: references `/domain:frame`, `/domain:refine`
- `domain:frame`: references `/domain:seed`, `/domain:capture`, `/domain:refine`
- `domain:query`: references `/domain:capture` (×2)
- `domain:consistency-check`: references `/domain:capture`, `/domain:refine`, `/domain:frame`
- `domain:triage`: references `/domain:query`
- `domain:refine`: references `/domain:query`
- `domain-refine-subagent`: references `/domain:refine`

### Module 4 — On-the-fly directory creation (changes to existing commands)

Each command that writes to `domain/raw/`, `domain/distilled/`, or `domain/index/` must create the required directory if it does not exist before attempting to write. This removes the need for the installer to pre-create these directories.

Commands affected: `domain:capture`, `domain:seed`, `domain:refine`, `domain:frame`, `domain:triage`, `domain:consistency-check`.

## Testing Decisions

**What makes a good test here**: test observable file system outcomes, not internal script logic. A test runs the script against a temp directory, then asserts the resulting structure — files present, files absent, file contents. Do not test implementation details like which curl command was used.

**Modules to test**:

- **`install.sh` (new project)**: create a temp dir, run `install.sh my-project`, assert `.claude/commands/domain:*.md` exist, `.domain-brain-root` exists, `domain/config/types.yaml` exists, `domain/raw/` does not exist.
- **`install.sh` (existing project)**: create a temp dir with an existing `.claude/skills/some-other-skill/`, run `install.sh`, assert Domain Brain files installed and `some-other-skill/` untouched.
- **`install.sh --update`**: install, then manually modify a Domain Brain command file, run `--update`, assert the file was restored; assert a user-created file in `.claude/` was not touched; assert `domain/` was not touched.
- **`types.yaml` preservation**: install, modify `types.yaml`, run `--update`, assert `types.yaml` still contains the modification.

**Prior art**: no existing shell tests in this repo. These would be new bash test files using a simple assert pattern (compare expected vs actual file contents/structure).

## Out of Scope

- `git init` — the installer never initialises a git repository.
- Windows native (non-WSL) support — the script targets bash on Linux/macOS/WSL.
- Authenticated or private GitHub repositories as the source.
- Pinned version installs — `--update` always fetches `main`; version pinning is a future feature.
- `domain/config/types.yaml` migration — if the built-in types change in a future release, merging user-customised types with the new defaults is out of scope.
- Interactive domain setup during install — the installer does not prompt for domain name or pitch; that is the job of `/domain:frame`.
- Installing Domain Brain into `~/.claude/` (global install) — project-local only for now.

## Further Notes

- The `domain:` prefix uses a colon separator following Claude Code's official namespace convention.
- Skill directory names use a hyphen (`domain-capture/`) rather than a colon, since colons in directory names can be problematic on some filesystems and tooling. The colon appears only in the `name:` frontmatter field, which is what Claude Code uses for invocation.
- The `.domain-brain-root` file enables reliable root detection regardless of where in a project the user is working. Without it, commands fall back to detecting a `domain/` subdirectory, which breaks if the user places their domain folder at a non-standard path.
- The rename from unprefixed to `domain:`-prefixed commands is a breaking change for the single current installation. This is acceptable and will be handled as part of this work.
