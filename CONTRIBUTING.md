# Contributing to Ralph

Thank you for your interest in contributing to Ralph! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

Before you start, ensure you have the following installed:

- **Bash 4.0+** - Ralph requires modern bash features
  - macOS ships with Bash 3.x; upgrade with `brew install bash`
  - Check your version with `bash --version`
- **[Claude CLI](https://docs.anthropic.com/en/docs/claude-cli)** - Required for running ralph
- **[ShellCheck](https://www.shellcheck.net/)** - For linting
  - Install with `brew install shellcheck` (macOS) or `apt install shellcheck` (Ubuntu)
- **[BATS](https://github.com/bats-core/bats-core)** - Bash Automated Testing System
  - Install with `brew install bats-core` (macOS) or see [installation docs](https://bats-core.readthedocs.io/en/stable/installation.html)

### Cloning the Repository

```bash
git clone https://github.com/mmenanno/ralph-claude-code.git
cd ralph-claude-code
```

### Project Structure

```text
ralph-claude-code/
├── ralph                 # Main script
├── test/
│   ├── ralph.bats        # BATS test suite
│   └── test_helper.bash  # Test utilities
├── scripts/
│   └── lint.sh           # ShellCheck wrapper
├── skill/
│   └── brief/            # /brief skill for Claude Code
├── .github/
│   └── workflows/
│       └── ci.yml        # GitHub Actions CI
├── LICENSE               # MIT License
├── README.md             # Project documentation
└── CONTRIBUTING.md       # This file
```

## Running Tests

Ralph uses the [BATS](https://github.com/bats-core/bats-core) testing framework. Tests are located in `test/ralph.bats`.

### Run All Tests

```bash
bats test/
```

### Run a Specific Test

```bash
bats test/ralph.bats --filter "test name pattern"
```

### Test Output

Successful output looks like:

```text
 ✓ ralph script exists and is executable
 ✓ --max with non-numeric value exits with error
 ✓ --help exits with code 0
 ...

17 tests, 0 failures
```

## Linting

Ralph uses [ShellCheck](https://www.shellcheck.net/) for static analysis. A wrapper script is provided for convenience.

### Run Linting

```bash
./scripts/lint.sh
```

### What Gets Checked

The lint script checks:

- `ralph` - Main script
- `test/ralph.bats` - Test suite
- `test/test_helper.bash` - Test utilities

### Successful Output

```text
Running ShellCheck on ralph project...

Checking ralph... OK
Checking test/ralph.bats... OK
Checking test/test_helper.bash... OK

All files passed ShellCheck!
```

## Code Style

### ShellCheck Compliance

All bash code must pass ShellCheck without warnings. Common issues to avoid:

- **SC2086** - Quote variables to prevent word splitting: `"$var"` not `$var`
- **SC2046** - Quote command substitutions: `"$(cmd)"` not `$(cmd)`
- **SC2164** - Use `cd ... || exit` or `set -e` to handle cd failures

### Bash Best Practices

1. **Use strict mode** - Start scripts with:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   ```

2. **Quote variables** - Always quote variable expansions:

   ```bash
   echo "$variable"    # Good
   echo $variable      # Bad - may cause issues with spaces
   ```

3. **Use `[[` for conditionals** - More robust than `[`:

   ```bash
   if [[ "$var" == "value" ]]; then
   ```

4. **Use meaningful function names** - Prefix internal functions with descriptive names:

   ```bash
   log_error() { ... }
   log_success() { ... }
   ```

5. **Respect NO_COLOR** - Honor the [NO_COLOR](https://no-color.org/) environment variable:

   ```bash
   if [[ -z "${NO_COLOR:-}" ]]; then
       RED=$'\033[0;31m'
   else
       RED=''
   fi
   ```

6. **Use local variables in functions** - Prevent namespace pollution:

   ```bash
   my_function() {
       local var="value"
   }
   ```

## Submitting Pull Requests

### Before Submitting

1. **Ensure tests pass** - Run `bats test/`
2. **Ensure linting passes** - Run `./scripts/lint.sh`
3. **Test your changes manually** - Try ralph with `--dry-run` flag
4. **Keep commits focused** - One logical change per commit

### PR Guidelines

1. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Write descriptive commit messages**

   ```text
   feat: add new flag for custom timeout

   - Add --timeout flag to specify iteration timeout
   - Update help text with new option
   - Add tests for timeout validation
   ```

3. **Update documentation** if adding new features or changing behavior

4. **Open a PR against `main`** with:
   - Clear description of what changes
   - Why the change is needed
   - How to test the changes

### Commit Message Format

Use conventional commit style:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation only changes
- `test:` - Adding or updating tests
- `refactor:` - Code changes that neither fix bugs nor add features
- `style:` - Formatting, whitespace changes
- `chore:` - Maintenance tasks

## Reporting Issues

### Before Opening an Issue

1. **Check existing issues** - Your issue may already be reported
2. **Use latest version** - Ensure you're on the latest version of ralph

### What to Include

When reporting a bug:

- **Ralph version** - Output of `git rev-parse --short HEAD`
- **Bash version** - Output of `bash --version`
- **OS and version** - e.g., macOS 14.0, Ubuntu 22.04
- **Steps to reproduce** - Minimal steps to reproduce the issue
- **Expected behavior** - What you expected to happen
- **Actual behavior** - What actually happened
- **Relevant logs** - Any error messages or output

### Example Issue

```markdown
## Bug: Ralph exits with error on valid BRIEF.md

**Environment:**
- Ralph: abc1234
- Bash: 5.2.15
- OS: macOS 14.0

**Steps to reproduce:**
1. Create BRIEF.md with a single task
2. Run `ralph --dry-run`

**Expected:** Dry run completes successfully
**Actual:** Error message: "..."

**Logs:**
(paste relevant output)
```

## Questions?

If you have questions that aren't covered here, feel free to open an issue with the "question" label.
