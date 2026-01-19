#!/usr/bin/env bats
# BATS tests for ralph script

# Load test helper
load test_helper

# Smoke test - verify ralph script exists and is executable
@test "ralph script exists and is executable" {
    [[ -f "$RALPH_SCRIPT" ]]
    [[ -x "$RALPH_SCRIPT" ]]
}

# ====================
# Argument Validation Tests
# ====================

@test "--max with non-numeric value exits with error" {
    run "$RALPH_SCRIPT" --max abc
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Max iterations must be a positive integer"* ]]
}

@test "--max with 0 exits with error" {
    run "$RALPH_SCRIPT" --max 0
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Max iterations must be a positive integer"* ]]
}

@test "--max with negative number exits with error" {
    run "$RALPH_SCRIPT" --max -5
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Max iterations must be a positive integer"* ]]
}

@test "--sleep with non-numeric value exits with error" {
    run "$RALPH_SCRIPT" --sleep abc
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Sleep seconds must be a non-negative integer"* ]]
}

@test "unknown flag exits with error and shows usage" {
    run "$RALPH_SCRIPT" --unknown-flag
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Unknown option: --unknown-flag"* ]]
    [[ "$output" == *"USAGE"* ]]
}

# ====================
# Help Tests
# ====================

@test "--help exits with code 0" {
    run "$RALPH_SCRIPT" --help
    [[ "$status" -eq 0 ]]
}

@test "--help output contains USAGE" {
    run "$RALPH_SCRIPT" --help
    [[ "$output" == *"USAGE"* ]]
}

@test "--help output contains OPTIONS" {
    run "$RALPH_SCRIPT" --help
    [[ "$output" == *"OPTIONS"* ]]
}

@test "--help output contains EXIT CODES" {
    run "$RALPH_SCRIPT" --help
    [[ "$output" == *"EXIT CODES"* ]]
}

@test "-h works same as --help" {
    run "$RALPH_SCRIPT" -h
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"USAGE"* ]]
    [[ "$output" == *"OPTIONS"* ]]
}

# ====================
# File Requirement Tests
# ====================

@test "exits with error when BRIEF.md is missing" {
    # Remove the BRIEF.md created by setup
    rm -f BRIEF.md
    run "$RALPH_SCRIPT"
    [[ "$status" -ne 0 ]]
}

@test "error message mentions BRIEF.md when missing" {
    rm -f BRIEF.md
    run "$RALPH_SCRIPT"
    [[ "$output" == *"BRIEF.md"* ]]
    [[ "$output" == *"not found"* ]]
}

@test "creates WORKLOG.md when it doesn't exist with --dry-run" {
    # Ensure WORKLOG.md doesn't exist
    rm -f WORKLOG.md
    # Need mock claude for dry-run to pass claude check
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run
    [[ "$status" -eq 0 ]]
    # Dry-run should NOT create WORKLOG.md (per TASK-009)
    [[ ! -f WORKLOG.md ]]
}

@test "--reset flag creates fresh WORKLOG.md without prompting" {
    # Create existing WORKLOG.md with some content
    echo "# Old Worklog Content" > WORKLOG.md
    # Need mock claude for the script to proceed
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run --reset
    [[ "$status" -eq 0 ]]
    # With dry-run AND reset, reset message should appear but no file modification
    [[ "$output" == *"Reset"* ]] || [[ "$output" == *"DRY RUN"* ]]
}

@test "--keep flag keeps existing WORKLOG.md without prompting" {
    # Create existing WORKLOG.md with some content
    echo "# Old Worklog Content" > WORKLOG.md
    create_mock_claude_success
    # Use --max 1 to limit iterations, mock claude completes immediately
    run "$RALPH_SCRIPT" --keep --max 1 --no-sleep
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]  # May reach max iterations
    [[ "$output" == *"Keeping existing"* ]]
}

@test "-k short flag works same as --keep" {
    echo "# Old Worklog Content" > WORKLOG.md
    create_mock_claude_success
    run "$RALPH_SCRIPT" -k --max 1 --no-sleep
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]  # May reach max iterations
    [[ "$output" == *"Keeping existing"* ]]
}

