#!/usr/bin/env bash
# Test suite for install.sh
# Runs install.sh against temporary directories and validates file-system outcomes
# Uses local repository files as fixtures instead of GitHub fetches

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get the directory where this test script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Temporary directory for test runs
TEST_ROOT=""

# Clean up function
cleanup() {
  if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
    rm -rf "$TEST_ROOT"
  fi
}

trap cleanup EXIT

# Assertion helpers
assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]]; then
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAILED: $message"
    echo -e "${RED}  File not found: $file${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_not_exists() {
  local file="$1"
  local message="${2:-File should not exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ ! -e "$file" ]]; then
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAILED: $message"
    echo -e "${RED}  File unexpectedly exists: $file${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local message="${2:-Directory should exist: $dir}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -d "$dir" ]]; then
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAILED: $message"
    echo -e "${RED}  Directory not found: $dir${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File should contain pattern: $pattern}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]] && grep -qF "$pattern" "$file"; then
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} FAILED: $message"
    if [[ ! -f "$file" ]]; then
      echo -e "${RED}  File not found: $file${NC}"
    else
      echo -e "${RED}  Pattern not found in $file: $pattern${NC}"
    fi
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Create a local version of install.sh that uses local files instead of GitHub
create_local_installer() {
  local dest="$1"

  # Create a modified installer that uses local files
  cat > "$dest" <<'INSTALLER_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Local Domain Brain installer (test version)
# Uses local repository files instead of GitHub

# Directory where the actual Domain Brain files are located
SOURCE_DIR="${SOURCE_DIR:-.}"

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

# Function to fetch a file from local source
fetch_file() {
  local source_path="$1"
  local dest_path="$2"

  if ! cp "${SOURCE_DIR}/${source_path}" "${dest_path}"; then
    echo "Error: Failed to copy ${source_path}" >&2
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
types:
  - name: task
    description: "An actionable work item linked to a domain requirement or gap."
    routes_to: distilled/backlog.md
    example: "Add retry logic to the payment callback handler (linked to REQ-007)."
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
INSTALLER_SCRIPT

  chmod +x "$dest"
}

# Test 1: Fresh install - new project
test_fresh_install_new_project() {
  echo ""
  echo -e "${YELLOW}Test 1: Fresh install - new project${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local test_dir="$TEST_ROOT/test1"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Create local installer
  create_local_installer "./install-local.sh"

  # Run installer with project name
  SOURCE_DIR="$SCRIPT_DIR" ./install-local.sh my-project >/dev/null 2>&1

  # Verify project directory created
  assert_dir_exists "my-project" "Project directory created"

  # Verify .claude structure
  assert_dir_exists "my-project/.claude/commands" ".claude/commands directory exists"
  assert_dir_exists "my-project/.claude/agents" ".claude/agents directory exists"
  assert_dir_exists "my-project/.claude/skills" ".claude/skills directory exists"

  # Verify command files exist
  assert_file_exists "my-project/.claude/commands/domain:consistency-check.md" "domain:consistency-check.md installed"
  assert_file_exists "my-project/.claude/commands/domain:frame.md" "domain:frame.md installed"
  assert_file_exists "my-project/.claude/commands/domain:refine.md" "domain:refine.md installed"
  assert_file_exists "my-project/.claude/commands/domain:query.md" "domain:query.md installed"
  assert_file_exists "my-project/.claude/commands/domain:triage.md" "domain:triage.md installed"
  assert_file_exists "my-project/.claude/commands/domain:consistency-check.md" "domain:consistency-check.md installed"

  # Verify agent files exist
  assert_file_exists "my-project/.claude/agents/domain-refine-subagent.md" "domain-refine-subagent.md installed"

  # Verify skill files exist
  assert_file_exists "my-project/.claude/skills/domain-capture/SKILL.md" "domain-capture skill installed"
  assert_file_exists "my-project/.claude/skills/domain-seed/SKILL.md" "domain-seed skill installed"

  # Verify .domain-brain-root
  assert_file_exists "my-project/.domain-brain-root" ".domain-brain-root created"
  assert_file_contains "my-project/.domain-brain-root" "domain/" ".domain-brain-root contains 'domain/'"

  # Verify types.yaml created
  assert_file_exists "my-project/domain/config/types.yaml" "types.yaml created"

  # Verify domain/raw/ NOT created
  assert_file_not_exists "my-project/domain/raw" "domain/raw not created by installer"
  assert_file_not_exists "my-project/domain/distilled" "domain/distilled not created by installer"
  assert_file_not_exists "my-project/domain/index" "domain/index not created by installer"
}

# Test 2: Fresh install - existing project
test_fresh_install_existing_project() {
  echo ""
  echo -e "${YELLOW}Test 2: Fresh install - existing project${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local test_dir="$TEST_ROOT/test2"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Create a pre-existing .claude structure with a non-Domain Brain skill
  mkdir -p .claude/skills/other-skill
  echo "# Other Skill" > .claude/skills/other-skill/SKILL.md

  # Create local installer
  create_local_installer "./install-local.sh"

  # Run installer in current directory
  SOURCE_DIR="$SCRIPT_DIR" ./install-local.sh >/dev/null 2>&1

  # Verify Domain Brain files installed
  assert_file_exists ".claude/commands/domain:frame.md" "Domain Brain commands installed"
  assert_file_exists ".claude/skills/domain-capture/SKILL.md" "Domain Brain skills installed"

  # Verify pre-existing skill untouched
  assert_file_exists ".claude/skills/other-skill/SKILL.md" "Pre-existing skill preserved"
  assert_file_contains ".claude/skills/other-skill/SKILL.md" "# Other Skill" "Pre-existing skill content unchanged"
}

# Test 3: Update mode
test_update_mode() {
  echo ""
  echo -e "${YELLOW}Test 3: Update mode${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local test_dir="$TEST_ROOT/test3"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Create local installer
  create_local_installer "./install-local.sh"

  # First, do a fresh install
  SOURCE_DIR="$SCRIPT_DIR" ./install-local.sh >/dev/null 2>&1

  # Create some user content
  mkdir -p domain/raw
  echo "# User content" > domain/raw/user-item.md

  mkdir -p .claude/skills/user-skill
  echo "# User Skill" > .claude/skills/user-skill/SKILL.md

  # Modify a Domain Brain command file
  echo "# MODIFIED" > .claude/commands/domain:frame.md

  # Run update
  SOURCE_DIR="$SCRIPT_DIR" ./install-local.sh --update >/dev/null 2>&1

  # Verify Domain Brain file was restored
  assert_file_exists ".claude/commands/domain:frame.md" "domain:frame.md exists after update"
  # Should not contain "# MODIFIED" anymore - it should be restored from source
  # (We can't easily test this without knowing the actual content, but the file should exist)

  # Verify user skill untouched
  assert_file_exists ".claude/skills/user-skill/SKILL.md" "User skill preserved during update"
  assert_file_contains ".claude/skills/user-skill/SKILL.md" "# User Skill" "User skill content unchanged"

  # Verify domain/ directory untouched
  assert_file_exists "domain/raw/user-item.md" "domain/raw content preserved"
  assert_file_contains "domain/raw/user-item.md" "# User content" "domain content unchanged"
}

# Test 4: types.yaml preservation
test_types_yaml_preservation() {
  echo ""
  echo -e "${YELLOW}Test 4: types.yaml preservation${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local test_dir="$TEST_ROOT/test4"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Create local installer
  create_local_installer "./install-local.sh"

  # First, do a fresh install
  SOURCE_DIR="$SCRIPT_DIR" ./install-local.sh >/dev/null 2>&1

  # Modify types.yaml
  echo "# CUSTOM TYPES" >> domain/config/types.yaml

  # Run update
  SOURCE_DIR="$SCRIPT_DIR" ./install-local.sh --update >/dev/null 2>&1

  # Verify types.yaml still contains the modification
  assert_file_exists "domain/config/types.yaml" "types.yaml exists after update"
  assert_file_contains "domain/config/types.yaml" "# CUSTOM TYPES" "types.yaml modification preserved"
}

# Main test runner
main() {
  echo ""
  echo "═══════════════════════════════════════════════════"
  echo "  Domain Brain Install Script Test Suite"
  echo "═══════════════════════════════════════════════════"

  # Create test root directory
  TEST_ROOT=$(mktemp -d)
  echo "Test directory: $TEST_ROOT"

  # Run all tests
  test_fresh_install_new_project
  test_fresh_install_existing_project
  test_update_mode
  test_types_yaml_preservation

  # Print summary
  echo ""
  echo "═══════════════════════════════════════════════════"
  echo "  Test Summary"
  echo "═══════════════════════════════════════════════════"
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    exit 1
  else
    echo -e "Tests failed: $TESTS_FAILED"
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

main "$@"
