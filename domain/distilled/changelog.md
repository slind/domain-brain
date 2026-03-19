# Changelog

<!-- Audit trail of all refine sessions and minutes of meeting. Appended by /refine at the end of every session. -->

## 2026-03-19 — Refine Session

### Autonomous actions
- [aggregate]: domain-20260319-c4f1 → aggregated per-project installation specifics (installer components, parallel instances, commands/skills split) into existing requirement "Domain Brain Must Be Installable in Any Project" in requirements-active-1.md

### Governed decisions
- domain-20260319-e7b2: new_adr_candidate → ADR-020 written (commands vs. skills split)
  Decided by: Søren Lindstrøm | Rationale: "A" (accepted as proposed)

---

## 2026-03-19 — Consistency Check Session

No stale entries found. All tracked entries are current.

### README
- [readme]: domain/README.md → updated (18 interfaces, 5 priorities)

---

## 2026-03-18 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260318-1a2b → requirements-active-1.md (Feature 001 explicit-subagents US1)
- [route_and_summarise]: domain-20260318-2c3d → requirements-active-1.md (Feature 001 explicit-subagents US2)
- [route_and_summarise]: domain-20260318-3e4f → requirements-active-1.md (Feature 001 explicit-subagents US3)
- [route_and_summarise]: domain-20260318-3f7c → requirements-active-1.md (Domain Brain Must Be Installable in Any Project)
- [route_and_summarise]: domain-20260318-4a5b → requirements-active-1.md (Feature 001 explicit-subagents edge cases)
- [route_and_summarise]: domain-20260318-5c6d → requirements-active-1.md (Feature 001 explicit-subagents FR-001–FR-006)
- [route_and_summarise]: domain-20260318-6e7f → requirements-active-1.md (Feature 001 explicit-subagents technical constraints)
- [route_and_summarise]: domain-20260318-8c9d → requirements-active-1.md (Feature 001 explicit-subagents SC-001–SC-004)
- [route_and_summarise]: domain-20260318-e9fa → requirements-active-1.md (Feature 001 explicit-subagents data model invariants)
- [route_and_summarise]: domain-20260318-7a8b → codebases.md (Explicit Subagents — Key Entities)
- [route_and_summarise]: domain-20260318-b3c4 → codebases.md (Explicit Subagents — .claude/ Directory Structure)
- [route_and_summarise]: domain-20260318-c5d6 → codebases.md (refine.md explicit subagents modifications)
- [route_and_summarise]: domain-20260318-d7e8 → codebases.md (refine-subagent.md subagent instruction file)
- [route_and_summarise]: domain-20260318-9e0f → decisions.md (Design Assumptions — Feature 001 Explicit Subagents)
- [route_and_summarise]: domain-20260318-a1b2 → decisions.md (Design Clarifications — Feature 001 Explicit Subagents)

### Governed decisions
- domain-20260318-a4f2: Multi-AI support — normative MUST vs. product direction → captured as product direction (option B); v1 Claude-first deferral preserved
  Decided by: Søren Lindstrøm | Rationale: "B"

---

## 2026-03-16 — Refine Session

### Semantic Duplicates
- [semantic_duplicate]: domain-20260316-7a1b → archived
  Matched: Feature 007 done backlog entry + ADR-018
  Basis: both describe the fix of stale codebase/responsibility routing rows in interfaces.md
- [semantic_duplicate]: domain-20260316-8b1c → archived
  Matched: /consistency-check Interface Contract (interfaces.md)
  Basis: both describe the /consistency-check command overview and purpose
- [semantic_duplicate]: domain-20260316-8b2d → archived
  Matched: /consistency-check Interface Contract — staleness detection logic
  Basis: both describe the user story for detecting stale distilled entries
- [semantic_duplicate]: domain-20260316-8b3e → archived
  Matched: /consistency-check Interface Contract — resolution flow
  Basis: both describe the user story for acting on a staleness report
