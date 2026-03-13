# Quickstart: Semantic Duplicate Detection in /refine

**Branch**: `005-semantic-dedup-refine` | **Phase**: 1 | **Date**: 2026-03-13

Verification scenarios for the three user stories. All tests are manual — run `/refine` and
observe the session output and changelog entry.

---

## Prerequisite

Ensure the domain brain has at least a few distilled entries so there is a corpus to compare
against. The domain used during development is `domain/` at the repo root.

---

## Scenario 1 — Near-duplicate suppressed before subagent (P1, FR-001–004)

**Goal**: Confirm that a raw item paraphrasing an existing distilled entry is caught by 6.5c
and never reaches the subagent.

**Setup**:
1. Identify any existing distilled entry (e.g., a `requirements.md` entry).
2. Capture a new raw item using `/capture` whose body conveys the same fact in different words.
   Do not make it a word-for-word copy (that would be caught by 6.5a instead).
3. Note the item ID from the raw queue.

**Run**: `/refine`

**Expected session output**:
```
Pre-filter results:
  Exact duplicates:       0
  Out of scope:           0
  Semantic duplicates:    1
    <item_id> → matched: <distilled entry title>
```

**Expected changelog entry**: Contains `### Semantic Duplicates` subsection with the item ID,
matched entry reference, and similarity basis.

**Pass criteria**:
- Item does not appear in the subagent's input batch.
- Item's raw file `status` is set to `refined`.
- Changelog has the semantic duplicate record.

---

## Scenario 2 — Genuinely new item passes through (FR-004)

**Goal**: Confirm that a raw item with new knowledge is not incorrectly suppressed.

**Setup**: Capture a raw item whose content does not substantially overlap any existing
distilled entry — a new fact, a new requirement, a new decision.

**Run**: `/refine`

**Expected**: Item appears in the subagent's batch and is processed normally. Session output
shows `Semantic duplicates: 0`. No `### Semantic Duplicates` subsection in the changelog.

**Pass criteria**: No false suppression. Changelog has no semantic duplicates section.

---

## Scenario 3 — Default threshold used when config absent (FR-008)

**Goal**: Confirm that the host applies `moderate` and surfaces a notice when
`config/similarity.md` does not exist.

**Setup**: Ensure `domain/config/similarity.md` does not exist (or temporarily rename it).

**Run**: `/refine` with any non-empty raw queue.

**Expected session output** (somewhere near the start):
```
No similarity config found — using default threshold: moderate.
```

**Pass criteria**: Session proceeds normally. `moderate` behavior is applied for 6.5c.

---

## Scenario 4 — Threshold adjustment changes suppression behaviour (FR-007, SC-003)

**Goal**: Confirm that switching from `moderate` to `conservative` causes previously-suppressed
items to pass through.

**Setup**:
1. Run Scenario 1 with `config/similarity.md` set to `moderate`. Confirm suppression.
2. Recapture the same paraphrase item (or restore its status to `raw`).
3. Change `config/similarity.md` level to `conservative`.

**Run**: `/refine`

**Expected**: At `conservative`, the paraphrase item is NOT suppressed (it passes to the
subagent) because it is a different framing, not a near-verbatim restatement.

**Pass criteria**: Suppression count drops at `conservative` vs `moderate` for the same items.

---

## Scenario 5 — Short item skipped by semantic comparison (FR-005)

**Goal**: Confirm that items below the 20-word minimum are not subject to semantic comparison.

**Setup**: Capture a raw item with a very short body (e.g., 5–10 words). This item is not an
exact duplicate of any distilled entry.

**Run**: `/refine`

**Expected**: Item passes through 6.5c untouched (no semantic-duplicate record). It reaches
the subagent. Session output shows `Semantic duplicates: 0`.

**Pass criteria**: Short item is not suppressed by 6.5c.

---

## Scenario 6 — Session with zero semantic duplicates produces clean changelog (FR-011)

**Goal**: Confirm the `### Semantic Duplicates` subsection is absent when nothing was suppressed.

**Setup**: Run `/refine` with a batch of genuinely novel items (no paraphrases in the queue).

**Expected**: Changelog entry for the session does NOT contain `### Semantic Duplicates`.

**Pass criteria**: Changelog is clean — no empty section added.
