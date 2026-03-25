#!/usr/bin/env bash
set -euo pipefail

# Domain Brain installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/slind/domain-brain/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/slind/domain-brain/main/install.sh | bash -s -- my-project

GITHUB_RAW_BASE="https://raw.githubusercontent.com/slind/domain-brain/main"

# Command files to install (from .claude/commands/)
COMMANDS=(
  "domain:capture.md"
  "domain:consistency-check.md"
  "domain:frame.md"
  "domain:query.md"
  "domain:refine.md"
  "domain:triage.md"
)

# Agent files to install (from .claude/agents/)
AGENTS=(
  "domain-refine-subagent.md"
)

# Skill directories to install (from .claude/skills/)
SKILLS=(
  "domain-capture"
  "domain-seed"
)

# Function to fetch a file from GitHub
fetch_file() {
  local source_path="$1"
  local dest_path="$2"

  if ! curl -fsSL "${GITHUB_RAW_BASE}/${source_path}" -o "${dest_path}"; then
    echo "Error: Failed to fetch ${source_path}" >&2
    return 1
  fi
}

# Main installation function
install_domain_brain() {
  local target_dir="${1:-.}"

  # If a project name was provided, create the directory
  if [[ "$target_dir" != "." ]]; then
    if [[ -e "$target_dir" ]]; then
      echo "Error: Directory '$target_dir' already exists" >&2
      exit 1
    fi
    mkdir -p "$target_dir"
    echo "Created project directory: $target_dir"
  fi

  cd "$target_dir"

  # Create .claude directory structure
  mkdir -p .claude/commands
  mkdir -p .claude/agents
  mkdir -p .claude/skills

  # Install command files
  echo "Installing Domain Brain commands..."
  for cmd in "${COMMANDS[@]}"; do
    # Note: filenames with colons may need special handling on some systems
    # We're using the colon directly as per the PRD requirement
    fetch_file ".claude/commands/${cmd}" ".claude/commands/${cmd}"
  done

  # Install agent files
  echo "Installing Domain Brain agents..."
  for agent in "${AGENTS[@]}"; do
    fetch_file ".claude/agents/${agent}" ".claude/agents/${agent}"
  done

  # Install skill files
  echo "Installing Domain Brain skills..."
  for skill in "${SKILLS[@]}"; do
    mkdir -p ".claude/skills/${skill}"
    fetch_file ".claude/skills/${skill}/SKILL.md" ".claude/skills/${skill}/SKILL.md"
  done

  # Create .domain-brain-root marker
  echo "domain/" > .domain-brain-root

  # Create domain/config directory and write types.yaml if it doesn't exist
  mkdir -p domain/config
  if [[ ! -f domain/config/types.yaml ]]; then
    echo "Creating default types.yaml..."
    cat > domain/config/types.yaml <<'EOF'
# Domain Brain — Type Registry
# Each type definition controls how /capture classifies items and how /refine routes them.
# Fields:
#   name:        The type identifier used in raw item YAML frontmatter.
#   description: Shown alongside the type name during capture and refinement.
#   routes_to:   Relative path from domain root to the target distilled file.
#   example:     One illustrative sentence used by the refine agent for classification inference.
#
# Hot-reload: Changes here take effect at the next /capture or /refine invocation.

types:
  - name: responsibility
    description: "Asserts which team, person, or service owns a domain area or capability."
    routes_to: distilled/domain.md
    example: "Payments owns checkout error handling end-to-end."

  - name: interface
    description: "Describes an API contract, event schema, or integration point between services."
    routes_to: distilled/interfaces.md
    example: "The checkout callback emits a payment.completed event with orderId and amount."

  - name: codebase
    description: "Describes a repository, service, or technical component and its ownership."
    routes_to: distilled/codebases.md
    example: "payments-api is owned by the Payments team, built in Node.js, deployed on AWS."

  - name: requirement
    description: "Captures a constraint, non-negotiable, or quality attribute the system must satisfy."
    routes_to: distilled/requirements.md
    example: "Checkout must complete in under 2 seconds at P99 under peak load."

  - name: stakeholder
    description: "Describes a person, team, or external party and their relationship to the domain."
    routes_to: distilled/stakeholders.md
    example: "Alice is the tech lead for the Payments team, responsible for architectural decisions."

  - name: decision
    description: "Records an architectural decision, its options, and its rationale (ADR)."
    routes_to: distilled/decisions.md
    example: "We chose Kafka over RabbitMQ for async events due to throughput requirements."

  - name: task
    description: "An actionable work item linked to a domain requirement or gap."
    routes_to: distilled/backlog.md
    example: "Add retry logic to the payment callback handler (linked to REQ-007)."

  - name: mom
    description: "Minutes of meeting — captures decisions, action items, and context from a discussion."
    routes_to: distilled/changelog.md
    example: "Architecture call 2026-03-04: agreed that Payments owns checkout error handling."

  - name: other
    description: "Unclassified item. The refine agent will attempt to classify it during refinement."
    routes_to: null
    example: "The checkout flow behaves differently on mobile browsers."
EOF
  fi

  echo ""
  echo "✓ Domain Brain installed successfully!"
  echo ""
  echo "Next step: Run /domain:frame to define your domain."
}

# Parse arguments
PROJECT_NAME="${1:-}"

install_domain_brain "$PROJECT_NAME"
