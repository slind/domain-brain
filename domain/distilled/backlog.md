# Backlog

<!-- Actionable work items linked to requirements or domain gaps. Populated by /refine from captured 'task' items. -->

## Enterprise API Integration for /seed
**Type**: task
**Status**: open
**Priority**: low
**Captured**: 2026-03-12
**Source**: [domain-20260312-c001]

Extend `/seed` to read directly from Confluence, Notion, Jira, and SharePoint via their respective REST APIs, eliminating the current requirement for users to manually export wiki content to Markdown before seeding. This is the highest adoption friction point for teams whose knowledge lives primarily in these platforms. Feature 002 Technical Constraints explicitly deferred authenticated enterprise API sources to a future release. Implementation will require authentication handling (OAuth or API token), format normalisation from each platform's native structure into the seeding pipeline's segment model, and access-error handling consistent with the existing inaccessible-URL pattern (FR-015). Scope boundary in `config/identity.md` references this as a future feature — this task is the work item to build it.

---

## Large Domain Support — Hosted Vector Index
**Type**: task
**Status**: open
**Priority**: low
**Captured**: 2026-03-12
**Source**: [domain-20260312-c002]

Implement the hosted index retrieval strategy for domains exceeding 500 distilled entries, completing the three-tier retrieval architecture specified in FR-023 (in-context ≤50, local index 51–500, hosted index >500). Currently `/query` informs users that large domains are unsupported, making this the primary scaling ceiling for the system. ADR-003 explicitly deferred this tier to v2. Work involves selecting a hosted vector store, defining embedding and indexing strategy for distilled entries, integrating retrieval into the `/query` classification and context-assembly pipeline, and ensuring the SC-004 latency target (cited answer in under 60 seconds) still holds at scale.

---

## Cross-Domain Federation
**Type**: task
**Status**: open
**Priority**: low
**Captured**: 2026-03-12
**Source**: [domain-20260312-c003]

Design and implement a federation layer that allows `/query` to reason across multiple domain brain instances, enabling organisation-wide questions such as "who across all teams owns X?" or "which teams have open ADRs touching the payment service?". Feature 001 Assumptions explicitly scopes v1 to one domain brain per team and defers federation. This is the natural growth axis once individual domain brains are mature. Work involves defining a federation discovery mechanism (registry of domain brain locations), a cross-domain query routing protocol, result merging and attribution, and governance for cross-domain governed decisions.

---

## Automated / Event-Triggered Seeding
**Type**: task
**Status**: open
**Priority**: low
**Captured**: 2026-03-12
**Source**: [domain-20260312-c004]

Connect `/seed` to CI/CD and repository events so seeding happens automatically when knowledge-bearing artifacts change — a new ADR file committed, a PR merged with a `decisions` label, a runbook updated in the docs directory. Feature 002 Scope Boundary Decisions explicitly defers automated capture triggers from CI/CD pipelines and third-party integrations to a future release. Feature 001 Assumptions also calls this out of scope for v1. Implementation requires a webhook or pipeline step that invokes the seeding pipeline, a configuration model for specifying trigger conditions and source paths per domain, and a mechanism to queue raw items without an interactive user present.

---

## Distilled File Auto-Splitting
**Type**: task
**Status**: in-progress
**Priority**: high
**Captured**: 2026-03-12
**Source**: [domain-20260312-c007]

Implement the distilled file auto-splitting mechanism specified in Feature 001 Edge Cases: when a distilled file grows too large for reliable retrieval, the system automatically proposes a split into sub-files as a governed action requiring user confirmation before committing the restructuring. The edge case is fully specified in requirements but not implemented in any command file. Work involves defining a size/entry-count threshold for each distilled file type, implementing split-proposal logic in `/refine` or as a standalone maintenance command, and ensuring the governed-action pattern (one decision at a time, changelog entry, "flag as unresolved" option) is respected per FR-009 through FR-015.

---

## Knowledge Staleness Detection
**Type**: task
**Status**: open
**Priority**: medium
**Captured**: 2026-03-12
**Source**: [domain-20260312-c008]