- [semantic_duplicate]: domain-20260316-8b4f → archived
  Matched: /consistency-check Interface Contract — edge case coverage
  Basis: both enumerate edge cases for the consistency-check mechanism
- [semantic_duplicate]: domain-20260316-9c4a → archived
  Matched: Describes-Link Convention (codebases.md)
  Basis: both describe the opt-in **Describes** field convention for linking distilled entries to source files

### Autonomous actions
- [route_and_summarise]: domain-20260316-7a2c, 7a3d, 7a4e, 7a5f, 7a6a → Feature 007 — Fix Stale /refine Interface Contract Routing Table appended to requirements.md
- [route_and_summarise]: domain-20260316-8b5a, 8b6b, 8b8d, 8b9e → Feature 008 — Consistency-Check Mechanism appended to requirements.md
- [archive_only]: domain-20260316-8b7c → Key Entities summary superseded by detailed entity definitions in 9c1d/9c2e/9c3f
- [classify_and_route]: domain-20260316-9c1d → reclassified requirement→codebase; Staleness Candidate entity appended to codebases.md
- [classify_and_route]: domain-20260316-9c2e → reclassified requirement→codebase; Staleness Resolution entity appended to codebases.md
- [classify_and_route]: domain-20260316-9c3f → reclassified requirement→codebase; ConsistencyCheckSession entity appended to codebases.md
- [aggregate]: domain-20260316-9c5b → Changelog Entry Format subsection added to /consistency-check Interface Contract in interfaces.md

---

<!-- Session format:
## YYYY-MM-DD — Refine Session

### Autonomous actions
- [action]: [item-id] → [description]

### Governed decisions
- [item-id]: [topic] → [outcome]
  Decided by: <user> | Rationale: "[rationale]"

---
-->

## 2026-03-16 — Triage Session

### Closed
- [close]: domain-20260316-c4e1 → Implement FR-024: Distilled Entry Consistency-Check Mechanism
  Rationale: "Feature implemented"
- [close]: domain-20260316-f7b2 → Fix Stale /refine Interface Contract — Codebase and Responsibility Specialist Routing
  Rationale: "Feature implemented"

---

## 2026-03-06 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260306-a1b2 → ADR-001: Delivery Mechanism → decisions.md
- [route_and_summarise]: domain-20260306-c3d4 → ADR-002: Hot-Reload for types.yaml → decisions.md
- [route_and_summarise]: domain-20260306-e5f6 → ADR-003: Retrieval Strategy by Domain Size → decisions.md
- [route_and_summarise]: domain-20260306-a7b8 → ADR-004: Refine Subagent Pattern → decisions.md
- [route_and_summarise]: domain-20260306-c9d0 → ADR-005: Large Document Chunking → decisions.md
- [route_and_summarise]: domain-20260306-e1f2 → ADR-006: Domain Brain Instance Layout → decisions.md
- [route_and_summarise]: domain-20260306-a3b4 → ADR-007: Raw Item Filename Convention → decisions.md
- [route_and_summarise]: domain-20260306-c5d6 → ADR-008: Command File Patterns → decisions.md
- [route_and_summarise]: domain-20260306-f7e8 → ADR-009: /frame Collection UX — Template-Fill Pattern → decisions.md
- [route_and_summarise]: domain-20260306-b9c0 → ADR-010: config/identity.md File Schema → decisions.md
- [route_and_summarise]: domain-20260306-d1e2 → ADR-011: /seed Resume Logic → decisions.md
- [route_and_summarise]: domain-20260306-f3a4 → ADR-012: Cap Applies to Raw Items Created → decisions.md
- [route_and_summarise]: domain-20260306-b5c6 → ADR-013: /refine Identity Context Injection → decisions.md
- [route_and_summarise]: domain-20260306-d7e8 → ADR-014: /query Identity Framing — Step 2.5 → decisions.md
- [route_and_summarise]: domain-20260306-a9b0 → Raw Item entity definition → codebases.md
- [route_and_summarise]: domain-20260306-c1d2 → Type Registry entity definition → codebases.md
- [route_and_summarise]: domain-20260306-e3f4 → Distilled Entry entity definition → codebases.md
- [route_and_summarise]: domain-20260306-a5b6 → Changelog Entry entity definition → codebases.md
- [route_and_summarise]: domain-20260306-c7d8 → Large Document Index entity definition → codebases.md
- [route_and_summarise]: domain-20260306-e9f0 → Knowledge Chunk entity definition → codebases.md
- [route_and_summarise]: domain-20260306-b1c2 → Domain Identity entity definition → codebases.md
- [route_and_summarise]: domain-20260306-d3e4 → Seeded Raw Item entity definition → codebases.md
- [route_and_summarise]: domain-20260306-f5a6 → Seed Session entity definition → codebases.md