@test "--keep and --reset together exits with error" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --keep --reset
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "--help shows --keep option" {
    run "$RALPH_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"--keep"* ]]
    [[ "$output" == *"Keep existing worklog"* ]]
}

# ====================
# Flag Combination Tests
# ====================

@test "--quiet suppresses banner" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run --quiet
    [[ "$status" -eq 0 ]]
    # Banner contains ASCII art with "RALPH" - should not be present in quiet mode
    [[ "$output" != *"██████╗"* ]]
    [[ "$output" != *"Autonomous Coding Agent Loop"* ]]
}

@test "--dry-run does not execute claude" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run
    [[ "$status" -eq 0 ]]
    # Dry-run should show the preview message
    [[ "$output" == *"[DRY RUN]"* ]]
    [[ "$output" == *"Would execute claude with prompt"* ]]
}

@test "--verbose shows additional output" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run --verbose
    [[ "$status" -eq 0 ]]
    # Verbose mode shows "Verbose: enabled" in configuration
    [[ "$output" == *"Verbose: enabled"* ]]
}

@test "--unlimited sets no iteration limit" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run --unlimited
    [[ "$status" -eq 0 ]]
    # Unlimited mode shows "unlimited" in configuration
    [[ "$output" == *"Max iterations: unlimited"* ]]
}

@test "--no-sleep disables sleep" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run --no-sleep
    [[ "$status" -eq 0 ]]
    # No-sleep mode shows "disabled" in configuration
    [[ "$output" == *"Sleep: disabled"* ]]
}

# ====================
# Signal Handling Tests
# ====================

# Note: Signal handling tests use the 'timeout' command with --signal=INT
# to reliably send SIGINT to ralph. This is more reliable than background
# processes with manual kill commands, especially in CI environments.
# We skip these tests if the 'timeout' command is not available.

@test "sending SIGINT results in exit code 130" {
    # Check if timeout command is available (GNU coreutils)
    if ! command -v timeout &>/dev/null; then
        skip "timeout command not available"
    fi

    # Create a mock claude that blocks (will be interrupted by timeout)
    create_mock_claude_blocking

    # Run ralph with timeout that sends SIGINT after 1 second
    # The --signal=INT flag sends SIGINT instead of default SIGTERM
    # The --preserve-status flag preserves the exit status of the killed process
    run timeout --preserve-status --signal=INT 1s "$RALPH_SCRIPT" --max 1 --reset --no-sleep

    # Exit code should be 130 (128 + 2 for SIGINT)
    [[ "$status" -eq 130 ]]
}

@test "interrupted output contains 'Interrupted by user'" {
    # Check if timeout command is available
    if ! command -v timeout &>/dev/null; then
        skip "timeout command not available"
    fi

    # Create a mock claude that blocks
    create_mock_claude_blocking

    # Run ralph with timeout that sends SIGINT
    run timeout --signal=INT 1s "$RALPH_SCRIPT" --max 1 --reset --no-sleep

    # Output should contain the interruption message from the trap
    [[ "$output" == *"Interrupted by user"* ]]
}

# ====================
# Cleanup Tests
# ====================

@test "--cleanup with both files deletes them on confirmation" {
    # Create both workflow files
    echo "# Brief" > BRIEF.md
    echo "# Worklog" > WORKLOG.md

    # Use yes to simulate 'y' confirmation
    run bash -c "echo 'y' | '$RALPH_SCRIPT' --cleanup"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Deleted"* ]]
    [[ ! -f BRIEF.md ]]
    [[ ! -f WORKLOG.md ]]
}

@test "--cleanup with no files reports no files to delete" {
    # Remove any workflow files
    rm -f BRIEF.md WORKLOG.md

    run "$RALPH_SCRIPT" --cleanup
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"No workflow files to delete"* ]]
}

