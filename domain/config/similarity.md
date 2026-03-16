# Similarity Configuration

## Threshold

**Level**: moderate

<!-- Allowed values: conservative | moderate | aggressive

  conservative — filter only near-verbatim restatements of a distilled entry;
                 paraphrases with different framing pass through to the subagent

  moderate     — filter when the raw item conveys the same core fact as a distilled
                 entry, even if worded or framed differently; new nuance or additional
                 context passes through (DEFAULT)

  aggressive   — filter when the raw item addresses the same topic as a distilled entry,
                 even if it adds some peripheral detail; only genuinely new knowledge
                 (new claims, new entities, new constraints) passes through

  Change this value to tune how aggressively near-duplicates are suppressed.
  Effect takes place on the next /refine invocation — no command file changes needed.
-->
