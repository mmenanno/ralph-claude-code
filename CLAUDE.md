# Ralph - Claude Code Project Context

## Development Commands

```bash
# Run tests
bats test/

# Run linting
./scripts/lint.sh

# Run both
bats test/ && ./scripts/lint.sh
```

## Project Structure

- `ralph` - Main bash script (autonomous coding agent loop)
- `skill/brief/SKILL.md` - /brief skill definition for Claude Code
- `test/ralph.bats` - BATS test suite
- `test/test_helper.bash` - Test fixtures and utilities
- `scripts/lint.sh` - ShellCheck wrapper

## Code Conventions

- All bash code must pass ShellCheck (no warnings)
- Use strict mode: `set -euo pipefail`
- Quote all variable expansions: `"$var"`
- Use `[[ ]]` for conditionals (not `[ ]`)
- Respect `NO_COLOR` environment variable for colored output
- Use `local` for function variables

## Testing Patterns

- BATS framework used for testing
- Tests run in isolated temp directories (setup/teardown in test_helper.bash)
- Mock claude commands available:
  - `create_mock_claude_success` - Mock that exits 0
  - `create_mock_claude_failure` - Mock that exits with error
  - `create_mock_claude_blocking` - Mock that blocks (for signal testing)

## Files Used by Ralph

- `BRIEF.md` - Task specification (required input)
- `WORKLOG.md` - Progress log (auto-created)
- `CLAUDE.md` - Project patterns (optional, updated by ralph)

## Documentation Maintenance

**Keep documentation in sync with code changes.** When adding or modifying features:

- Update `README.md` Options table and Examples section for new/changed flags
- Update `ralph --help` output (in the `usage()` function) to match
- Update `CONTRIBUTING.md` if development workflows change
- Ensure all three sources (README, --help, script behavior) stay consistent
