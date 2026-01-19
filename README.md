# Ralph

[![CI](https://github.com/mmenanno/ralph-claude-code/actions/workflows/ci.yml/badge.svg)](https://github.com/mmenanno/ralph-claude-code/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/shell-bash-blue.svg)](https://www.gnu.org/software/bash/)

An autonomous coding agent loop for Claude Code.

## What is Ralph?

Ralph is my take on the [original Ralph concept](https://ghuntley.com/ralph/) by Geoffrey Huntley. After seeing various implementations of autonomous coding agent loops, I refined the approach to work better for my own workflow.

At its core, Ralph is a bash script that creates an autonomous coding loop with Claude Code. Instead of manually prompting Claude for each change, Ralph manages an iterative workflow where Claude:

1. Reads a task specification from a brief file
2. Implements one task at a time
3. Validates work with tests and linting
4. Commits successful changes
5. Logs progress for future iterations
6. Continues until all tasks are complete

This allows you to define a set of tasks upfront and let Claude work through them autonomously, learning from each iteration and building context as it goes. By starting fresh each iteration while preserving learnings in the worklog, Ralph significantly reduces context rot that occurs in long-running sessions.

## How It Works

```text
┌─────────────────────────────────────────────────────────────┐
│                     Ralph Iteration Loop                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Read BRIEF.md   │
                    │  Find first [ ]  │
                    └─────────┬────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Read WORKLOG.md  │
                    │ Check learnings  │
                    └─────────┬────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Execute task   │
                    │  (one at a time) │
                    └─────────┬────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │     Validate     │
                    │  tests/lint/type │
                    └─────────┬────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
     ┌────────────────┐              ┌────────────────┐
     │   PASS         │              │   FAIL         │
     │ Mark [x]       │              │ Leave [ ]      │
     │ Commit changes │              │ Log learnings  │
     │ Log success    │              │ Next iteration │
     └────────┬───────┘              └────────┬───────┘
              │                               │
              └───────────────┬───────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  All tasks [x]?  │
                    └─────────┬────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
     ┌────────────────┐              ┌────────────────┐
     │      YES       │              │       NO       │
     │    COMPLETE    │              │ Next iteration │
     └────────────────┘              └────────────────┘
```

**Key Features:**

- **One task per iteration**: Focused, incremental progress
- **Self-validating**: Only commits if tests/lint pass
- **Learning loop**: Failed attempts inform future iterations via WORKLOG.md
- **Interruptible**: Ctrl+C cleanly stops the loop
- **Configurable**: Adjust iterations, sleep time, verbosity

## Prerequisites

- **Bash 4.0+**: Ralph uses modern bash features (`set -euo pipefail`, `[[ ]]` conditionals)
  - macOS: Install via Homebrew (`brew install bash`) - the system bash is v3.x
  - Linux: Usually already installed
  - Check version: `bash --version`

- **Claude Code CLI**: The `claude` command must be available in your PATH
  - Install from: <https://docs.anthropic.com/en/docs/claude-code>
  - Verify: `claude --version`

- **timeout command**: Used for iteration timeouts
  - macOS: Install via Homebrew (`brew install coreutils`) - provides `gtimeout`
  - Linux: Usually already installed as `timeout`
  - Verify: `timeout --version` or `gtimeout --version`

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/mmenanno/ralph-claude-code.git
   cd ralph-claude-code
   ```

2. **Make ralph executable:**

   ```bash
   chmod +x ralph
   ```

3. **Add to PATH** (choose one method):

   **Option A: Symlink to a directory in PATH**

   ```bash
   ln -s "$(pwd)/ralph" /usr/local/bin/ralph
   ```

   **Option B: Add project directory to PATH**

   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/ralph-claude-code"
   ```

4. **Install the brief skill** (optional but recommended):

   The `/brief` skill helps Claude Code generate well-structured briefs for Ralph. Symlink the skill directory to your Claude Code skills folder:

   ```bash
   mkdir -p ~/.claude/skills
   ln -s "$(pwd)/skill/brief" ~/.claude/skills/brief
   ```

5. **Verify installation:**

   ```bash
   ralph --help
   ```

## Quick Start

1. **Navigate to your project:**

   ```bash
   cd your-project
   ```

2. **Create a BRIEF.md** with your tasks:

   **Option A: Use the `/brief` skill** (recommended)

   If you installed the skill, run Claude Code and use the `/brief` command:

   ```bash
   claude
   # Then type: /brief
   ```

   The `/brief` skill guides you through creating a well-structured brief optimized for Ralph:

   - **Interactive requirements gathering**: Uses the `AskUserQuestion` tool to ask 1-4 clarifying questions at a time, continuing until all ambiguity is resolved
   - **Existing file detection**: Checks if `BRIEF.md` already exists and prompts you to overwrite, stop, or provide an alternative filename
   - **Task scoping**: Ensures each task fits within a single iteration context window—oversized tasks are decomposed into smaller, atomic units
   - **Dependency ordering**: Sequences tasks correctly (data layer → logic → UI) so no task depends on something defined later
   - **Verifiable criteria**: Every acceptance criterion is objectively checkable, with required "Testing passes" and "Linting passes" items on each task
   - **Pre-save validation**: Confirms the brief follows all best practices before writing to disk

   **Option B: Write manually** (use markdown checkboxes)

   ```markdown
   # Brief: My Feature

   ## Tasks

   ### TASK-001: Implement the thing
   - [ ] Create the module
   - [ ] Add tests
   - [ ] Linting passes
   ```

3. **Run ralph:**

   ```bash
   ralph
   ```

4. **Watch it work** - Ralph will iterate through tasks, committing as it goes. Check `WORKLOG.md` for progress.

## Usage

```text
ralph [OPTIONS]
```

### Options

| Flag | Long Form | Description |
| ------ | ----------- | ------------- |
| `-n` | `--max NUM` | Maximum iterations (default: 10) |
| `-u` | `--unlimited` | No iteration limit (run until complete) |
| `-s` | `--sleep SECS` | Seconds between iterations (default: 3) |
| `-S` | `--no-sleep` | Disable sleep between iterations |
| `-r` | `--reset` | Reset worklog (don't prompt, just overwrite) |
| `-k` | `--keep` | Keep existing worklog (don't prompt, just continue) |
| `-c` | `--cleanup` | Delete BRIEF.md and WORKLOG.md (with confirmation) |
| `-f` | `--force` | Skip confirmation prompts (use with --cleanup) |
| `-g` | `--add-gitignore` | Auto-add workflow files to .gitignore |
| `-G` | `--skip-gitignore` | Skip the gitignore check entirely |
| `-v` | `--verbose` | Show additional debug information |
| `-q` | `--quiet` | Suppress banner and configuration output |
| `-d` | `--dry-run` | Preview execution without running claude |
| `-h` | `--help` | Show this help message |

### Examples

```bash
# Run with defaults (10 iterations, 3s sleep between each)
ralph

# Run up to 20 iterations
ralph -n 20

# Run unlimited iterations until all tasks complete
ralph -u

# Run with 5 second pause between iterations
ralph -s 5

# Run with no pause between iterations (fastest)
ralph -S

# Reset worklog and start fresh (useful for re-running)
ralph -r

# Keep existing worklog and continue where you left off
ralph -k

# Clean up workflow files after completing a task
ralph --cleanup

# Clean up without confirmation prompt
ralph --cleanup -f

# Auto-add workflow files to .gitignore on startup
ralph --add-gitignore

# Skip the gitignore check entirely
ralph --skip-gitignore

# Run with minimal output
ralph -q

# Preview what would happen without actually running claude
ralph -d

# Combine flags: unlimited iterations, no sleep, verbose output
ralph -u -S -v
```

### Exit Codes

| Code | Meaning |
| ------ | --------- |
| `0` | All tasks completed successfully |
| `1` | Error or max iterations reached |
| `130` | Interrupted by user (Ctrl+C) |

## Files

Ralph uses three files to manage the autonomous coding loop:

### BRIEF.md (Required)

The task specification file. Contains your project brief with tasks formatted as markdown checkboxes:

```markdown
# Brief: Feature Name

## Tasks

### TASK-001: First task
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
- [ ] Tests pass

### TASK-002: Second task
- [ ] Acceptance criterion 1
- [ ] Tests pass
```

**Key points:**

- Use `- [ ]` for incomplete items, `- [x]` for completed items
- Ralph finds the first unchecked `[ ]` and works on that task
- When all checkboxes are `[x]`, Ralph considers the brief complete

### WORKLOG.md (Auto-created)

Progress log created automatically by Ralph. Contains:

- **Learnings section**: Patterns discovered during implementation
- **Iteration entries**: What was done, files changed, and context for future iterations

Example structure:

```markdown
# Work Log

## Learnings
- Tests use BATS framework: run with `bats test/`
- Config is loaded from ~/.myapprc

---

## Iteration 1 - TASK-001: Create config module
- What was implemented: Config loading with defaults
- Files changed: src/config.js, test/config.test.js
- Learnings for future iterations:
  - Use dotenv for env vars
  - Config validates on load
---
```

**Key points:**

- Failed iterations log what went wrong so the next iteration can learn
- The learnings section persists across iterations
- Use `--reset` flag to start fresh

### CLAUDE.md (Optional)

Project-specific patterns and conventions. Ralph updates this file when it discovers reusable patterns that future work should know about.

Example entries:

```markdown
## Project Patterns

- This codebase uses Jest for testing, run with `npm test`
- Always run `npm run lint` before committing
- Database migrations are in `db/migrations/`
```

## Workflow

### The Iteration Loop

Each Ralph iteration follows this protocol:

1. **Read BRIEF.md** - Find the first unchecked task (`[ ]`)
2. **Read WORKLOG.md** - Check learnings from prior iterations
3. **Execute task** - Implement exactly one task
4. **Validate** - Run tests, linting, and type checks
5. **On success** - Mark task `[x]`, commit changes, log success
6. **On failure** - Leave task `[ ]`, log what went wrong
7. **Check completion** - If all tasks `[x]`, output completion marker

### Completion Detection

Ralph knows tasks are complete when:

1. **All checkboxes marked**: Every `- [ ]` in BRIEF.md becomes `- [x]`
2. **Completion marker output**: Claude outputs `<promise>COMPLETE</promise>`

When Ralph detects the completion marker in Claude's output, it stops the loop and exits with code 0.

### Failure Recovery

If a task fails validation:

- The task checkbox remains unchecked (`[ ]`)
- Ralph logs what went wrong to WORKLOG.md
- The next iteration reads the failure context
- Ralph tries again with the new information

This learning loop allows Ralph to recover from failures by building context over multiple iterations.

## Development

Quick commands for development:

```bash
# Run tests
bats test/

# Run linting
./scripts/lint.sh

# Run both
bats test/ && ./scripts/lint.sh
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Development setup
- Running tests and linting
- Code style (ShellCheck compliance)
- Submitting pull requests
- Reporting issues

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