Introduce a mechanism to surface distilled entries that may have become outdated, using the existing `last_updated` field on entries. No current requirement covers this gap. Options include a `/stale` check command that lists entries older than a configurable threshold, or a freshness signal appended to `/query` responses when retrieved entries are aging. This is particularly important for `responsibility`, `interface`, and `codebase` entries, which are most sensitive to organisational and architectural change. Work involves defining a staleness threshold (configurable per type), choosing the surfacing mechanism, and specifying how users act on stale entries (re-capture, archive, or mark as reviewed).

---

## Changelog / Trend Query Mode for /query
**Type**: task
**Status**: open
**Priority**: medium
**Captured**: 2026-03-12
**Source**: [domain-20260312-c009]

Add a sixth reasoning mode to `/query` — `trend-analysis` or `changelog-query` — that reasons against `changelog.md` to answer questions like "what changed this week?", "which entries have been updated most recently?", or "how many governed decisions were made in the last month?". FR-017 specifies exactly five reasoning modes; changelog content is currently not reachable through any query path despite containing a complete audit trail. Work involves defining the new mode's classification signals, specifying the retrieval pattern (changelog.md is append-only and grows unbounded — chunking or date-range filtering may be needed), and integrating it into the mode-dispatch logic in `/query`.

---

## Onboarding Briefing Command (/onboard or /tour)
**Type**: task
**Status**: open
**Priority**: medium
**Captured**: 2026-03-12
**Source**: [domain-20260312-c00a]

Implement an `/onboard` (or `/tour`) command that compiles a structured domain briefing for new team members in a single invocation: domain one-liner and pitch from `config/identity.md`, all active responsibilities, all [OPEN] ADRs from `decisions.md`, all active interface contracts, and key stakeholders. SC-008 requires that a new team member can correctly identify domain ownership, active interfaces, and unresolved decisions using queries alone — but this only works if they know which queries to ask. Work involves defining the briefing structure and retrieval scope, implementing selective loading of only the relevant distilled files, and formatting the output for a first-time reader.

---

## Multi-AI Host Support
**Type**: task
**Status**: open
**Priority**: low
**Captured**: 2026-03-12
**Source**: [domain-20260312-c00c]

Extend the command-file architecture to support AI hosts beyond Claude, realising the stated product vision in Feature 001 Technical Constraints ("the system should eventually support AI hosts beyond Claude — a stated product direction, not a current requirement"). The storage layer (Markdown with YAML frontmatter in git) is already AI-agnostic per ADR-001; the gap is the invocation mechanism, which currently relies on Claude command files and the Agent tool. Work involves abstracting the command interface so the same prompt instructions and knowledge files can be invoked by other AI assistants, defining a compatibility matrix, and identifying which built-in tool assumptions have equivalents in other host environments.

---

## Validate Feature 005 SC-001–SC-004 with Representative /refine Batch
**Type**: task
**Status**: open
**Priority**: high
**Captured**: 2026-03-16
**Source**: [domain-20260316-9d3a]

Run a representative /refine batch to validate Feature 005 success criteria: SC-001 (≥80% semantic duplicate suppression before subagent invocation), SC-002 (≥70% autonomous processing rate), SC-003 (zero false positives — no non-duplicate items suppressed), and SC-004 (session latency <60 seconds for a 10-item batch). Results should be recorded to confirm the feature meets its acceptance criteria or surface regressions.

---



## Create introduction for new users to get started
**Type**: task
**Status**: open
**Priority**: medium
**Captured**: 2026-03-16
**Source**: domain-20260316-a2e7

Provide an introduction to what domain brain is and how to use it, so that new users can get started.

---

## Move subagents to separate files for maintainability
**Type**: task
**Status**: open
**Priority**: high
**Captured**: 2026-03-16
**Source**: domain-20260316-3f9c

Make subagents explicit — move to separate files — so that they are easier to maintain by hand. This reduces the risk of accidental regressions when editing the refine command and improves the overall maintainability of the refinement pipeline.

---

## Done

## Fix Stale /refine Interface Contract — Codebase and Responsibility Specialist Routing
**Type**: task
**Status**: done
**Priority**: high
**Captured**: 2026-03-16
**Source**: [domain-20260316-f7b2]

