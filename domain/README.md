# Domain Brain — Instance Template

This directory is a template for a single domain brain instance. Copy and rename it for
your team's domain, then use the `/capture`, `/refine`, and `/query` Claude commands to
manage your domain knowledge.

## Initialization

1. **Copy this directory** and rename it for your domain:

   ```bash
   cp -r domain/ my-payments-domain/
   ```

2. **For single-domain repos** (name it `domain/`): the commands find it automatically.

   **For multi-domain repos**: create a `.domain-brain-root` file at the git root:

   ```bash
   echo "my-payments-domain/" > .domain-brain-root
   ```

3. **Frame the domain identity** (required before seeding, recommended before capturing):

   ```
   /frame
   ```

   This creates `config/identity.md` — a one-line headline, a 3–5 sentence pitch, and explicit
   in-scope / out-of-scope lists. The identity is used by `/seed` to filter relevance, by
   `/refine` to archive off-domain items, and by `/query` to orient answers for new readers.

4. **Seed existing knowledge** (optional): Import existing docs, runbooks, or web pages:

   ```
   /seed docs/payments-runbook.md
   /seed docs/payments/
   ```

   Requires `config/identity.md` to exist (run `/frame` first).

5. **Customize types** (optional): Edit `config/types.yaml` to add domain-specific capture
   types. Changes take effect immediately — no restart needed.

6. **Capture your first item**:

   ```
   /capture Payments team owns all checkout error handling
   ```

7. **Run first refine session**:

   ```
   /refine
   ```

8. **Query the brain**:

   ```
   /query Who owns checkout error handling?
   ```

## Directory Structure

```
<domain-root>/
├── config/
│   ├── types.yaml       # Type registry — edit to customize capture types
│   └── identity.md      # Domain identity — created by /frame
├── raw/                 # Raw item queue — one .md file per /capture or /seed invocation
├── distilled/           # Distilled knowledge files — written by /refine
│   ├── domain.md        # Responsibilities and team ownership
│   ├── codebases.md     # Repos, services, tech stack
│   ├── interfaces.md    # API contracts, events, integration points
│   ├── requirements.md  # Constraints and non-negotiables
│   ├── stakeholders.md  # People, teams, external parties
│   ├── decisions.md     # ADRs (open and resolved)
│   ├── backlog.md       # Actionable work items
│   └── changelog.md     # Refine session audit trail
└── index/               # Large document chunk index — auto-populated by /capture
```

## Commands

| Command | Purpose |
|---|---|
| `/frame` | Create or update the domain identity (headline, pitch, scope lists) |
| `/seed <source>` | Bulk-import existing docs, PDFs, or URLs into the raw queue |
| `/capture <description>` | Capture a raw knowledge item (≤30 seconds, no manual envelope) |
| `/refine` | Process raw queue — autonomous + governed decisions |
| `/query <question>` | Ask a natural language question; get a cited answer |

## Tips

- **Commit after every refine session** — the changelog gives you a clean git history.
- **Keep the distilled base small** — a large growing distilled set signals a quality problem in the refine layer.
- **Open ADRs are first-class** — they appear in query results for any intersecting topic.