---

## 2026-03-06 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260306-aa1b → /capture Interface Contract consolidated from 6 items → interfaces.md
- [aggregate]: domain-20260306-aa2c → merged into /capture Interface Contract
- [aggregate]: domain-20260306-aa3d → merged into /capture Interface Contract
- [aggregate]: domain-20260306-aa4e → merged into /capture Interface Contract
- [aggregate]: domain-20260306-aa5f → merged into /capture Interface Contract
- [aggregate]: domain-20260306-aa6a → merged into /capture Interface Contract
- [route_and_summarise]: domain-20260306-ab1c → /refine Interface Contract consolidated from 10 items → interfaces.md
- [aggregate]: domain-20260306-ab2d → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ab3e → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ab4f → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ab5a → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ab6b → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ac1d → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ac2e → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ac3f → merged into /refine Interface Contract
- [aggregate]: domain-20260306-ac4a → merged into /refine Interface Contract
- [route_and_summarise]: domain-20260306-ad1e → /query Interface Contract consolidated from 4 items → interfaces.md
- [aggregate]: domain-20260306-ad2f → merged into /query Interface Contract
- [aggregate]: domain-20260306-ad3a → merged into /query Interface Contract
- [aggregate]: domain-20260306-ad4b → merged into /query Interface Contract
- [route_and_summarise]: domain-20260306-ae1a → /frame Interface Contract consolidated from 6 items → interfaces.md
- [aggregate]: domain-20260306-ae2b → merged into /frame Interface Contract
- [aggregate]: domain-20260306-ae3c → merged into /frame Interface Contract
- [aggregate]: domain-20260306-ae4d → merged into /frame Interface Contract
- [aggregate]: domain-20260306-ae5e → merged into /frame Interface Contract
- [aggregate]: domain-20260306-ae6f → merged into /frame Interface Contract
- [route_and_summarise]: domain-20260306-af1a → /seed Interface Contract consolidated from 8 items → interfaces.md
- [aggregate]: domain-20260306-af2b → merged into /seed Interface Contract
- [aggregate]: domain-20260306-af3c → merged into /seed Interface Contract
- [aggregate]: domain-20260306-af4d → merged into /seed Interface Contract
- [aggregate]: domain-20260306-af5e → merged into /seed Interface Contract
- [aggregate]: domain-20260306-af6f → merged into /seed Interface Contract
- [aggregate]: domain-20260306-af7a → merged into /seed Interface Contract
- [aggregate]: domain-20260306-af8b → merged into /seed Interface Contract

---