The /refine Interface Contract in distilled/interfaces.md contains a stale routing table: both `codebase` and `responsibility` item types are listed as routing to the generalist subagent. Following Feature 006, the correct routing is: `codebase` → codebases.md + identity.md (specialist); `responsibility` → responsibilities.md (if present) + identity.md (specialist). Update the interfaces.md routing table to match the implemented Feature 006 behaviour as documented in the codebases.md distilled entry "Refine Pipeline — Type Clusters and Subagents".

---

## Implement FR-024: Distilled Entry Consistency-Check Mechanism
**Type**: task
**Status**: done
**Priority**: high
**Captured**: 2026-03-16
**Source**: [domain-20260316-c4e1]

Implement FR-024 by resolving ADR-016 and building the chosen distilled-entry consistency-check mechanism. ADR-016 (currently open) proposes three options: A — add a consistency-check phase to /refine; B — a dedicated /consistency-check command; C — a hook/git-diff-based approach. This work item covers both closing the ADR decision and delivering the resulting mechanism. Blocked until ADR-016 is resolved; resolution should be treated as the first sub-step.

---

## Additional Specialist Subagents in /refine
**Type**: task
**Status**: done
**Priority**: high
**Captured**: 2026-03-12
**Source**: [domain-20260312-c006]

Extend the specialist subagent roster beyond the three mandated by Feature 003 FR-007 (requirements, interfaces, decisions) to cover at least `codebase` and `responsibility` type clusters, which currently fall to the generalist subagent with full context loading. ADR-015 established the type-routing rules that specialist subagents rely on; this task applies that same pattern to the remaining high-volume types. Adding `codebase` and `responsibility` specialists would extend the token-efficiency gains from Feature 003 to a wider share of typical batches, directly improving SC-002 (70%+ autonomy) and SC-005 (no full-distilled-files load unless genuinely necessary).

---

## Semantic Duplicate Detection in /refine
**Type**: task
**Status**: done
**Priority**: high
**Captured**: 2026-03-12
**Source**: [domain-20260312-c005]

Upgrade the host pre-filtering stage in `/refine` from byte-for-byte exact match to semantic similarity detection, so that near-duplicate and paraphrased items are eliminated before reaching a subagent rather than consuming a governed decision. Feature 003 Design Assumptions explicitly scope pre-filtering to exact duplicates only, and the Feature 003 Edge Cases entry confirms near-duplicates intentionally pass through to the subagent. Implementing this would push the autonomous processing rate (SC-002: 70%+ target) toward the 90%+ range. Work involves choosing an embedding or similarity strategy compatible with the no-external-service constraint (or relaxing that constraint), defining a configurable similarity threshold, and extending the pre-filtering accounting to record semantic-duplicate outcomes in the session changelog.

---

## Backlog Entry Schema Migration — Existing 12 Entries
**Type**: task
**Status**: done
**Priority**: high
**Captured**: 2026-03-12
**Source**: [domain-20260312-e8f9]

Backfill all 12 existing entries in `distilled/backlog.md` to include the new `Status` and `Priority` fields introduced by Feature 004. Migration is mechanical — no normative judgment required; default priority `medium` for all pre-existing entries. This task directly enables the `/triage` command and `task-management` query mode to function correctly, as both depend on well-formed Status and Priority fields on every backlog entry.

---

## Backlog Activation and Task-Management Query Mode
**Type**: task
**Status**: done
**Priority**: high
**Captured**: 2026-03-12
**Source**: [domain-20260312-c00b]

Activate `distilled/backlog.md` as a live, queryable workflow surface by: (1) adding a `task-management` reasoning mode to `/query` (FR-017 currently lists no such mode) that can surface open tasks, filter by linked requirement or domain gap, and report task age; (2) defining lightweight lifecycle operations — a `/triage` skill to promote a backlog task to a requirement (triggering a governed decision per FR-009) or close it with a rationale. The data model and routing exist; the query support and lifecycle commands do not. Without these, `backlog.md` is a write-only log with no retrieval or workflow value.

---