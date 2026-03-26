---
type: prd
issue: 14
---

## Problem Statement

Domain Brain can capture, distil, and query discrete knowledge items — facts, decisions, requirements, responsibilities. But real domain work is not always discrete. Many of the most important questions a team faces are long-running investigations: "What should our API security model look like?", "What direction should we take with our event infrastructure?", "What does our current API landscape actually look like?" These questions cannot be answered immediately. They require collecting input from stakeholders, reviewing documentation, exploring codebases, and making a series of partial decisions over days or weeks before a final conclusion can be reached.

Currently, Domain Brain has no way to represent this kind of investigation. There is no mechanism for tracking a question over time, accumulating evidence toward its resolution, surfacing related sub-questions, or governing the graduation of conclusions into distilled domain knowledge. The `/query` command cannot answer questions about these topics precisely because they are open — the knowledge does not yet exist in the distilled files. And there is no structured way for a user and the AI to work together to close that gap.

## Solution

Introduce a new `domain:investigation:*` command namespace that models long-running domain investigations as a graph of **node files** in `domain/investigations/`. Each node is a standalone question file with its own lifecycle, a list of initiatives (actions needed to collect information), evidence links (to distilled knowledge and provisional leads), and optional parent references that place it in a larger investigation hierarchy.

Four commands cover the full investigation lifecycle:

- **`domain:investigation:capture`** (skill) — open a new investigation node or add provisional leads to an existing one; also used to explicitly link nodes the AI has missed
- **`domain:investigation:analyze-issue`** (command) — structured grill-me-style expansion of a node: the AI proposes and directly creates child nodes and initiatives with user agreement
- **`domain:investigation:resolve`** (command) — guided resolution of a node: the user and AI negotiate the conclusion, then govern what graduates into distilled files
- **`domain:investigation:query`** (command) — query across investigation material; also provides status overview of open nodes, unexpanded nodes, and resolution candidates

The distilled knowledge base remains the single source of validated domain truth. Investigation files are a separate epistemic workspace — never read by `/query`. When a node resolves, conclusions graduate into distilled files via a governed action (the same pattern as `/refine`). The `/refine` pipeline is extended with an autonomous sub-agent step that links newly distilled items to relevant open investigation nodes.

The installer is updated to include all new commands, skills, agents, and the `domain/investigations/` directory scaffold.

## User Stories

1. As a domain steward, I want to open a new investigation node with a single question, so that I can begin tracking a long-running domain unknown.
2. As a domain steward, I want to open a set of related questions in one invocation, so that the AI can silently create the investigation hierarchy without me having to structure it manually.
3. As a domain steward, I want to see all existing investigation nodes before a new one is created, so that I can make an informed decision about whether my question is already tracked or should be attached as a child of an existing node.
4. As a domain steward, I want to explicitly link two investigation nodes, so that I can correct a relationship the AI missed.
5. As a domain steward, I want to add provisional leads and notes directly to an investigation node, so that they are available during resolution without polluting the distilled knowledge base.
6. As a domain steward, I want to run an analyze-issue session on a node, so that the AI helps me identify what child nodes and initiatives are needed to resolve it.
7. As a domain steward, I want the AI to propose and immediately create child nodes and initiatives during an analyze-issue session, so that I do not have to run separate capture commands after the dialogue.
8. As a domain steward, I want to know which investigation nodes have never had an analyze-issue session, so that I can identify nodes that have not yet been expanded.
9. As a domain steward, I want to run multiple analyze-issue sessions on a single node over time, so that the investigation hierarchy can evolve as new information arrives.
10. As a domain steward, I want to re-classify an initiative as a child node (and vice versa), so that the investigation hierarchy can be restructured as understanding deepens.
11. As a domain steward, I want the AI to surface investigation nodes that are candidates for resolution, so that I know when a node has collected enough evidence to be concluded.
12. As a domain steward, I want to resolve a node by stating my conclusion directly, so that the AI can figure out what supporting context needs to accompany it into distilled files.
13. As a domain steward, I want to resolve a node through a negotiated dialogue with the AI, so that we can arrive at a conclusion together based on the collected evidence.
14. As a domain steward, I want rejected alternatives to be recorded in an ADR when a node resolves, so that future queries can explain why certain directions were not taken.
15. As a domain steward, I want each ADR produced during node resolution to be appended to `decisions.md` via the normal governed action pattern, so that the quality gate is respected.
16. As a domain steward, I want confirmed findings from a resolved node to be distilled into requirements, responsibilities, interfaces, or other appropriate files, so that future `/query` invocations can answer questions about this topic.
17. As a domain steward, I want a node to remain as a historical record in `domain/investigations/` after resolution, so that the investigation process is preserved for future reference.
18. As a domain steward, I want the same investigation node to appear as a child of multiple parent nodes, so that questions relevant to more than one investigation are not duplicated.
19. As a domain steward, I want to fully resolve a child node while parent nodes remain open, so that progress can be made incrementally without waiting for the entire investigation to complete.
20. As a domain steward, I want to force-close a node at any time regardless of whether all child nodes and initiatives are complete, so that I am not blocked by the automated resolution condition.
21. As a domain steward, I want to query what Domain Brain knows about a specific investigation node, so that I can get a compiled view of current evidence, open sub-questions, and initiative status.
22. As a domain steward, I want the query to clearly label which parts of the answer come from validated distilled knowledge vs. provisional leads, so that I always know the epistemic status of the information.
23. As a domain steward, I want to ask "what investigations are open?" and get a structured overview, so that I can see the current state of all active investigations without reading individual files.
24. As a domain steward, I want to ask "which nodes are ready to resolve?" and get a list of candidates, so that I can prioritise resolution sessions efficiently.
25. As a domain steward, I want newly distilled items (from `/capture` and `/refine`) to be automatically linked to relevant open investigation nodes, so that I do not have to manually connect domain knowledge to investigations.
26. As a domain steward, I want uncertain automatic links to surface as governed decisions in `/refine`, so that I can confirm or reject them before they are written.
27. As a domain steward, I want to indicate in the body of a capture that it relates to a specific investigation, so that the link is always created regardless of the AI's semantic confidence.
28. As a new Domain Brain user installing the system, I want all investigation commands, skills, and directory scaffolding to be included in the installer, so that investigation support is available immediately after installation.
29. As a domain steward, I want each investigation node to have a unique, human-readable ID, so that I can reference nodes explicitly in commands and in discussion.
30. As a domain steward, I want the investigation node ID to carry a user-provided prefix and an auto-assigned sequence number, so that I can group related nodes by topic area.

