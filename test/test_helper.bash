#!/usr/bin/env bash
# Test helper for ralph BATS tests

# Path to the ralph script (used by tests)
export RALPH_SCRIPT="${BATS_TEST_DIRNAME}/../ralph"

# Setup function - creates isolated temp directory for each test
setup() {
    # Create a unique temp directory for this test
    TEST_TEMP_DIR=$(mktemp -d)

    # Change to temp directory so tests don't affect real files
    cd "$TEST_TEMP_DIR" || exit 1

    # Create minimal BRIEF.md for tests that need it
    create_mock_brief

    # Create .gitignore with workflow files to skip gitignore check prompt
    create_mock_gitignore
}

# Teardown function - cleans up temp directory after each test
teardown() {
    # Return to original directory
    cd "$BATS_TEST_DIRNAME" || exit 1

    # Remove temp directory and all contents
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a minimal BRIEF.md fixture
create_mock_brief() {
    cat > BRIEF.md << 'EOF'
# Test Brief

## Tasks

### TASK-001: Test task
- [ ] Item one
- [ ] Item two
EOF
}

# Create a mock WORKLOG.md fixture
create_mock_worklog() {
    cat > WORKLOG.md << 'EOF'
# Work Log

## Learnings
(Patterns discovered during implementation)

---
EOF
}

# Create a mock .gitignore with workflow files
create_mock_gitignore() {
    cat > .gitignore << 'EOF'
BRIEF.md
WORKLOG.md
EOF
}

# Create a mock claude command that succeeds
create_mock_claude_success() {
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/claude" << 'EOF'
#!/usr/bin/env bash
echo "Mock claude output"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/claude"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

# Create a mock claude command that fails
create_mock_claude_failure() {
    local exit_code="${1:-1}"
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/claude" << EOF
#!/usr/bin/env bash
echo "Mock claude error" >&2
exit $exit_code
EOF
    chmod +x "$TEST_TEMP_DIR/bin/claude"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

# Remove claude from PATH for tests that need it missing
remove_claude_from_path() {
    # Create a sanitized PATH that preserves system commands but removes claude
    # Prepend empty bin directory to shadow any claude in PATH
    mkdir -p "$TEST_TEMP_DIR/bin"
    # Remove any existing claude mock
    rm -f "$TEST_TEMP_DIR/bin/claude"
    # Prepend our empty bin dir so it gets checked first, but keep system paths
    export PATH="$TEST_TEMP_DIR/bin:/usr/bin:/bin"
}

# Create a mock claude command that blocks (for signal testing)
# Uses sleep in a way that allows signal propagation
create_mock_claude_blocking() {
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/claude" << 'EOF'
#!/usr/bin/env bash
# Block indefinitely - signals will terminate this
exec sleep 3600
EOF
    chmod +x "$TEST_TEMP_DIR/bin/claude"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

# Create a mock claude command that outputs the completion marker
create_mock_claude_complete() {
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/claude" << 'EOF'
#!/usr/bin/env bash
echo "Mock claude completed all tasks"
echo "<promise>COMPLETE</promise>"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/claude"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

# Create a mock claude command that outputs a partial completion marker
create_mock_claude_partial_marker() {
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/claude" << 'EOF'
#!/usr/bin/env bash
echo "Mock claude output"
echo "<promise>COMPLE"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/claude"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

# Create a mock claude command that outputs marker without closing tag
create_mock_claude_unclosed_marker() {
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/claude" << 'EOF'
#!/usr/bin/env bash
echo "Mock claude output"
echo "<promise>COMPLETE"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/claude"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

# Create a mock claude command that outputs similar but different marker
create_mock_claude_similar_marker() {
    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/claude" << 'EOF'
#!/usr/bin/env bash
echo "Mock claude output"
echo "<promise>COMPLETED</promise>"
exit 0
EOF
    chmod +x "$TEST_TEMP_DIR/bin/claude"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}