## 2026-03-06 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260306-b0c1, d2e3, f4a5, b6c7, d8e9 → Feature 001 User Stories (US1–US5) → requirements.md
- [route_and_summarise]: domain-20260306-f0a1 → Feature 001 Edge Cases → requirements.md
- [route_and_summarise]: domain-20260306-b8c9 → Feature 001 Technical Constraints → requirements.md
- [route_and_summarise]: domain-20260306-b2c3 → Feature 001 FR: Capture (FR-001–FR-007) → requirements.md
- [route_and_summarise]: domain-20260306-d4e5 → Feature 001 FR: Refine (FR-008–FR-015) → requirements.md
- [route_and_summarise]: domain-20260306-f6a7 → Feature 001 FR: Query/Reason (FR-016–FR-023) → requirements.md
- [route_and_summarise]: domain-20260306-f2a3 → Feature 001 Success Criteria (SC-001–SC-008) → requirements.md
- [route_and_summarise]: domain-20260306-b4c5 → Feature 001 Assumptions → requirements.md
- [route_and_summarise]: domain-20260306-e1f2, e3f4, e5f6, e7f8 → Feature 002 User Stories (US1–US4) → requirements.md
- [route_and_summarise]: domain-20260306-e9fa → Feature 002 Edge Cases → requirements.md
- [route_and_summarise]: domain-20260306-f5f6 → Feature 002 Technical Constraints → requirements.md
- [route_and_summarise]: domain-20260306-edee → Feature 002 FR: /frame (FR-001–FR-006) → requirements.md
- [route_and_summarise]: domain-20260306-eff0 → Feature 002 FR: /seed (FR-007–FR-015) → requirements.md
- [route_and_summarise]: domain-20260306-f1f2 → Feature 002 FR: /refine enhancements (FR-016–FR-019) → requirements.md
- [route_and_summarise]: domain-20260306-f3f4 → Feature 002 FR: /query enhancements (FR-020–FR-022) → requirements.md
- [route_and_summarise]: domain-20260306-f9fa → Feature 002 Success Criteria (SC-001–SC-006) → requirements.md
- [route_and_summarise]: domain-20260306-fbfc → Feature 002 Assumptions → requirements.md
- [route_and_summarise]: domain-20260306-d6e7 → Design Clarifications Feature 001 session → decisions.md
- [route_and_summarise]: domain-20260306-ebec → Design Clarifications Feature 002 session → decisions.md
- [route_and_summarise]: domain-20260306-fdfe → Feature 002 Explicit Scope Boundary Decisions → decisions.md
- [archive_only]: domain-20260306-d0e1 → Key Entities (spec 001) fully covered by existing codebases.md entries
- [archive_only]: domain-20260306-f7f8 → Key Entities (spec 002) fully covered by existing codebases.md entries

---

## 2026-03-06 — Refine Session

### Autonomous actions
- [out_of_scope]: domain-20260306-c8d9 → archived; matched out-of-scope term "Enterprise API integrations (Confluence REST, Notion API — future feature)"; Jira API / MCP integration for external requirements sync

### Governed decisions
- domain-20260306-e5f6: future requirement (multi-AI host support) → aggregated into Feature 001 Technical Constraints in requirements.md as a product vision note
  Decided by: Søren Lindstrøm | Rationale: "Vision statement, not materialized into a requirement yet — its main purpose is to guide the direction of this application."

---

## 2026-03-06 — Refine Session

### Governed decisions
- domain-20260306-b3c4: new_adr_candidate (type-aware context loading in /refine Step 6) → ADR-015 [RESOLVED] written to decisions.md, option A (selective load by routes_to)
  Decided by: Søren Lindstrøm | Rationale: "A"
- domain-20260306-d5e6: new requirement (token efficiency in context loading) → FR-024 added to requirements.md as cross-cutting quality requirement
  Decided by: Søren Lindstrøm | Rationale: "A"

---