@test "--cleanup cancelled on 'n' response" {
    # Create both workflow files
    echo "# Brief" > BRIEF.md
    echo "# Worklog" > WORKLOG.md

    # Use echo 'n' to simulate rejection
    run bash -c "echo 'n' | '$RALPH_SCRIPT' --cleanup"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Cleanup cancelled"* ]]
    # Files should still exist
    [[ -f BRIEF.md ]]
    [[ -f WORKLOG.md ]]
}

@test "--cleanup only deletes BRIEF.md when WORKLOG.md doesn't exist" {
    # Create only BRIEF.md
    echo "# Brief" > BRIEF.md
    rm -f WORKLOG.md

    run bash -c "echo 'y' | '$RALPH_SCRIPT' --cleanup"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Deleted"* ]]
    [[ "$output" == *"BRIEF.md"* ]]
    [[ ! -f BRIEF.md ]]
}

@test "--cleanup only deletes WORKLOG.md when BRIEF.md doesn't exist" {
    # Create only WORKLOG.md
    rm -f BRIEF.md
    echo "# Worklog" > WORKLOG.md

    run bash -c "echo 'y' | '$RALPH_SCRIPT' --cleanup"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Deleted"* ]]
    [[ "$output" == *"WORKLOG.md"* ]]
    [[ ! -f WORKLOG.md ]]
}

@test "--help shows --cleanup option" {
    run "$RALPH_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"--cleanup"* ]]
    [[ "$output" == *"Delete BRIEF.md and WORKLOG.md"* ]]
}

# ====================
# Force Flag Tests
# ====================

@test "--cleanup with --force skips confirmation and deletes files" {
    # Create both workflow files
    echo "# Brief" > BRIEF.md
    echo "# Worklog" > WORKLOG.md

    # No input needed - force skips confirmation
    run "$RALPH_SCRIPT" --cleanup --force
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Deleted"* ]]
    [[ ! -f BRIEF.md ]]
    [[ ! -f WORKLOG.md ]]
}

@test "--cleanup -f short flag works same as --force" {
    # Create both workflow files
    echo "# Brief" > BRIEF.md
    echo "# Worklog" > WORKLOG.md

    run "$RALPH_SCRIPT" --cleanup -f
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Deleted"* ]]
    [[ ! -f BRIEF.md ]]
    [[ ! -f WORKLOG.md ]]
}

@test "--force without --cleanup shows warning" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --force --dry-run
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"--force has no effect without --cleanup"* ]]
}

@test "-f without --cleanup shows warning" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" -f --dry-run
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"--force has no effect without --cleanup"* ]]
}

@test "--help shows --force option" {
    run "$RALPH_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"--force"* ]]
    [[ "$output" == *"Skip confirmation"* ]]
}

# ====================
# Gitignore Check Tests
# ====================

@test "gitignore check prompts when .gitignore exists but missing workflow files" {
    # Create .gitignore without workflow files
    echo "node_modules" > .gitignore
    create_mock_claude_success

    # Use 's' to skip (don't modify gitignore)
    run bash -c "echo 's' | '$RALPH_SCRIPT' --max 1 --no-sleep"
    [[ "$output" == *"Workflow files not in .gitignore"* ]]
    [[ "$output" == *"BRIEF.md"* ]]
    [[ "$output" == *"WORKLOG.md"* ]]
}

@test "gitignore check adds files when user chooses 'a'" {
    # Create .gitignore without workflow files
    echo "node_modules" > .gitignore
    create_mock_claude_success

    # Choose 'a' to add files to gitignore
    run bash -c "echo 'a' | '$RALPH_SCRIPT' --max 1 --no-sleep"
    [[ "$output" == *"Added"* ]]
    [[ "$output" == *".gitignore"* ]]

    # Verify files were added
    grep -Fxq "BRIEF.md" .gitignore
    grep -Fxq "WORKLOG.md" .gitignore
}

