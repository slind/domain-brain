---
id: API-001
status: blocked
expanded: true
opened: 2026-03-24
parents: []
---

# How should we handle rate limiting?

## Initiatives

- [x] Define rate limit thresholds
- [x] Choose rate limiting algorithm

## Evidence

### Distilled Knowledge

[distilled] Free tier should allow 100 requests/hour (requirements.md:23)
[distilled] Premium tier should allow 10000 requests/hour (requirements.md:24)
[distilled] Rate limiting must be per-API-key, not per-IP (decisions.md:8)

### Provisional Leads

[lead] Token bucket algorithm is preferred over sliding window

## Child Nodes

<!-- This section is informational only - populated by scanning parent references -->
<!-- Child nodes are discovered by scanning all investigation files for this node's ID in their parents list -->

## Resolution

<!-- Filled when the node is resolved -->
<!-- Contains: conclusion summary, references to ADRs created, date resolved -->
