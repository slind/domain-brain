---
id: API-002
status: open
expanded: false
opened: 2026-03-23
parents: [API-001]
---

# What storage backend should we use for rate limit counters?

## Initiatives

- [ ] Benchmark Redis vs Memcached
- [ ] Evaluate distributed vs single-node

## Evidence

### Distilled Knowledge

### Provisional Leads

[lead] Redis has built-in sorted sets which could be useful
[lead] Need sub-millisecond latency for rate limit checks

## Child Nodes

<!-- This section is informational only - populated by scanning parent references -->
<!-- Child nodes are discovered by scanning all investigation files for this node's ID in their parents list -->

## Resolution

<!-- Filled when the node is resolved -->
<!-- Contains: conclusion summary, references to ADRs created, date resolved -->