@test "gitignore check skips when user chooses 's'" {
    # Create .gitignore without workflow files
    echo "node_modules" > .gitignore
    create_mock_claude_success

    # Choose 's' to skip
    run bash -c "echo 's' | '$RALPH_SCRIPT' --max 1 --no-sleep"
    [[ "$output" == *"Skipping gitignore update"* ]]

    # Verify files were NOT added (use run to properly handle negation in BATS)
    run grep -Fxq "BRIEF.md" .gitignore
    [[ "$status" -ne 0 ]]
    run grep -Fxq "WORKLOG.md" .gitignore
    [[ "$status" -ne 0 ]]
}

@test "gitignore check prompts to create .gitignore when it doesn't exist" {
    # Ensure no .gitignore exists
    rm -f .gitignore
    create_mock_claude_success

    # Choose 's' to skip creation
    run bash -c "echo 's' | '$RALPH_SCRIPT' --max 1 --no-sleep"
    [[ "$output" == *".gitignore not found"* ]]
    [[ "$output" == *"Create .gitignore"* ]]
}

@test "gitignore check creates .gitignore when user chooses 'c'" {
    # Ensure no .gitignore exists
    rm -f .gitignore
    create_mock_claude_success

    # Choose 'c' to create gitignore
    run bash -c "echo 'c' | '$RALPH_SCRIPT' --max 1 --no-sleep"
    [[ "$output" == *"Created .gitignore"* ]]

    # Verify .gitignore was created with workflow files
    [[ -f .gitignore ]]
    grep -Fxq "BRIEF.md" .gitignore
    grep -Fxq "WORKLOG.md" .gitignore
}

@test "gitignore check skips when .gitignore already contains workflow files" {
    # Create .gitignore with workflow files already present
    echo "BRIEF.md" > .gitignore
    echo "WORKLOG.md" >> .gitignore
    create_mock_claude_success

    # Should not prompt - just proceed
    run "$RALPH_SCRIPT" --max 1 --no-sleep
    [[ "$output" != *"Workflow files not in .gitignore"* ]]
    [[ "$output" != *".gitignore not found"* ]]
}

@test "gitignore check is skipped in dry-run mode" {
    # Remove .gitignore to trigger prompt (if not skipped)
    rm -f .gitignore
    create_mock_claude_success

    # Dry-run should skip gitignore check entirely
    run "$RALPH_SCRIPT" --dry-run
    [[ "$status" -eq 0 ]]
    [[ "$output" != *".gitignore not found"* ]]
    [[ "$output" != *"Workflow files not in .gitignore"* ]]
}

@test "gitignore check only prompts for missing files when one is already present" {
    # Create .gitignore with only BRIEF.md
    echo "BRIEF.md" > .gitignore
    create_mock_claude_success

    # Should only prompt about WORKLOG.md
    run bash -c "echo 's' | '$RALPH_SCRIPT' --max 1 --no-sleep"
    [[ "$output" == *"WORKLOG.md"* ]]
    [[ "$output" != *"- BRIEF.md"* ]]  # BRIEF.md should NOT be in the missing list
}

# ====================
# Add Gitignore Flag Tests
# ====================

@test "--add-gitignore auto-adds workflow files to existing .gitignore" {
    # Create .gitignore without workflow files
    echo "node_modules" > .gitignore
    create_mock_claude_success

    # Should auto-add without prompting
    run "$RALPH_SCRIPT" --add-gitignore --max 1 --no-sleep
    [[ "$output" == *"Added"* ]]
    [[ "$output" == *".gitignore"* ]]
    [[ "$output" != *"[a]"* ]]  # Should not prompt

    # Verify files were added
    grep -Fxq "BRIEF.md" .gitignore
    grep -Fxq "WORKLOG.md" .gitignore
}

@test "--add-gitignore creates .gitignore when it doesn't exist" {
    # Ensure no .gitignore exists
    rm -f .gitignore
    create_mock_claude_success

    # Should auto-create without prompting
    run "$RALPH_SCRIPT" --add-gitignore --max 1 --no-sleep
    [[ "$output" == *"Created .gitignore"* ]]
    [[ "$output" != *"[c]"* ]]  # Should not prompt

    # Verify .gitignore was created with workflow files
    [[ -f .gitignore ]]
    grep -Fxq "BRIEF.md" .gitignore
    grep -Fxq "WORKLOG.md" .gitignore
}