## Implementation Decisions

### New directory: `domain/investigations/`
- One Markdown file per investigation node
- Committed to git — investigations are long-running and must survive across sessions
- Directory created by the installer on fresh install and `--update`

### Node file schema
Each node file contains YAML frontmatter and Markdown body:
- Frontmatter fields: `id`, `status` (open | blocked | resolved), `expanded` (boolean), `opened` (date), `parents` (list of node IDs, empty = root node)
- Body sections: question (h1 title), Initiatives (checklist), Evidence (bullet list with `[distilled]` or `[lead]` prefix), Child Nodes (informational, discovered by scan), Resolution (filled on close)
- Child nodes are implicit — discovered by scanning all node files for parent references; not listed explicitly in the parent file

### Node ID format
- User provides a short prefix at capture time (e.g. `SEC`, `API`, `ARCH`)
- AI assigns the next number in that series by scanning existing files
- Default prefix `INV` if none provided
- Format: `{PREFIX}-{NNN}` (e.g. `SEC-001`, `API-003`)

### Node lifecycle states
- `open` — active, being worked
- `blocked` — waiting on initiative completion or external input
- `resolved` — concluded; Resolution section filled; ADRs referenced

### `expanded` flag
- Set to `false` on creation
- Set to `true` after a `domain:investigation:analyze-issue` session completes
- Enables `domain:investigation:query` to surface "nodes that have never been expanded"

### Resolution candidacy condition
A node is surfaced as a resolution candidate when all child nodes are resolved AND all initiatives are checked. This is advisory — user can resolve at any time.

### `domain:investigation:capture` (skill)
- Detects three cases from input: new node(s), add leads to existing node, explicit link between nodes
- For new node: scans `domain/investigations/` for semantic overlap; presents matching nodes with full content for informed user decision (attach as child / create as root / already exists)
- For multi-question input: AI silently creates hierarchy as it deems logical; all nodes created with `expanded: false`
- For explicit link: updates both node files to reflect the declared relationship
- Belongs in `.claude/skills/domain-investigation-capture/` following the skill pattern

### `domain:investigation:analyze-issue` (command)
- Takes a node ID as argument
- Structured grill-me-style dialogue targeting the specified node
- AI proposes additional child nodes and initiatives based on the question and existing evidence
- User agrees or negotiates; AI directly creates proposed child node files and updates the initiative checklist
- Marks node `expanded: true` on session completion
- Multiple sessions per node are valid and expected
- Hierarchy re-negotiation (initiative ↔ child node) is explicitly supported

### `domain:investigation:resolve` (command)
- Takes a node ID as argument
- Two resolution entry paths:
  1. User states conclusion → AI identifies what supporting context needs to accompany it into distilled files
  2. User + AI negotiate conclusion via structured dialogue based on collected evidence
- Exit flow (both paths):
  - AI proposes distillation targets: ADR(s) for decisions + rejected alternatives, requirements, responsibilities, etc.
  - User confirms each piece via governed action pattern (same as `/refine`)
  - ADRs appended to `decisions.md`
  - Other findings routed to appropriate distilled files
  - Node status set to `resolved`; Resolution section filled with conclusion summary and ADR references
