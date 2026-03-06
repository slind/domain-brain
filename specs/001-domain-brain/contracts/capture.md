# Contract: /capture Command

**Command file**: `.claude/commands/capture.md`
**FR coverage**: FR-001–FR-007

---

## Invocation Syntax

```
/capture <description>
/capture --title "Title text" --type <type> [description]
/capture --domain <path> <description>
```

## Arguments

| Argument | Required | Description |
|---|---|---|
| `<description>` | Yes (if no `--title`) | Free-form description of the knowledge item |
| `--title` | No | Explicit title; inferred from description if absent |
| `--type` | No | Explicit type from types.yaml; inferred from description if absent |
| `--domain` | No | Path to domain brain root; uses default discovery if absent |

## Auto-Populated Envelope Fields

The command generates all envelope fields the user does not provide:

| Field | Generation rule |
|---|---|
| `id` | `<domain>-<YYYYMMDD>-<4-char-hex>` using current date and random hex |
| `source.tool` | Detected from invocation context (`claude-code`, `chat`, etc.) |
| `source.location` | Active file path or URL if available; omitted otherwise |
| `type` | Inferred from description using types.yaml examples; confirmed if ambiguous |
| `domain` | Inferred from domain brain root name or `.domain-brain-root` file |
| `captured_at` | Current UTC timestamp in ISO 8601 format |
| `captured_by` | Git user name or session identity |
| `status` | Always `raw` at capture time |

## Type Inference and Confirmation

1. Load `config/types.yaml` from domain root.
2. Match description against each type's `description` and `example` fields.
3. If confidence is high (clear match): assign type silently (FR-006).
4. If confidence is low (ambiguous): display type options with descriptions and ask for
   confirmation (FR-003b, FR-006). Present one question only.
5. If `--type` is provided explicitly: use it without inference; skip confirmation.

## Output

### Success

```
Captured: payments-20260305-a3f2
  Type: responsibility
  File: raw/payments-20260305-a3f2.md
  Status: raw — ready for next refine session
```

### Validation Failure (FR-004)

```
Error: Could not determine domain. Use --domain <path> or create a .domain-brain-root file.
Missing fields: [domain]
```

### Large Document Detected (FR-007)

When the description references a document above the size threshold:

```
Large document detected: psd2-spec-v4.pdf (~42 pages)
Processing: chunking at logical boundaries...
  Created 38 chunks in index/psd2-spec-v4/
  Summary written to index/psd2-spec-v4/summary.md
Captured: payments-20260305-e5f6 (type: requirement, with chunk references)
```

## Files Written

- `raw/<id>.md` — the captured raw item

Optionally (large document):
- `index/<doc-id>/summary.md`
- `index/<doc-id>/chunks/chunk-NNNN.md` (one per chunk)