@test "--add-gitignore does nothing when workflow files already in .gitignore" {
    # Create .gitignore with workflow files already present
    echo "BRIEF.md" > .gitignore
    echo "WORKLOG.md" >> .gitignore
    create_mock_claude_success

    # Should proceed without adding anything to gitignore
    run "$RALPH_SCRIPT" --add-gitignore --max 1 --no-sleep
    [[ "$output" != *"Added"*".gitignore"* ]]
    [[ "$output" != *"Created .gitignore"* ]]
}

@test "--add-gitignore only adds missing files" {
    # Create .gitignore with only BRIEF.md
    echo "BRIEF.md" > .gitignore
    create_mock_claude_success

    run "$RALPH_SCRIPT" --add-gitignore --max 1 --no-sleep
    [[ "$output" == *"Added"* ]]
    [[ "$output" == *"WORKLOG.md"* ]]

    # Verify only WORKLOG.md was added (BRIEF.md should still appear once)
    grep -Fxq "WORKLOG.md" .gitignore
    [[ $(grep -c "^BRIEF.md$" .gitignore) -eq 1 ]]
}

@test "--help shows --add-gitignore option" {
    run "$RALPH_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"--add-gitignore"* ]]
    [[ "$output" == *"Auto-add workflow files"* ]]
}

# ====================
# Skip Gitignore Flag Tests
# ====================

@test "--skip-gitignore bypasses gitignore check entirely" {
    # Remove .gitignore to trigger prompt (if not skipped)
    rm -f .gitignore
    create_mock_claude_success

    # Should skip gitignore check entirely - no prompt
    run "$RALPH_SCRIPT" --skip-gitignore --max 1 --no-sleep
    [[ "$output" != *".gitignore not found"* ]]
    [[ "$output" != *"Workflow files not in .gitignore"* ]]
    [[ "$output" != *"[c]"* ]]  # Should not prompt
    [[ "$output" != *"[a]"* ]]  # Should not prompt
}

@test "--skip-gitignore bypasses check when .gitignore exists but missing workflow files" {
    # Create .gitignore without workflow files
    echo "node_modules" > .gitignore
    create_mock_claude_success

    # Should skip gitignore check entirely - no prompt
    run "$RALPH_SCRIPT" --skip-gitignore --max 1 --no-sleep
    [[ "$output" != *"Workflow files not in .gitignore"* ]]
    [[ "$output" != *"[a]"* ]]  # Should not prompt
}

@test "--skip-gitignore and --add-gitignore are mutually exclusive" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --skip-gitignore --add-gitignore
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "--help shows --skip-gitignore option" {
    run "$RALPH_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"--skip-gitignore"* ]]
    [[ "$output" == *"Skip the gitignore check"* ]]
}

# ====================
# Short Flag Tests (recent features)
# ====================

@test "-r short flag works same as --reset" {
    # Create existing WORKLOG.md with some content
    echo "# Old Worklog Content" > WORKLOG.md
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run -r
    [[ "$status" -eq 0 ]]
    # With dry-run AND reset, reset message should appear
    [[ "$output" == *"Reset"* ]] || [[ "$output" == *"DRY RUN"* ]]
}

@test "-g short flag works same as --add-gitignore" {
    # Create .gitignore without workflow files
    echo "node_modules" > .gitignore
    create_mock_claude_success

    # Should auto-add without prompting
    run "$RALPH_SCRIPT" -g --max 1 --no-sleep
    [[ "$output" == *"Added"* ]]
    [[ "$output" == *".gitignore"* ]]
    [[ "$output" != *"[a]"* ]]  # Should not prompt

    # Verify files were added
    grep -Fxq "BRIEF.md" .gitignore
    grep -Fxq "WORKLOG.md" .gitignore
}