## 2026-03-12 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260312-a3f1, b7c2, d9e4 → Feature 003 User Stories (US1–US3) → requirements.md
- [route_and_summarise]: domain-20260312-2f5a → Feature 003 Edge Cases → requirements.md
- [route_and_summarise]: domain-20260312-4e1d → Feature 003 Technical Constraints → requirements.md
- [route_and_summarise]: domain-20260312-8c6b → Feature 003 Functional Requirements (FR-001–FR-014) → requirements.md
- [route_and_summarise]: domain-20260312-3b9c → Feature 003 Success Criteria (SC-001–SC-005) → requirements.md
- [route_and_summarise]: domain-20260312-7d2e → Design Assumptions Feature 003 session → decisions.md
- [aggregate]: domain-20260312-5f3b → updated /capture Interface Contract type inference section with 3-phase signal-table approach → interfaces.md
- [aggregate]: domain-20260312-0c4a → added Specialist Routing table to /refine Interface Contract → interfaces.md
- [split]: domain-20260312-f0a7 → new entry "Refine Pipeline — Type Clusters and Subagents" (Type cluster, Specialist subagent, Generalist subagent); pre-existing entity references archived → codebases.md
- [aggregate]: domain-20260312-a1b3 → extended Raw Item entry with pre-filter status transition table → codebases.md
- [archive_only]: domain-20260312-c5d7 → trivially implied by existing Distilled Entry documentation; no new information added
- [route_and_summarise]: domain-20260312-e2f9 → PreFilterResult entity definition → codebases.md
- [route_and_summarise]: domain-20260312-4a8c → TypeClusterBatch entity definition → codebases.md
- [route_and_summarise]: domain-20260312-6b2d → SpecialistPlan entity definition → codebases.md
- [route_and_summarise]: domain-20260312-9e1f → MergedRefinePlan entity definition → codebases.md

---

## 2026-03-12 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260312-c001 → Enterprise API Integration for /seed → backlog.md
- [route_and_summarise]: domain-20260312-c002 → Large Domain Support — Hosted Vector Index → backlog.md
- [route_and_summarise]: domain-20260312-c003 → Cross-Domain Federation → backlog.md
- [route_and_summarise]: domain-20260312-c004 → Automated / Event-Triggered Seeding → backlog.md
- [route_and_summarise]: domain-20260312-c005 → Semantic Duplicate Detection in /refine → backlog.md
- [route_and_summarise]: domain-20260312-c006 → Additional Specialist Subagents in /refine → backlog.md
- [route_and_summarise]: domain-20260312-c007 → Distilled File Auto-Splitting → backlog.md
- [route_and_summarise]: domain-20260312-c008 → Knowledge Staleness Detection → backlog.md
- [route_and_summarise]: domain-20260312-c009 → Changelog / Trend Query Mode for /query → backlog.md
- [route_and_summarise]: domain-20260312-c00a → Onboarding Briefing Command (/onboard or /tour) → backlog.md
- [route_and_summarise]: domain-20260312-c00b → Backlog Activation and Task-Management Query Mode → backlog.md
- [route_and_summarise]: domain-20260312-c00c → Multi-AI Host Support → backlog.md

---

## 2026-03-12 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260312-b1a2, c3d4, d5e6, e7f8, f9a1, a2b3 → Feature 004 User Stories (US1–US6) → requirements.md
- [route_and_summarise]: domain-20260312-b4c5 → Feature 004 Edge Cases → requirements.md
- [route_and_summarise]: domain-20260312-c6d7 → Feature 004 FR: /triage Command (FR-001–FR-011) → requirements.md
- [route_and_summarise]: domain-20260312-d8e9 → Feature 004 FR: Priority Guidelines (FR-012–FR-014) → requirements.md
- [route_and_summarise]: domain-20260312-e1f2 → Feature 004 FR: /refine Integration (FR-015–FR-016) → requirements.md
- [route_and_summarise]: domain-20260312-f3a4 → Feature 004 FR: /query Integration (FR-017–FR-019) → requirements.md
- [route_and_summarise]: domain-20260312-a5b6 → Feature 004 FR: Backlog Entry Schema (FR-020–FR-022) → requirements.md
- [route_and_summarise]: domain-20260312-e4f5 → Feature 004 Success Criteria (SC-001–SC-007) → requirements.md
- [route_and_summarise]: domain-20260312-f6a7, a8b9, b1c2, c3d5, d6e7 → /triage Backlog Lifecycle Data Model (5 entities) → interfaces.md
- [route_and_summarise]: domain-20260312-b7c8, c9d1, d2e3 → Design Clarifications Feature 004 session → decisions.md
- [route_and_summarise]: domain-20260312-e8f9 → Backlog Entry Schema Migration task (priority: high) → backlog.md

