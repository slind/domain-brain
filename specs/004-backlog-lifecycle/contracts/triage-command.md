# Contract: /triage Command

**Feature**: `004-backlog-lifecycle`
**File**: `.claude/commands/triage.md` (new)
**Date**: 2026-03-12

---

## Purpose

Single entry point for all backlog lifecycle operations: view, prioritise, start, close, drop, and maintain priority guidelines. Designed as a conversational command — one invocation, multiple user turns.

---

## Invocation

```
/triage [no arguments]
```

No arguments required. All operations are expressed in natural language after the initial display.

---

## Session Flow

```
1. LOAD      Read backlog.md; separate open+in-progress from done entries
2. DISPLAY   Numbered list — grouped by status/priority
3. PROMPT    "What would you like to do?"
4. INTERPRET Natural language intent dispatch
5. EXECUTE   Apply change(s) to backlog.md; append changelog if close/drop
6. REPORT    Confirm what changed; offer next step
```

Steps 3–6 repeat until the user exits the session or gives no further input.

---

## Display Format

```
Backlog (N open, M in-progress)

▶ In Progress:
  [1] <Title>                                      [priority]

High:
  [2] <Title>                                      [high]
  [3] <Title>                                      [high]

Medium:
  [4] <Title>                                      [medium]
  [5] <Title>                                      [medium]
  ... (N more)

Low:
  [10] <Title>                                     [low]

What would you like to do?
  "start [N]" · "set [N] to high/medium/low" · "elevate <topic>" ·
  "close [N]" · "drop [N]" · "update guidelines" · or describe
```

**Empty backlog**: Output "Backlog is empty — capture some items first with /capture" and stop.
**All done**: Output "No open items. Use 'show done' to see completed work."

---

## Intent Dispatch Table

| User intent pattern | Action | Confirmation required? |
|---|---|---|
| "set N to high/medium/low" | Direct priority: update `**Priority**` field on entry N | No |
| "elevate X" / "prioritise anything related to Y" / "focus on Z" | Hint-driven: invoke subagent → propose table → wait for confirm | Yes |
| "reprioritise everything" / "apply guidelines" | Guidelines-driven: invoke subagent with priorities.md → propose table → wait for confirm | Yes |
| "update guidelines" / "set guidelines" | Show current `config/priorities.md` + guided edit in one exchange, then write | No (edit is direct) |
| "start N" / "work on N" / "pick N" | Mark entry N `in-progress`; show item; ask "Ready to start speccing?" → on confirm auto-fire `/speckit.specify` | Yes (one confirm) |
| "close N" / "done with N" | Ask for one-line rationale → mark done → move to Done section → changelog | Yes (rationale prompt) |
| "drop N" / "remove N" / "cancel N" | Governed decision: options A (done+reason), B (de-prioritise, keep open), Z (flag as unresolved) | Yes (governed decision) |
| "show backlog" / "status" | Display only — no mutation | No |
| "show done" | List Done section | No |

---

## Priority Subagent Contract

When hint-driven or guidelines-driven re-ranking is requested, the host invokes a subagent:

**Input to subagent**:
- All open backlog entries (numbered, title, current priority, was_manual flag)
- User hint OR full content of `config/priorities.md`
- Instruction: return `PRIORITY_PROPOSAL` JSON array

**Expected output**:
```
PRIORITY_PROPOSAL:
[
  { "item_num": N, "title": "...", "current": "medium", "proposed": "high", "reason": "...", "was_manual": false }
]
```

**Host behaviour after receiving proposal**:
1. Display proposal table with ⚠ flag on was_manual items
2. Ask: "Apply these changes? (yes / no / select N,M to apply only some)"
3. On confirmation: apply only changed entries using Edit tool
4. On rejection: no writes

---

## Speckit Handoff Contract

When user says "start N":

1. Read entry N's title and body from `backlog.md`
2. Update `**Status**` from `open` to `in-progress` via Edit tool
3. Display:
   ```
   Item N marked in-progress: "<title>"

   Will start spec with:
     "<body text of entry>"

   Ready to start speccing? (yes / not yet)
   ```
4. On "yes": invoke `/speckit.specify "<body text>"` — body text becomes the feature description argument
5. On "not yet": stay in triage session; item remains `in-progress`

---

## File Writes

| Operation | File(s) modified |
|---|---|
| Direct priority change | `backlog.md` — Edit `**Priority**` field |
| Hint/guidelines re-rank (confirmed) | `backlog.md` — Edit `**Priority**` fields (batch) |
| Start item | `backlog.md` — Edit `**Status**` field |
| Close item | `backlog.md` — Edit `**Status**` + move entry to Done section; `changelog.md` — append |
| Drop item (done) | `backlog.md` — Edit `**Status**` + move entry to Done section; `changelog.md` — append |
| Drop item (keep open) | `backlog.md` — Edit `**Priority**` to `low`; `changelog.md` — append |
| Update guidelines | `config/priorities.md` — Write/Edit |

---

## Error Conditions

| Condition | Output |
|---|---|
| `backlog.md` does not exist | "backlog.md not found. Run /refine after capturing some task items." |
| Item number N out of range | "No item [N] in the current view. Use 'show backlog' to see current numbers." |
| Hint-driven subagent returns empty proposal | "No items matched that hint. Would you like to rephrase?" |
| User provides no rationale on close | Ask once; if still empty, use "no rationale provided" and proceed |