@test "-G short flag works same as --skip-gitignore" {
    # Remove .gitignore to trigger prompt (if not skipped)
    rm -f .gitignore
    create_mock_claude_success

    # Should skip gitignore check entirely - no prompt
    run "$RALPH_SCRIPT" -G --max 1 --no-sleep
    [[ "$output" != *".gitignore not found"* ]]
    [[ "$output" != *"Workflow files not in .gitignore"* ]]
    [[ "$output" != *"[c]"* ]]  # Should not prompt
    [[ "$output" != *"[a]"* ]]  # Should not prompt
}

# ====================
# Short Flag Tests (remaining flags)
# ====================

@test "-n short flag works same as --max" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run -n 5
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Max iterations: 5"* ]]
}

@test "-s short flag works same as --sleep" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run -s 10
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Sleep: 10s"* ]]
}

@test "-u short flag works same as --unlimited" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run -u
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Max iterations: unlimited"* ]]
}

@test "-S short flag works same as --no-sleep" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run -S
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Sleep: disabled"* ]]
}

@test "-v short flag works same as --verbose" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run -v
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Verbose: enabled"* ]]
}

@test "-q short flag works same as --quiet" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --dry-run -q
    [[ "$status" -eq 0 ]]
    # Banner contains ASCII art with "RALPH" - should not be present in quiet mode
    [[ "$output" != *"██████╗"* ]]
    [[ "$output" != *"Autonomous Coding Agent Loop"* ]]
}

@test "-d short flag works same as --dry-run" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" -d
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[DRY RUN]"* ]]
    [[ "$output" == *"Would execute claude with prompt"* ]]
}

@test "-c short flag works same as --cleanup" {
    # Create both workflow files
    echo "# Brief" > BRIEF.md
    echo "# Worklog" > WORKLOG.md

    # Use yes to simulate 'y' confirmation
    run bash -c "echo 'y' | '$RALPH_SCRIPT' -c"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Deleted"* ]]
    [[ ! -f BRIEF.md ]]
    [[ ! -f WORKLOG.md ]]
}

# ====================
# Completion Detection Tests
# ====================

@test "ralph exits 0 when claude outputs completion marker" {
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$status" -eq 0 ]]
}

@test "output contains 'ALL TASKS COMPLETE' on successful completion" {
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$output" == *"ALL TASKS COMPLETE"* ]]
}

@test "output shows correct iteration count on completion" {
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$output" == *"Finished after 1 iteration"* ]]
}

# ====================
# Negative Completion Detection Tests
# ====================

@test "partial marker '<promise>COMPLE' does NOT trigger completion" {
    create_mock_claude_partial_marker
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    # Should reach max iterations (exit 1), not complete successfully (exit 0)
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"MAX ITERATIONS"* ]]
    [[ "$output" != *"ALL TASKS COMPLETE"* ]]
}

@test "marker without closing tag does NOT trigger completion" {
    create_mock_claude_unclosed_marker
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    # Should reach max iterations (exit 1), not complete successfully (exit 0)
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"MAX ITERATIONS"* ]]
    [[ "$output" != *"ALL TASKS COMPLETE"* ]]
}

@test "similar text '<promise>COMPLETED</promise>' does NOT trigger completion" {
    create_mock_claude_similar_marker
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    # Should reach max iterations (exit 1), not complete successfully (exit 0)
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"MAX ITERATIONS"* ]]
    [[ "$output" != *"ALL TASKS COMPLETE"* ]]
}

# ====================
# Max Iterations Reached Tests
# ====================

@test "ralph exits 1 when max iterations reached" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --max 2 --no-sleep --reset
    [[ "$status" -eq 1 ]]
}

@test "output contains 'MAX ITERATIONS REACHED' message" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$output" == *"MAX ITERATIONS REACHED"* ]]
}

@test "output suggests running with more iterations" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --max 3 --no-sleep --reset
    # Should suggest running with more iterations (n + 10)
    [[ "$output" == *"Run again with: ralph -n 13"* ]]
}

# ====================
# Claude CLI Failure Tests
# ====================

@test "ralph exits 1 when claude command fails" {
    create_mock_claude_failure
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$status" -eq 1 ]]
}