- Node file is retained as historical record after resolution

### `domain:investigation:query` (command)
- Reads `domain/investigations/` files directly (unlike `/query` which never reads investigation files)
- For topic queries: compiles evidence from matching node(s) and their descendants; labels each claim as `[distilled]` or `[lead]`
- For status queries ("what's open", "what's unexpanded", "what's ready to resolve"): scans all node files and produces structured overview
- Never modifies files

### `/refine` — investigation-linking sub-agent
- New autonomous sub-agent step added after normal type routing
- Reads all open (`status: open | blocked`) investigation node files
- For each newly distilled item, evaluates semantic relevance to open nodes using LLM judgment
- High-confidence match → autonomously appends `[distilled]` evidence link to node file
- Uncertain match → surfaces as governed decision
- Explicit indication in capture body (e.g. mentioning a node ID or investigation topic) → link always created, confidence threshold bypassed
- Cost scales with number of open investigation nodes; acceptable for typical usage

### New `investigation` type in `config/types.yaml`
- `routes_to: investigations/` (marks items that should become investigation nodes)
- Used by `/refine` to route `type: investigation` raw items to the investigation pipeline rather than distilled files

### Installer updates (`install.sh`)
The following additions are required in both fresh install and `--update` modes:
- New commands: `domain:investigation:analyze-issue.md`, `domain:investigation:resolve.md`, `domain:investigation:query.md`
- New skill directory: `domain-investigation-capture/`
- New agent (if a dedicated investigation sub-agent is needed for resolve/analyze)
- New scaffold directory: `domain/investigations/` (created empty on install)
- `config/types.yaml` updated to include `investigation` type (applied on `--update` only if not already present)

### Graph properties and circular references
- Node graph is a DAG in the intended design but circular references are accepted as a known limitation
- No cycle detection required in v1
- Commands that traverse parent/child chains should implement a visited-node guard to avoid infinite loops

## Testing Decisions

Good tests for this feature test external behaviour — what the commands produce in the filesystem and what they output to the user — not internal parsing or file-reading logic.

### What makes a good test
- Given a set of existing node files, verify that a command produces the expected new or modified files
- Verify that the correct governed decisions are surfaced and that file writes only happen after confirmation
- Verify that `/query` responses correctly label distilled vs. lead sources
- Do not test intermediate state or subagent prompt construction

### Modules to test
- Node file creation (capture): correct frontmatter, correct parent references, correct ID assignment
- Hierarchy creation from multi-question input: expected parent/child structure produced
- Analyze-issue: child nodes and initiatives are created in node file when user agrees
- Resolve: node file updated to `resolved`, ADR appended to `decisions.md`, other findings routed correctly
- Investigation-linking sub-agent in `/refine`: newly distilled item produces evidence link in correct node file
- Query status: unexpanded nodes, resolution candidates, open investigations correctly identified

### Prior art
- Existing `/refine` integration tests for governed decision pattern
- `domain:triage` tests for status lifecycle (open → in-progress → done) as a model for node lifecycle

## Out of Scope

- **GitHub issue integration per investigation node** — deferred to a future iteration. Each node will not automatically create a corresponding GitHub issue in this version.
- **Vector database for semantic linking** — LLM-based semantic judgment is used throughout. A vector store may be reconsidered if investigation counts grow large.
- **`/query` reading investigation files** — the main `/query` command is deliberately scoped to validated distilled knowledge only. Investigation-scoped queries go through `domain:investigation:query`.
- **Automated resolution** — the system surfaces resolution candidates but never closes a node without explicit user action.
- **Cross-domain investigation federation** — investigation nodes are scoped to a single domain brain instance.
- **Investigation templates** — predefined investigation structures for common domain questions (e.g. "API landscape audit") are not included in v1.

## Further Notes

- **Epistemic separation is the core architectural invariant.** Investigation files are a working-memory workspace. Distilled files are validated facts. This boundary must be respected by every command — particularly that `domain:investigation:query` labels its sources and that `/query` never crosses into investigation files.
- **Rejected alternatives are not waste — they are knowledge.** The ADR that closes a node should always include the options that were considered and rejected, with reasoning. This makes future queries about "why didn't we do X" answerable.
- **The investigation graph is intentionally flexible.** Circular references are accepted. Multi-parent nodes are expected. The hierarchy will be renegotiated as understanding deepens. Commands that traverse the graph must guard against infinite loops.
- **When writing skills in this feature, consult the `write-a-skill` skill** for guidance on robust skill structure, progressive disclosure, and bundled resources.
- **The `expanded` flag is a navigation aid, not a quality gate.** A node can be resolved without ever being expanded. The flag exists only to help the steward find nodes that haven't been thought through yet.
