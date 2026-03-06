# Contract: /seed Command

**Command file**: `.claude/commands/seed.md`
**FR coverage**: FR-007–FR-015, FR-012a, FR-013, FR-013a

---

## Invocation Syntax

```
/seed <source>
/seed --domain <path> <source>
/seed --limit N <source>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<source>` | Yes | Local file path, web URL, or directory path to import from |
| `--domain` | No | Path to domain brain root; uses default discovery if absent |
| `--limit N` | No | Override the default 100-item cap for this session |

## Session Flow

```
1. LOCATE     Domain brain root (same discovery logic as /capture, /refine, /query)
2. CHECK      config/identity.md exists — error if missing
3. LOAD       config/identity.md into context (pitch, In scope list, Out of scope list)
4. DETECT     Source type (file, URL, directory); enumerate all target files
5. RESUME     Count existing raw items with source.location matching this source → compute offset
6. SEGMENT    Split source content at logical boundaries (per source type)
7. FILTER     Classify each segment for relevance against the domain identity
8. WRITE      Create raw item files for in-scope and ambiguous segments
9. REPORT     Output session summary
```

## Source Type Handling

| Source type | Detection | Segmentation |
|-------------|-----------|--------------|
| Markdown file (`.md`) | file path ends in `.md` | Split at `##` headings; fall back to `###` or paragraph breaks for long sections |
| PDF file (`.pdf`) | file path ends in `.pdf` | Read in 10-page batches; split at detected headings or page boundaries |
| Web URL | starts with `http://` or `https://` | Fetch with Read tool; split by heading structure |
| Directory | path is a directory | Glob `.md` and `.pdf` files; apply per-file rules; report unsupported formats |

## Segment Minimum Requirement

A segment is eligible to become a raw item only if it contains at least one complete,
standalone knowledge claim. Segments that are only a heading, a single phrase, or boilerplate
(e.g., table of contents, navigation, footers) are merged with the adjacent segment or
discarded.

## Relevance Classification (per segment)

Uses semantic judgment against `config/identity.md` — not keyword matching alone.

| Classification | Condition | Action |
|----------------|-----------|--------|
| **In scope** | Topic clearly aligns with the "In scope" list and pitch | Create raw item, no `seed-note` |
| **Out of scope** | Topic clearly aligns with the "Out of scope" list | Skip; log reason in session summary |
| **Ambiguous** | Neither clearly in nor out; or identity scope lists are insufficient to judge | Create raw item with `seed-note: Relevance uncertain` |

If the "Out of scope" list in `config/identity.md` is empty: all segments are treated as
ambiguous and the session summary warns the user.

## Session Cap

- Default cap: **100 raw items written** per session (in-scope + flagged; skipped items do not count).
- Override with `--limit N`.
- When cap is reached: stop, report remaining segment count, report resume offset for next run.
- On re-run: auto-detect resume offset from count of existing raw items with matching `source.location`.

## Raw Item Structure

Each created raw item follows the standard raw item format with these specifics:

```yaml
---
id: <domain>-<YYYYMMDD>-<4hex>
source:
  tool: seed
  location: <file path or URL>
type: <inferred type>
domain: <domain>
tags: []
captured_at: <UTC ISO 8601>
captured_by: <git user name>
status: raw
seed-note: "Relevance uncertain"   # present only for ambiguous segments
---

# <title>

<segment content — verbatim or lightly cleaned>
```

**Title rule**: Use the nearest section heading if present; otherwise infer a ≤10-word title
from the segment content. Title MUST NOT be blank.

## Output

### Session in progress (announced before processing)

```
Seeding from: <source>
Domain: payments | Identity: config/identity.md loaded

Resuming from segment 101 (100 already seeded).   ← only if resuming
Processing segments 101–200...
```

### Session complete

```
Seed session complete.

Source: path/to/document.md
  Created (in scope):     42 items
  Skipped (out of scope): 18 segments
  Flagged (uncertain):    7 items
  Unreadable:             0

Run /refine to process the 49 new items.
```

### Session complete — cap reached

```
Seed session complete. Cap reached at 100 raw items.

Source: path/to/large-doc.md
  Created (in scope):     82 items
  Skipped (out of scope): 31 segments
  Flagged (uncertain):    18 items
  Unreadable:             0

84 segments remain unprocessed.
Re-run /seed on the same source to continue (will resume from segment 202).
```

### Error — missing identity

```
Error: config/identity.md not found.
Run /frame first to define what this domain is about before seeding.
```

### Error — unsupported file format (within directory seed)

```
Skipped 3 unsupported files:
  - design-spec.docx  (export to PDF or Markdown first)
  - budget.xlsx       (export to Markdown first)
  - notes.pages       (export to PDF or Markdown first)
```

### Error — inaccessible URL

```
Skipped 1 inaccessible URL:
  - https://wiki.internal.example.com/payments (authentication required)
  Export the page content to a local file and re-run /seed with the file path.
```

## Files Written

- `raw/<id>.md` — one per in-scope or ambiguous segment (up to 100 per session)