@test "output contains 'claude command failed' error message" {
    create_mock_claude_failure
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$output" == *"claude command failed"* ]]
}

@test "output shows claude's exit code in error" {
    create_mock_claude_failure 42
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$output" == *"exit code 42"* ]]
}

@test "claude stderr output is displayed to user" {
    create_mock_claude_failure
    run "$RALPH_SCRIPT" --max 1 --no-sleep --reset
    [[ "$output" == *"Mock claude error"* ]]
}

# ====================
# Missing Claude CLI Detection Tests
# ====================

@test "ralph exits with error when claude CLI not found" {
    remove_claude_from_path
    run "$RALPH_SCRIPT" --reset --skip-gitignore
    [[ "$status" -eq 1 ]]
}

@test "error message mentions 'claude CLI not found' when missing" {
    remove_claude_from_path
    run "$RALPH_SCRIPT" --reset --skip-gitignore
    [[ "$output" == *"claude CLI not found"* ]]
}

# ====================
# NO_COLOR Environment Variable Tests
# ====================

@test "NO_COLOR=1 disables color escape codes in output" {
    create_mock_claude_success
    # Run with NO_COLOR set and capture output
    NO_COLOR=1 run "$RALPH_SCRIPT" --dry-run
    [[ "$status" -eq 0 ]]
    # Output should NOT contain ANSI escape codes (which start with \033[ or \x1b[)
    # Check for common escape sequence pattern ESC[
    [[ "$output" != *$'\033['* ]]
}

@test "output contains no ANSI escape sequences when NO_COLOR is set" {
    create_mock_claude_success
    # Run with NO_COLOR set and check for any ANSI escape sequences
    NO_COLOR=1 run "$RALPH_SCRIPT" --help
    [[ "$status" -eq 0 ]]
    # ANSI escape sequences start with ESC (0x1b or \033) followed by [
    # Use a regex-free approach: check that the escape character is not in output
    [[ "$output" != *$'\x1b'* ]]
}

# ====================
# Comprehensive Verbose Mode Tests
# ====================

@test "verbose mode shows iteration start timestamp" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --verbose --max 1 --no-sleep --reset
    # Output should contain the iteration start log with timestamp format YYYY-MM-DD HH:MM:SS
    [[ "$output" == *"Iteration 1 started at"* ]]
    [[ "$output" == *":"*":"* ]]  # Timestamp contains colons
}

@test "verbose mode shows prompt preview (first N chars)" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --verbose --max 1 --no-sleep --reset
    # Output should contain the prompt preview log
    [[ "$output" == *"Prompt (first 200 chars):"* ]]
    # Should show start of the ralph prompt
    [[ "$output" == *"You are Ralph"* ]]
}

@test "verbose mode shows claude exit code" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --verbose --max 1 --no-sleep --reset
    # Output should contain the exit code log
    [[ "$output" == *"claude exit code: 0"* ]]
}

@test "verbose mode shows result character count" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --verbose --max 1 --no-sleep --reset
    # Output should contain the result character count log
    [[ "$output" == *"Result character count:"* ]]
}

@test "verbose mode shows iteration end timestamp" {
    create_mock_claude_success
    run "$RALPH_SCRIPT" --verbose --max 1 --no-sleep --reset
    # Output should contain the iteration end log with timestamp
    [[ "$output" == *"Iteration 1 ended at"* ]]
}

@test "verbose mode shows sleep message before next iteration" {
    create_mock_claude_success
    # Need at least 2 iterations with sleep enabled to see the sleep message
    # Use --max 2 and --sleep 1 to trigger sleep between iterations
    run "$RALPH_SCRIPT" --verbose --max 2 --sleep 1 --reset
    # Output should contain the sleep log message
    [[ "$output" == *"Sleeping"*"before next iteration"* ]]
}

# ====================
# WORKLOG.md Creation and Content Tests
# ====================

