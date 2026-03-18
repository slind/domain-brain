# Data Model: Domain README — Consolidate Command

**Feature**: 010-onboard-tour
**Date**: 2026-03-18

## Entities

### DomainReadme

The output document written to `domain/README.md`. A pure Markdown file with no YAML frontmatter — designed for human readability in git browsers.

**Structure**:

```markdown
# <Domain Name> — Domain Brain README

> <domain one-liner from config/identity.md>

**Steward**: <steward from config/identity.md>
**Last generated**: <YYYY-MM-DD> by `/consolidate`

---

## Domain Summary

<pitch paragraph from config/identity.md>

---

## Exposed Interfaces

<list of interface contract titles from distilled/interfaces.md>
OR: "No interfaces defined yet."

---

## Intended Usage

<static prose: what Domain Brain is, the four commands, when to use each>

---

## Top Priorities

<up to 5 open backlog items from distilled/backlog.md>
OR: "No open items."

---

*Run `/consolidate` to refresh this document.*
```

**Field sources**:

| README field | Source |
|---|---|
| Domain Name | `config/identity.md` frontmatter `domain` field |
| One-liner | `config/identity.md` body `**One-line**:` field |
| Steward | `config/identity.md` frontmatter `steward` field |
| Last generated | Current UTC date (injected by command at runtime) |
| Pitch | `config/identity.md` body `**Pitch**:` field |
| Interface titles | All `## ` headings in `distilled/interfaces.md` that represent interface contracts |
| Intended Usage | Static prose (embedded in command, not sourced from a file) |
| Top Priorities | Up to 5 open items from `distilled/backlog.md`, ordered high → medium → low |

---

### ConsolidateSession

In-memory record maintained during a single `/consolidate` invocation. Never written to disk; the changelog entry is the durable record.

| Field | Type | Description |
|---|---|---|
| `run_date` | string (YYYY-MM-DD) | Date of the consolidate run |
| `domain_root` | string | Resolved path to the domain brain root |
| `readme_path` | string | Absolute path to `domain/README.md` |
| `identity_found` | boolean | Whether `config/identity.md` was found and read |
| `interfaces_count` | integer | Number of interface entries included in the README |
| `priorities_count` | integer | Number of backlog items included in the README |
| `readme_existed` | boolean | Whether `domain/README.md` existed before this run |
| `action` | enum: `created` \| `updated` | Whether the README was created or overwritten |

---

### BacklogItem (read-only view, for Top Priorities section)

A distilled entry from `distilled/backlog.md` used to populate the Top Priorities section. Read-only — `/consolidate` never modifies the backlog.

| Field | Source in backlog.md |
|---|---|
| `title` | `## <Title>` heading |
| `priority` | `**Priority**:` field (`high` \| `medium` \| `low`) |
| `status` | `**Status**:` field — only `open` or `in-progress` items are included |
| `description` | First sentence of the entry body (truncated at 120 chars if needed) |

**Selection logic**: Include items where `status` is `open` or `in-progress`. Exclude `done` items. Sort: `high` first, then `in-progress` (any priority), then `medium`, then `low`. Cap at 5 total.

---

### InterfaceEntry (read-only view, for Exposed Interfaces section)

An entry from `distilled/interfaces.md` used to populate the Exposed Interfaces section. Read-only — `/consolidate` never modifies the interfaces file.

| Field | Source |
|---|---|
| `title` | `## <Title>` heading from `distilled/interfaces.md` |

All `## ` headings in `distilled/interfaces.md` are included. No filtering.