---

## 2026-03-13 — Triage Session

### Closed
- [close]: domain-20260312-e8f9 → Backlog Entry Schema Migration — Existing 12 Entries
  Rationale: "All 12 entries already carry Status and Priority fields — migration complete."
- [close]: domain-20260312-c005 → Semantic Duplicate Detection in /refine
  Rationale: "Task implemented"
- [close]: domain-20260312-c006 → Additional Specialist Subagents in /refine
  Rationale: "The feature has been implemented"

---

## 2026-03-13 — Refine Session

### Semantic Duplicates
- [semantic_duplicate]: domain-20260313-c001 → archived
  Matched: Feature 001 — User Stories (US1–US5) — US2 acceptance scenario 1
  Basis: both describe that /refine archives duplicate items without requiring human input

### Autonomous actions
- [route_and_summarise]: domain-20260313-a001, a002, a003 → Feature 005 User Stories (US1–US3) → requirements.md
- [route_and_summarise]: domain-20260313-a004 → Feature 005 Edge Cases → requirements.md
- [route_and_summarise]: domain-20260313-a005, a006 → Feature 005 Functional Requirements (FR-001–FR-012) → requirements.md
- [route_and_summarise]: domain-20260313-a007, a008 → Feature 005 Technical Constraints, Key Entities, and Success Criteria → requirements.md
- [route_and_summarise]: domain-20260313-b001 → config/similarity.md interface contract → interfaces.md
- [aggregate]: domain-20260313-b002 → extended PreFilterResult with semantic_duplicate fields → codebases.md
- [aggregate]: domain-20260313-b003 → extended /refine Interface Contract changelog format with Semantic Duplicates subsection → interfaces.md
- [route_and_summarise]: domain-20260313-b004 → SimilarityConfig entity → codebases.md
- [route_and_summarise]: domain-20260313-a009 → Design Assumptions Feature 005 session → decisions.md

### Governed decisions
- domain-20260313-c2d4: new_adr_candidate (governance of priority guideline changes) → ADR-016 [RESOLVED] written to decisions.md, option A (full ADR logging)
  Decided by: Søren Lindstrøm | Rationale: "the priorities file controls the general direction that the domain takes. It guides the AI's automated decision and severely impacts priorities."

---

## 2026-03-13 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260313-3c4d, domain-20260313-5e6f, domain-20260313-7a8b → Feature 006 User Stories (US1–US3) appended to requirements.md (requirements specialist)
- [route_and_summarise]: domain-20260313-9c0d → Feature 006 Edge Cases appended to requirements.md (requirements specialist)
- [route_and_summarise]: domain-20260313-b1e2 → Feature 006 Functional Requirements FR-001–FR-009 appended to requirements.md (requirements specialist)
- [route_and_summarise]: domain-20260313-c3f4 → Feature 006 Technical Constraints appended to requirements.md (requirements specialist)
- [route_and_summarise]: domain-20260313-e7b8 → Feature 006 Success Criteria SC-001–SC-004 appended to requirements.md (requirements specialist)
- [route_and_summarise]: domain-20260313-1a2b → ADR-017 [RESOLVED] written to decisions.md (decisions specialist)
- [route_and_summarise]: domain-20260313-f9c0 → Design Assumptions Feature 006 appended to decisions.md (decisions specialist)

### Governed decisions
- domain-20260313-d5a6: type_ambiguous → routed to codebases.md as data model update; "Refine Pipeline — Type Clusters and Subagents" entry updated to reflect five specialist clusters and context file set table
  Decided by: user | Rationale: "B" (retype as codebase, route to codebases.md)

---

## 2026-03-17 — Refine Session

### File Splits
- [split]: requirements.md → requirements-active-1.md (27 entries), requirements-archived-1.md (26 entries)
  Rationale: "File has grown too large"