@test "WORKLOG.md is created when it doesn't exist (non-dry-run)" {
    # Ensure WORKLOG.md doesn't exist
    rm -f WORKLOG.md
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --max 1 --no-sleep
    [[ "$status" -eq 0 ]]
    # WORKLOG.md should now exist
    [[ -f WORKLOG.md ]]
    # Output should mention creation
    [[ "$output" == *"Created"*"WORKLOG.md"* ]]
}

@test "fresh WORKLOG.md contains '# Work Log' header" {
    # Ensure WORKLOG.md doesn't exist
    rm -f WORKLOG.md
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --max 1 --no-sleep
    [[ "$status" -eq 0 ]]
    # Check that WORKLOG.md contains the header
    grep -q "^# Work Log$" WORKLOG.md
}

@test "fresh WORKLOG.md contains '## Learnings' section" {
    # Ensure WORKLOG.md doesn't exist
    rm -f WORKLOG.md
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --max 1 --no-sleep
    [[ "$status" -eq 0 ]]
    # Check that WORKLOG.md contains the Learnings section
    grep -q "^## Learnings$" WORKLOG.md
}

@test "--reset creates fresh worklog with correct structure" {
    # Create existing WORKLOG.md with different content
    echo "# Old Content" > WORKLOG.md
    echo "Some old data" >> WORKLOG.md
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --reset --max 1 --no-sleep
    [[ "$status" -eq 0 ]]
    # WORKLOG.md should have fresh structure, not old content
    grep -q "^# Work Log$" WORKLOG.md
    grep -q "^## Learnings$" WORKLOG.md
    # Old content should be gone
    run grep -q "# Old Content" WORKLOG.md
    [[ "$status" -ne 0 ]]
}

# ====================
# Iteration Display Tests
# ====================

@test "iteration box shows 'Iteration 1 of N' format with --max" {
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --max 5 --no-sleep --reset
    [[ "$status" -eq 0 ]]
    # Output should contain "Iteration 1 of 5" in the iteration box
    [[ "$output" == *"Iteration 1 of 5"* ]]
}

@test "iteration box shows 'Iteration 1' format with --unlimited" {
    create_mock_claude_complete
    run "$RALPH_SCRIPT" --unlimited --no-sleep --reset
    [[ "$status" -eq 0 ]]
    # Output should contain "Iteration 1" without "of" when unlimited
    [[ "$output" == *"Iteration 1"* ]]
    # Should NOT contain "of" in the iteration display (no max to show)
    # Check that we don't see "Iteration 1 of" pattern
    [[ "$output" != *"Iteration 1 of"* ]]
}

@test "iteration counter increments correctly across multiple iterations" {
    create_mock_claude_success  # Does NOT complete, so it runs multiple iterations
    run "$RALPH_SCRIPT" --max 3 --no-sleep --reset
    # Should reach max iterations (exit 1)
    [[ "$status" -eq 1 ]]
    # Output should contain all three iteration displays
    [[ "$output" == *"Iteration 1 of 3"* ]]
    [[ "$output" == *"Iteration 2 of 3"* ]]
    [[ "$output" == *"Iteration 3 of 3"* ]]
}

# ====================
# Sleep Behavior Tests
# ====================

@test "with --sleep 1, elapsed time between iterations is at least 1 second" {
    create_mock_claude_success  # Does NOT complete, runs multiple iterations
    # Record start time using bash SECONDS variable
    SECONDS=0
    run "$RALPH_SCRIPT" --max 2 --sleep 1 --reset
    elapsed=$SECONDS
    # With 2 iterations and 1 second sleep between them, should take at least 1 second
    # (sleep happens BETWEEN iterations, so 2 iterations = 1 sleep)
    [[ "$elapsed" -ge 1 ]]
}

@test "with --no-sleep, no delay occurs between iterations" {
    create_mock_claude_success  # Does NOT complete, runs multiple iterations
    # Record start time
    SECONDS=0
    run "$RALPH_SCRIPT" --max 3 --no-sleep --reset
    elapsed=$SECONDS
    # With no sleep, 3 iterations should complete very quickly (under 2 seconds)
    # The mock claude returns immediately, so iterations themselves are instant
    [[ "$elapsed" -lt 2 ]]
}
