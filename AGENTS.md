# AGENTS.md

Instructions for AI coding assistants working on this project. Read `PROJECT_PLAN.md` for full project context.

## Git Commits

**NEVER** make a git commit without prompting the user first.

## Development Workflow

Follow test-driven development:

1. Write unit tests first. Stub them out so there are no errors, but tests fail.
2. Iterate on the implementation until tests pass.
3. Verify all tests pass.
4. Run the linter and type checker after every edit.
5. Test manually with `nix run`.
6. Run tests, linter, formatter, and type checker before committing.

## Testing

### Running All Tests

To run the complete test suite:

```sh
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedDirectory tests' -c 'qa!'
```

Or run individual test files:

```sh
# Run core module tests
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedFile tests/lua/davewiki/core_spec.lua' -c 'qa!'

# Run init module tests
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedFile tests/lua/davewiki/init_spec.lua' -c 'qa!'

# Run cmp module tests
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedFile tests/lua/davewiki/cmp_spec.lua' -c 'qa!'
```

### Test Commands Reference

- **Always use the minimal init:** `-u scripts/minimal-init.lua`
- **Run all tests:** `PlenaryBustedDirectory tests`
- **Run specific file:** `PlenaryBustedFile tests/lua/davewiki/core_spec.lua`
- **Run directory:** `PlenaryBustedDirectory tests/lua/davewiki`
- **Always end with:** `-c 'qa!'` to exit after tests complete

### Current Test Suite

- `tests/lua/davewiki/core_spec.lua` - Core module tests (wiki_root resolution, tag management, markdown hyperlink support)
- `tests/lua/davewiki/init_spec.lua` - Init module tests (public API)
- `tests/lua/davewiki/cmp_spec.lua` - Cmp module tests (nvim-cmp tag completion)
- Total: 82 tests covering all implemented features

### Testing Rules

- **Never mock** vim internal functions or filesystem operations unless there is no alternative.
- Tests run against **real files** in `test_root/` — no mocking the filesystem.
- Tests must use `test_root` as the `wiki_root` and **never access files outside it**.

### Test File Structure

- **Directory layout:** Tests mirror the `lua/` folder structure under `tests/lua/`
- **File naming:** Append `_spec.lua` to the corresponding module name
- **Examples:**
  - `lua/davewiki/init.lua` → `tests/lua/davewiki/init_spec.lua`
  - `lua/davewiki/core.lua` → `tests/lua/davewiki/core_spec.lua`

## Code Quality

- All Lua code must include **type annotations**.
- Type checking via lua-language-server must pass.
- Follow lua-language-server (LuaLS) naming conventions.
- Run `luacheck` (linter) and `stylua` (formatter) before committing.

### Documentation

- **Lua files:** Module-level and file-level docstrings. Function docstrings with type annotations.
- **Nix files:** File-level descriptions and inline comments.
- **Tests:** Clearly describe intent — what is being tested, why, and why this approach.

## Security Rules

- Use `vim.system` for **all** shell command execution.
- **Escape/encode** all user input (tag names, file paths, search queries) when used in shell commands.
- Validate tag names against `#[A-Za-z0-9-_]+` (at word boundaries).
- URL-encode markdown hyperlink target paths.
- The plugin must **only** access files under the configured `wiki_root`.

## Antipatterns to Avoid

1. **Over-mocking in unit tests** — produces passing tests for incorrect code. Use real `test_root/` files.
2. **Requiring third-party modules at import time** — causes unnecessary startup errors. Load third-party Lua modules just before use (at setup time, not import time).

## Pre-Commit Review

Before committing, spawn a subagent to run a code review. The review should check for:

- Correctness
- Consistency with existing code
- Best practices
- Test coverage
- Security concerns
- Duplication and opportunities for reuse
- Tests that mock the filesystem instead of using `test_root`
- Shell commands vulnerable to injection

## Documentation Consistency

Use the `documentation-consistency` skill to check that README.md, PROJECT_PLAN.md, and AGENTS.md are consistent with each other and with the actual project state. Run this skill when making changes that affect project structure, conventions, or features.

## Commit Conventions

- Use **Conventional Commits** format.
- Use **feature branches** merged to main.

## GitHub Operations

Use `nix run .#gh` for all GitHub CLI operations (issues, PRs, releases):

```sh
nix run .#gh -- pr create --title "feat: add new feature" --body "$(cat <<'EOF'
## Summary
- New feature description
EOF
)"
```