### Autonomous actions
- [route_and_summarise]: domain-20260317-a1b2 → Command Namespace Prefix for Domain Brain Extensions (priority: medium) → backlog.md

---

## 2026-03-16 — Refine Session

### Governed decisions
- domain-20260316-a8e2 + domain-20260316-c4f1: new_requirement → merged into FR-024 (Distilled Entry Consistency with Implementation) in requirements.md
  Decided by: Søren Lindstrøm | Rationale: "A" — accept merge of both items into single requirement
- domain-20260316-c4f1: new_adr_candidate → ADR-016 created [OPEN] — mechanism for keeping distilled entries consistent with implementation changes
  Decided by: Søren Lindstrøm | Rationale: "Z" — This is just a requirement and the refine-detection is just an idea. The mechanism is deferred to when we add items/tasks to the backlog that addresses this requirement.

---

## 2026-03-16 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260316-9d3a → Validate Feature 005 SC-001–SC-004 with Representative /refine Batch (priority: high) → backlog.md
- [route_and_summarise]: domain-20260316-c4e1 → Implement FR-024: Distilled Entry Consistency-Check Mechanism (priority: high) → backlog.md
- [route_and_summarise]: domain-20260316-f7b2 → Fix Stale /refine Interface Contract — Codebase and Responsibility Specialist Routing (priority: high) → backlog.md

---

## 2026-03-16 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260316-a2e7 → Create introduction for new users to get started (priority: medium) → backlog.md
- [route_and_summarise]: domain-20260316-3f9c → Move subagents to separate files for maintainability (priority: high) → backlog.md

---

## 2026-03-17 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260316-4c5d → Feature 009 User Story 1: Detect an Oversized Distilled File → requirements.md
- [route_and_summarise]: domain-20260316-6e7f → Feature 009 User Story 2: Confirm and Execute a Split → requirements.md
- [route_and_summarise]: domain-20260316-8a9b → Feature 009 User Story 3: Dismiss or Flag a Split Proposal → requirements.md
- [route_and_summarise]: domain-20260316-2e3f → Feature 009 Functional Requirements FR-001–FR-010 → requirements.md
- [route_and_summarise]: domain-20260316-3c4d → Feature 009 Sub-file Naming Convention → requirements.md
- [route_and_summarise]: domain-20260316-4a5b → Feature 009 Technical Constraints → requirements.md
- [route_and_summarise]: domain-20260316-0c1d → Feature 009 Edge Cases → requirements.md
- [route_and_summarise]: domain-20260316-8e9f → Feature 009 Success Criteria SC-001–SC-005 → requirements.md
- [route_and_summarise]: domain-20260316-0a1b → Design Assumptions — Feature 009 Specification Session → decisions.md
- [route_and_summarise]: domain-20260316-2a3b → Design Clarifications — Feature 009 Specification Session → decisions.md
- [route_and_summarise]: domain-20260316-1a2b → Feature 009 SplitCandidate State Transitions → decisions.md
- [classify_and_route]: domain-20260316-1c2d → SplitCandidate entity (other→interface) → interfaces.md
- [classify_and_route]: domain-20260316-3e4f → SplitProposal entity (other→interface) → interfaces.md
- [classify_and_route]: domain-20260316-5a6b → SubFileSpec entity (other→interface) → interfaces.md
- [classify_and_route]: domain-20260316-7c8d → SplitResolution entity (other→interface) → interfaces.md
- [classify_and_route]: domain-20260316-9e0f → ThresholdConfig entity (other→interface) → interfaces.md
- [archive_only]: domain-20260316-6c7d → high-level summary covered by SplitProposal + ThresholdConfig entities

---

## 2026-03-17 — Triage Session

### Closed
- [close]: domain-20260312-c007 → Distilled File Auto-Splitting
  Rationale: "feature implemented"
