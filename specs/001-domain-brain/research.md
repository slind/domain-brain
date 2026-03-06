# Research: Software Domain Brain

**Feature**: 001-domain-brain | **Branch**: 001-domain-brain | **Date**: 2026-03-05

---

## Decision 1: Delivery Mechanism

**Decision**: Claude AI assistant extension — command files only (`.claude/commands/*.md`).

**Rationale**: Spec Technical Constraints mandate "Claude command or skill; refine agent is a
subagent orchestrated by the host." Claude command files are Markdown with YAML frontmatter —
no build step, no server, no dependencies. Commands invoke built-in tools (Read, Write, Edit,
Glob, Grep, Bash) for all file operations. This is identical to how speckit is delivered in
this repo, giving us a proven pattern to follow.

**Alternatives considered**:
- Node.js CLI — rejected: violates Extension-First, adds deployment complexity and a runtime
  dependency not available in all Claude environments.
- Python scripts — rejected: same reasons as Node.js.

---

## Decision 2: Hot-Reload for types.yaml (FR-003a)

**Decision**: Read `config/types.yaml` at every command invocation using the Read tool.

**Rationale**: Claude commands execute fresh per invocation — there is no persistent daemon to
reload. "Hot-reload" in this context simply means the command reads the file on every call.
Any edit to `types.yaml` takes effect at the next `/capture` or `/refine` invocation without
any restart. This is zero-cost to implement and requires no infrastructure.

**Alternatives considered**:
- File watcher daemon — rejected: violates Extension-First, over-engineered for this delivery
  model, and impossible to maintain from within a command file.

---

## Decision 3: Retrieval Strategy by Domain Size (FR-023)

**Decision**:

| Tier | Threshold | Strategy | Tool |
|---|---|---|---|
| Small | ≤50 distilled entries | Load all candidate files fully into context | Read |
| Medium | 51–500 entries | Grep candidate files for keyword matches; load top-N | Grep + Read |
| Large | >500 entries | Hosted index | Deferred to v2 |

**Rationale**: Claude's context window holds all distilled files for a small domain (≤50 entries
× ~500 tokens ≈ 25k tokens — well within limits). For medium domains, the Grep tool provides
keyword/substring search without any external infrastructure. Grep-based retrieval is O(file
size) and sufficient for ≤500 entries. No embedding pipeline required for v1.

**Alternatives considered**:
- Local SQLite FTS — rejected: violates IV Knowledge as Code (opaque database).
- External vector store — rejected: violates Extension-First and Knowledge as Code; over-engineered
  for v1 scope.

---

## Decision 4: Refine Subagent Pattern (FR-008–FR-015)

**Decision**: The `/refine` command orchestrates a refine subagent via the Agent tool. Flow:

1. Host `/refine` command loads raw queue and distilled context.
2. Host invokes refine subagent with item batch + knowledge context.
3. Subagent processes items: autonomous actions silently, governed decisions returned as structured
   output to host.
4. Host presents each governed decision to the human one at a time (FR-010).
5. Human responds; host records decision + rationale in changelog.md (FR-014).
6. Host invokes subagent again with next batch until queue is exhausted or session paused.

**Rationale**: Mirrors the speckit implement pattern where the host command orchestrates subagents
for execution. The separation keeps the governed decision loop clean (host-side) while the
subagent focuses on knowledge processing. The subagent never writes to distilled files directly —
only the host writes after human confirmation.

**Alternatives considered**:
- Single monolithic /refine command with no subagent — rejected: conflates orchestration logic
  with knowledge processing; makes the governed decision loop difficult to test and reason about.

---

## Decision 5: Large Document Chunking (FR-007, FR-022)

**Decision**: When a raw item references a document above the size threshold (~10 pages / ~5000
tokens), the capture pipeline:

1. Reads the document using Read tool (with page ranges for PDFs).
2. Splits at logical boundaries: Markdown headings, paragraph breaks, or PDF page boundaries.
3. Stores each chunk as a separate `.md` file under `index/<doc-id>/chunks/chunk-NNNN.md`.
4. Stores a ≤500-word summary at `index/<doc-id>/summary.md`.
5. Updates the relevant distilled entry with `chunk-ids` reference list.

For second-stage retrieval (FR-022): Grep searches `index/<doc-id>/chunks/` for relevant
passages, then loads matched chunks into context.

**Rationale**: Storing chunks as individual `.md` files preserves Knowledge as Code (all files
human-readable in git). Grep can search chunk files efficiently for second-stage retrieval
without external tooling.

**Alternatives considered**:
- Single large-document file — rejected: defeats targeted retrieval; loads full document into
  context regardless of relevance.
- External vector index — rejected: violates Extension-First and Knowledge as Code for v1.

---

## Decision 6: Domain Brain Instance Layout

**Decision**: A domain brain instance is a directory (named after the domain) with `config/`,
`raw/`, `distilled/`, and `index/` subdirectories. Teams initialize by copying the `domain/`
template directory from this repo.

Command discovery order for domain root:
1. Explicit `--domain <path>` argument.
2. `.domain-brain-root` file at git repo root (contains the path).
3. Conventional `domain/` directory at git repo root.

**Rationale**: Per-directory isolation enables multiple domains in one repo. Git tracks all
changes natively. The `.domain-brain-root` pointer file enables flexible placement.

---

## Decision 7: Raw Item Filename Convention

**Decision**: Each raw item stored as `raw/<id>.md` where `<id>` = `<domain>-<YYYYMMDD>-<4hex>`
(e.g., `raw/payments-20260305-a3f2.md`). The filename matches the `id` frontmatter field.

**Rationale**: Filename matches id → findable without parsing frontmatter. Sorting by filename
gives approximate chronological order within a domain. Domain prefix keeps items identifiable
if files are ever moved or shared.

---

## Decision 8: Command File Patterns (from speckit analysis)

All Claude command files follow this schema:

```yaml
---
description: [One-line description shown in command palette]
handoffs:
  - label: [Button label]
    agent: [target-command-name]
    prompt: [Context prompt for next command]
---
```

The `handoffs` array enables chained workflows (e.g., after `/capture`, offer `/refine`).
Domain Brain commands will use this pattern to chain `/capture` → `/refine` → `/query`.

---

## Resolved NEEDS CLARIFICATION Items

All Technical Context fields from plan.md were inferable from spec and codebase exploration.
No external research required. All decisions resolved above.
