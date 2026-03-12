# Quickstart: Verifying Refine Pipeline Performance Improvements

**Feature**: 003-refine-perf | **Date**: 2026-03-12

Three independent verification scenarios — one per improvement. Each can be run separately.

---

## Verify P1: Host-Level Pre-Filtering

**Goal**: Confirm the host eliminates exact duplicates and out-of-scope items before the
subagent is invoked.

### Setup

1. Pick an existing distilled entry from `domain/distilled/requirements.md` (any entry will
   do). Copy its body text verbatim.
2. Create a raw item manually (or via `/capture`) with that exact body text.
3. Capture one more item whose content matches a term on the Out-of-scope list in
   `config/identity.md` (e.g., "Confluence REST API integration setup").

### Run

```
/refine --limit 5
```

### Expected output

Session announcement lists the new items. After starting:

```
Autonomous: N items processed
  ✓ Pre-filtered 1 duplicate (host)
  ✓ Pre-filtered 1 out-of-scope (host)
  ...
```

The changelog entry has a `### Pre-filtered (host)` subsection listing both items with
their reasons. Neither item appeared in the subagent's input (the subagent should not
mention them in its plan).

---

## Verify P2: Specialist Subagents

**Goal**: Confirm items are routed to specialist subagents and the merged plan is correctly
executed.

### Setup

Ensure the raw queue contains at least:
- One item of type `requirement`
- One item of type `interface`
- One item of type `decision`
- One item of type `task` or `mom` (generalist path)

### Run

```
/refine --limit 10
```

### Expected output

The session processes all four items. Check the changelog: each item should be processed
correctly. Verify by examining the distilled files — the requirement item should appear in
`requirements.md`, the interface item in `interfaces.md`, the decision item in
`decisions.md`, and the task/mom item in `backlog.md` or `changelog.md`.

No item should appear in the wrong distilled file.

---

## Verify P3: Type Inference at Capture and Seed

### 3a — /capture

**Goal**: Confirm the signal table assigns types without asking the user.

```
/capture "The checkout service MUST complete payment processing within 2 seconds under P99 load"
```

**Expected**: Type assigned as `requirement` silently. No "Type is ambiguous" prompt shown.

```
/capture "The payments-api repository is a Node.js service deployed on AWS ECS"
```

**Expected**: Type assigned as `codebase` silently.

```
/capture "We chose Kafka over RabbitMQ because Kafka's consumer group model better supports our replay requirements"
```

**Expected**: Type assigned as `decision` silently.

### 3b — /seed

**Goal**: Confirm seeded items receive specific types (not `other`) when signals are present.

Run `/seed` on any Markdown file that contains a mix of content — requirements, design
decisions, and meeting notes. After the seed completes:

```
/refine --limit 5
```

Check the session announcement. Items seeded from requirements sections should show
type `requirement`, design rationale sections should show type `decision`, etc. Fewer items
should show type `other` compared to a baseline seed from the same file before the
improvement.

**Baseline comparison**: If `other` items previously made up >30% of a seeded batch from
this source, the improved inference should bring that below 20% (SC-004).

---

## Verify SC-005: No Spurious Full-Load Sessions

**Goal**: Confirm that a batch with no `other` items does not trigger a full distilled-files
load.

### Setup

Use `/capture` to create several items of specific types (requirement, interface, decision)
with no `other` items. Ensure none of them are exact duplicates of existing entries.

### Run

```
/refine --limit 5
```

### Expected

The session completes without loading all distilled files for the generalist cluster. Only
the type-specific context files are loaded (verify via the session output or by observing
that no generalist subagent invocation occurs if no items route to the generalist cluster).
