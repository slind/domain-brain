---
type: prd
issue: 4
---

## Problem Statement

`/refine` is slow even when processing just 2 items. A steward running a routine batch of simple `task` items waits minutes before any refinement output appears. The delay happens entirely before the subagent is invoked — in the setup phases that load context and check file sizes. The root cause is that three pipeline phases operate on the full set of distilled files and raw files regardless of what is actually in the batch.

## Solution

Three independent fixes applied to the `/refine` command, in descending impact order:

1. **Delete refined raw files** — after a raw item is processed (autonomously or via governed decision), delete the file rather than marking it `status: refined`. The raw queue scan becomes O(pending items only) instead of O(all items ever captured).

2. **Move split-check to post-session** — Step 6.2 currently runs before any items are processed and counts entries in every distilled file. Move it to run after Step 10, evaluating only the files that were actually written to during the session.

3. **Load only type-relevant distilled context in Step 6** — once the split-check no longer requires a full upfront load, Step 6 should load only the distilled files that are routing targets for the declared types present in the batch. Items declared as `mom` or `other` retain full-load as the correct fallback.

## User Stories

1. As a steward refining a 2-item `task` batch, I want the session to complete in seconds, so that the overhead of running `/refine` does not discourage frequent use.
2. As a steward, I want the raw queue directory to stay small, so that future sessions do not slow down as the project ages.
3. As a steward, I want the split-check to still fire when a distilled file genuinely exceeds its threshold, so that I am not silently accumulating oversized files.
4. As a steward, I want the split-check to trigger at the end of the session rather than the beginning, so that it only concerns itself with files that were actually changed.
5. As a steward refining a batch of `requirement` items, I want the session to load only requirements-relevant context, so that large unrelated files do not inflate the setup time.
6. As a steward refining a mixed batch of `task` and `decision` items, I want only `backlog.md`, `decisions.md`, `priorities.md`, and `identity.md` loaded, so that setup time reflects the actual scope of the batch.
7. As a steward refining a `mom` item (minutes of meeting), I want the full distilled context loaded, so that the subagent can correctly split and route knowledge across all target files.
8. As a steward, I want `other`-typed items to continue triggering a full context load, so that reclassification has the information it needs.
9. As a steward, I want deleted raw files to be reflected correctly in the session changelog, so that the audit trail is not broken by the deletion.
10. As a steward, I want the session summary to correctly count processed items even though raw files are deleted rather than marked refined, so that I can verify the session ran correctly.
11. As a steward, I want the split-check to still support Options A, B, C, and Z when it runs post-session, so that the governed decision quality is unchanged.
12. As a steward, I want the performance improvement to be invisible — the same output format, same governed decisions, same changelog — just faster.

## Implementation Decisions

### Fix 1 — Delete refined raw files

- After a raw item is fully processed (status set to `refined` in the current flow), the raw file is **deleted** using the Bash tool (`rm`).
- This applies in all paths: autonomous actions (Step 9), governed decisions (Step 10), and host pre-filter (Step 6.5).
- The item ID (filename without `.md`) continues to be recorded in the changelog as today. Deletion does not affect changelog entries.
- No index file or manifest is introduced — the raw directory itself is the queue.
- Files with `status: raw` are never deleted mid-session. Only fully-processed items are deleted.

### Fix 2 — Move split-check to post-session

- Step 6.2 is removed from its current position (between Step 6 and Step 6.5).
- A new **Step 10.5** is inserted between Step 10 (governed decision loop) and Step 11 (session end). It runs the same split-check logic, but scoped to a `touched_files` set.
- `touched_files` is populated during Steps 9 and 10: every distilled file path that receives a write (append, merge, or overwrite) is added to the set.
- The split-check reads and counts entries only for files in `touched_files`. No other distilled files are examined.
- The `config/split-thresholds.md` load moves to Step 10.5 (lazy — only read if `touched_files` is non-empty).
- Split proposals in Step 10.5 follow the same governed decision flow (Options A/B/C/Z) as the current Step 6.2.
- If `touched_files` is empty (e.g., all items were pre-filtered as exact duplicates), Step 10.5 is skipped entirely.

### Fix 3 — Type-driven context loading in Step 6

- After the raw queue is loaded (Step 4), collect the set of declared types present in the batch: `batch_types`.
- In Step 6, replace "read all files in `distilled/`" with: load only the distilled files that are routing targets for the types in `batch_types`, as defined in `config/types.yaml`.
- Additionally always load: `config/identity.md`, `config/priorities.md`, `config/similarity.md`, and `.claude/agents/refine-subagent.md` (unchanged).
- **Full-load fallback**: if `batch_types` contains any of `mom`, `other`, `stakeholder`, or any unrecognised type, load all distilled files. This matches the existing generalist cluster behaviour.
- The `config/split-thresholds.md` read is removed from Step 6 entirely (moved to Step 10.5).
- Step 6 no longer loads distilled files for the split-check — it loads only what the subagent needs.

### Interaction between fixes

Fixes 2 and 3 are independent but complementary: Fix 3 reduces Step 6 load time; Fix 2 eliminates the reason Step 6 previously loaded everything. Fix 1 is fully independent of both.

### No changes to

- The subagent instruction file (`refine-subagent.md`)
- The governed decision format or options
- The changelog format
- The session summary format
- The type routing table in Step 7
- Pre-filtering logic in Step 6.5

## Testing Decisions

Good tests verify observable external behaviour, not internal step sequencing.

**What makes a good test here**: run `/refine` against a controlled raw queue, observe timing, file-system state after the session, and changelog output. Do not test which files were loaded internally.

**Scenarios to verify manually after implementation**:

- A batch of 2 `task` items: session completes noticeably faster; raw files are deleted; `backlog.md` has new entries; no distilled files other than `backlog.md` appear in the changelog.
- A batch of 1 `mom` item: full distilled context loaded (no regression on multi-type routing); raw file deleted after processing.
- A batch that writes to a distilled file that now exceeds its split threshold: split proposal appears at end of session (post Step 10), not at the start.
- A session where all items are pre-filtered as exact duplicates: no split-check runs; raw files deleted; changelog records pre-filter outcomes.
- A mixed `requirement` + `task` batch: only `requirements-active-1.md`, `decisions.md`, `backlog.md`, `priorities.md`, and `identity.md` are loaded (verify by observing which files are read in tool calls).
- A batch containing an `other`-typed item: full distilled context loaded (fallback behaviour preserved).

**Prior art**: the existing `/refine` session run in this project serves as the baseline. Compare step-by-step tool call counts before and after.

## Out of Scope

- Splitting `refine-subagent.md` into per-specialist files — that is a maintainability change with no performance impact.
- Introducing an index file or manifest for the raw queue.
- Parallelising the subagent invocations across clusters.
- Caching distilled file content between sessions.
- Any changes to how the raw items are captured or structured.

## Further Notes

Fix 1 (delete refined files) can be shipped independently and immediately — it requires only a one-line change to each processing path (replace Edit with Bash rm). Fixes 2 and 3 are more structural but remain confined to `refine.md`. All three fixes are changes to the command file only; no other files in the system are affected.

The multi-type split case (`mom`, `other`) was specifically validated during design: these types genuinely require broad context and correctly retain the full-load path. Single-type batches — the common case for day-to-day capture — are the primary beneficiaries.
