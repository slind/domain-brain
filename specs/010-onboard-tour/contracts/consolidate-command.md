# /consolidate Interface Contract

**Feature**: 010-onboard-tour
**Command file**: `.claude/commands/consolidate.md`
**Type**: Claude command file (Extension-First delivery)

## Invocation

```
/consolidate
/consolidate --domain <path>
```

### Arguments

| Argument | Required | Description |
|---|---|---|
| *(none)* | — | Runs consolidate against the auto-discovered domain root |
| `--domain <path>` | Optional | Explicit path to the domain brain root directory; overrides auto-discovery |

## Discovery Sequence

Same three-level domain root discovery as all other Domain Brain commands:

1. `--domain <path>` flag (if present)
2. `.domain-brain-root` file at git repository root
3. `domain/` directory at git repository root

If discovery fails → output error and stop:
```
Error: Cannot locate domain brain root.
Create a .domain-brain-root file or use: /consolidate --domain <path>
```

## Execution Flow

```
1. DISCOVER   Locate domain brain root (3-level discovery)
2. VALIDATE   Read config/identity.md — error and stop if missing
3. LOAD       Read distilled/interfaces.md (soft — missing = "none")
4. LOAD       Read distilled/backlog.md (soft — missing = "no priorities")
5. COMPOSE    Build domain/README.md content in memory
6. WRITE      Overwrite domain/README.md (create if absent)
7. CHANGELOG  Append entry to distilled/changelog.md (create if absent)
8. REPORT     Output confirmation summary to user
```

## Output: domain/README.md

See `data-model.md → DomainReadme` for full document structure.

**Overwrite behavior**: The file is always fully overwritten. Previous content is not preserved.

## Output: distilled/changelog.md (append)

```markdown
## YYYY-MM-DD — Consolidate Session

### Generated
- [consolidate]: domain/README.md → <created|updated> (N interfaces, M priorities)

---
```

## Terminal Output (success)

```
✓ domain/README.md <created|updated>

  Domain:      <domain name>
  Interfaces:  <N> listed
  Priorities:  <M> listed (top <M> of <total> open)
  Changelog:   distilled/changelog.md updated

README path: domain/README.md
```

## Terminal Output (error — missing identity)

```
Error: config/identity.md not found.
Run /frame first to define the domain identity before consolidating.
```

## Preconditions

| Condition | Behaviour if unmet |
|---|---|
| `config/identity.md` exists | **Hard stop** — error and exit |
| `distilled/interfaces.md` exists | Soft — section shows "No interfaces defined yet." |
| `distilled/backlog.md` exists | Soft — section shows "No open items." |
| `distilled/changelog.md` exists | Soft — file is created if absent |
| `domain/README.md` exists | Soft — file is overwritten if present, created if absent |

## Out of Scope

- Does not accept `--top N` flag (deferred to v2)
- Does not modify any distilled knowledge files (backlog, interfaces, decisions, requirements)
- Does not invoke any subagent
- Does not present any governed decisions
- Does not validate the content of `config/identity.md` beyond confirming it exists
