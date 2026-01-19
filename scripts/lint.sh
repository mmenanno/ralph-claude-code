#!/usr/bin/env bash
# ShellCheck validation script for ralph project
#
# Runs shellcheck on all shell scripts in the repository.
# Exit codes:
#   0 - All files pass shellcheck
#   1 - One or more files failed shellcheck or shellcheck not found

set -euo pipefail

# Colors for output (respects NO_COLOR)
if [[ -z "${NO_COLOR:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    BLUE=''
    NC=''
fi

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check for shellcheck
if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}Error:${NC} shellcheck not found in PATH"
    echo "Install with: brew install shellcheck (macOS) or apt install shellcheck (Ubuntu)"
    exit 1
fi

echo -e "${BLUE}Running ShellCheck on ralph project...${NC}"
echo ""

# Track failures
FAILED=0

# Files to check
FILES=(
    "$PROJECT_ROOT/ralph"
    "$PROJECT_ROOT/test/ralph.bats"
    "$PROJECT_ROOT/test/test_helper.bash"
)

# Run shellcheck on each file
for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        relative_path="${file#"$PROJECT_ROOT/"}"
        echo -n "Checking $relative_path... "

        # BATS files need --shell=bash since they have .bats extension
        shell_arg=""
        if [[ "$file" == *.bats ]]; then
            shell_arg="--shell=bash"
        fi

        # Run shellcheck (SC1091 is ignored for sourced files that may not exist during analysis)
        # shellcheck disable=SC2086
        if shellcheck $shell_arg --exclude=SC1091 "$file"; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAILED${NC}"
            FAILED=1
        fi
    else
        echo -e "${RED}Error:${NC} File not found: $file"
        FAILED=1
    fi
done

echo ""

if [[ "$FAILED" -eq 0 ]]; then
    echo -e "${GREEN}All files passed ShellCheck!${NC}"
    exit 0
else
    echo -e "${RED}ShellCheck found issues in one or more files.${NC}"
    exit 1
fi
