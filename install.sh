#!/usr/bin/env bash
set -euo pipefail

# Domain Brain installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/slind/domain-brain/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/slind/domain-brain/main/install.sh | bash -s -- my-project
#   curl -fsSL https://raw.githubusercontent.com/slind/domain-brain/main/install.sh | bash -s -- --update

GITHUB_RAW_BASE="https://raw.githubusercontent.com/slind/domain-brain/main"

# Command files to install (from .claude/commands/)
COMMANDS=(
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

# Function to update an existing Domain Brain installation
update_domain_brain() {
  # Verify we're in a project with Domain Brain installed
  if [[ ! -f .domain-brain-root ]]; then
    echo "Error: No Domain Brain installation found in current directory" >&2
    echo "Hint: Run without --update to perform a fresh install" >&2
    exit 1
  fi

  echo "Updating Domain Brain installation..."
  echo ""

  local -a added=()
  local -a updated=()
  local -a removed=()

  # Track existing Domain Brain files before update
  local -A existing_commands=()
  local -A existing_agents=()
  local -A existing_skills=()

  # Scan for existing Domain Brain files
  if [[ -d .claude/commands ]]; then
    while IFS= read -r -d '' file; do
      local basename=$(basename "$file")
      if [[ "$basename" == domain:*.md ]]; then
        existing_commands["$basename"]=1
      fi
    done < <(find .claude/commands -maxdepth 1 -type f -name "domain:*.md" -print0 2>/dev/null)
  fi

  if [[ -d .claude/agents ]]; then
    while IFS= read -r -d '' file; do
      local basename=$(basename "$file")
      if [[ "$basename" == domain-*.md ]]; then
        existing_agents["$basename"]=1
      fi
    done < <(find .claude/agents -maxdepth 1 -type f -name "domain-*.md" -print0 2>/dev/null)
  fi

  if [[ -d .claude/skills ]]; then
    while IFS= read -r -d '' dir; do
      local basename=$(basename "$dir")
      if [[ "$basename" == domain-* ]]; then
        existing_skills["$basename"]=1
      fi
    done < <(find .claude/skills -maxdepth 1 -type d -name "domain-*" -print0 2>/dev/null)
  fi

  # Create directories if they don't exist
  mkdir -p .claude/commands
  mkdir -p .claude/agents
  mkdir -p .claude/skills

  # Update command files
  for cmd in "${COMMANDS[@]}"; do
    local dest_path=".claude/commands/${cmd}"
    if [[ -f "$dest_path" ]]; then
      fetch_file ".claude/commands/${cmd}" "${dest_path}"
      updated+=("commands/${cmd}")
      unset existing_commands["$cmd"]
    else
      fetch_file ".claude/commands/${cmd}" "${dest_path}"
      added+=("commands/${cmd}")
    fi
  done

  # Update agent files
  for agent in "${AGENTS[@]}"; do
    local dest_path=".claude/agents/${agent}"
    if [[ -f "$dest_path" ]]; then
      fetch_file ".claude/agents/${agent}" "${dest_path}"
      updated+=("agents/${agent}")
      unset existing_agents["$agent"]
    else
      fetch_file ".claude/agents/${agent}" "${dest_path}"
      added+=("agents/${agent}")
    fi
  done

  # Update skill files
  for skill in "${SKILLS[@]}"; do
    local dest_dir=".claude/skills/${skill}"
    local dest_file="${dest_dir}/SKILL.md"
    if [[ -d "$dest_dir" ]]; then
      mkdir -p "$dest_dir"
      fetch_file ".claude/skills/${skill}/SKILL.md" "${dest_file}"
      updated+=("skills/${skill}/SKILL.md")
      unset existing_skills["$skill"]
    else
      mkdir -p "$dest_dir"
      fetch_file ".claude/skills/${skill}/SKILL.md" "${dest_file}"
      added+=("skills/${skill}/SKILL.md")
    fi
  done

  # Remove obsolete Domain Brain files (files that existed but are no longer in the lists)
  for cmd in "${!existing_commands[@]}"; do
    rm -f ".claude/commands/${cmd}"
    removed+=("commands/${cmd}")
  done

  for agent in "${!existing_agents[@]}"; do
    rm -f ".claude/agents/${agent}"
    removed+=("agents/${agent}")
  done

  for skill in "${!existing_skills[@]}"; do
    rm -rf ".claude/skills/${skill}"
    removed+=("skills/${skill}/")
  done

  # Report changes
  echo ""
  echo "Update complete!"
  echo ""

  if [[ ${#added[@]} -gt 0 ]]; then
    echo "Added:"
    for file in "${added[@]}"; do
      echo "  + $file"
    done
    echo ""
  fi

  if [[ ${#updated[@]} -gt 0 ]]; then
    echo "Updated:"
    for file in "${updated[@]}"; do
      echo "  ~ $file"
    done
    echo ""
  fi

  if [[ ${#removed[@]} -gt 0 ]]; then
    echo "Removed:"
    for file in "${removed[@]}"; do
      echo "  - $file"
    done
    echo ""
  fi

  if [[ ${#added[@]} -eq 0 && ${#updated[@]} -eq 0 && ${#removed[@]} -eq 0 ]]; then
    echo "No changes needed - installation is up to date."
    echo ""
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
if [[ "${1:-}" == "--update" ]]; then
  update_domain_brain
else
  PROJECT_NAME="${1:-}"
  install_domain_brain "$PROJECT_NAME"
fi