- [close]: domain-20260316-9d3a → Validate Feature 005 SC-001–SC-004 with Representative /refine Batch
  Rationale: "Verification complete and passed"

---

## 2026-03-17 — Refine Session (Feature 005 Validation Batch)

### Semantic Duplicates
- [semantic_duplicate]: domain-20260317-ff01 → archived
  Matched: [RESOLVED] ADR-001: Delivery Mechanism
  Basis: both describe the no-runtime, command-files-only delivery approach for Domain Brain
- [semantic_duplicate]: domain-20260317-ff02 → archived
  Matched: [RESOLVED] ADR-007: Raw Item Filename Convention
  Basis: both describe the `<domain>-<YYYYMMDD>-<4hex>.md` filename pattern with id-match property
- [semantic_duplicate]: domain-20260317-ff03 → archived
  Matched: Feature 001 SC-002 in requirements.md
  Basis: both state the 70% autonomous processing rate target for /refine
- [semantic_duplicate]: domain-20260317-ff04 → archived
  Matched: /refine Interface Contract §Pause and Resume in interfaces.md
  Basis: both describe stop/pause halting the session with queue intact and partial changelog written
- [semantic_duplicate]: domain-20260317-ff05 → archived
  Matched: [RESOLVED] ADR-003: Retrieval Strategy by Domain Size
  Basis: both describe the ≤50/51-500/>500 tiered retrieval strategy for /query
- [semantic_duplicate]: domain-20260317-ff06 → archived
  Matched: /seed Interface Contract §Session Cap in interfaces.md
  Basis: both describe the 100-item cap with out-of-scope exclusion and --limit N override
- [semantic_duplicate]: domain-20260317-ff07 → archived
  Matched: /refine Interface Contract §Governed Decision Presentation in interfaces.md
  Basis: both describe one-at-a-time lettered-option governed decisions with natural language acceptance

### Autonomous actions
- [route_and_summarise]: domain-20260317-ff08 → new requirement appended to requirements.md ([TEST-V005] Dry-run mode for refine command)
- [route_and_summarise]: domain-20260317-ff09 → new task appended to backlog.md ([TEST-V005] Implement /diff command for changelog comparison, priority: medium)
- [aggregate]: domain-20260317-ff0a → --format json section appended to /query Interface Contract in interfaces.md

---

## 2026-03-18 — Triage Session

### Closed
- [close]: domain-20260312-c00a, domain-20260316-a2e7 → Onboarding and Introduction for New Users
  Rationale: "implemented as domain/README.md generated by /consolidate command (feature 010)"

---

## 2026-03-18 — Refine Session

### Autonomous actions
- [route_and_summarise]: domain-20260318-b2c3, domain-20260318-c4d5, domain-20260318-d6e7 → Feature 010 User Stories (US1–US3) appended to requirements-active-1.md
- [route_and_summarise]: domain-20260318-e8f9 → Feature 010 Edge Cases appended to requirements-active-1.md
- [route_and_summarise]: domain-20260318-fa0b → Feature 010 Functional Requirements (FR-001–FR-010) appended to requirements-active-1.md
- [route_and_summarise]: domain-20260318-0c1d → Feature 010 Technical Constraints appended to requirements-active-1.md
- [route_and_summarise]: domain-20260318-2e3f, domain-20260318-4a5b → Feature 010 Success Criteria and Assumptions appended to requirements-active-1.md
- [route_and_summarise]: domain-20260318-6c7d → DomainReadme output document entity appended to interfaces.md
- [route_and_summarise]: domain-20260318-8e9f → ConsolidateSession in-memory session entity appended to interfaces.md
- [route_and_summarise]: domain-20260318-0a1b → BacklogItem read-only view entity appended to interfaces.md
- [route_and_summarise]: domain-20260318-2c3d → InterfaceEntry read-only view entity appended to interfaces.md
- [route_and_summarise]: domain-20260318-a4c7 → ADR-019 (Consolidate Command Merged into Consistency-Check) appended to decisions.md

---
