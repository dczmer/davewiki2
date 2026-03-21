# AGENTS.md

Instructions for AI coding assistants working on this project. Read `PROJECT_PLAN.md` for full project context.

## Development Workflow

Follow test-driven development:

1. Write unit tests first. Stub them out so there are no errors, but tests fail.
2. Iterate on the implementation until tests pass.
3. Verify all tests pass.
4. Run the linter and type checker after every edit.
5. Test manually with `nix run`.
6. Run tests, linter, formatter, and type checker before committing.

## Testing

Run tests with:

```sh
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c ...
```

- Always use the minimal init: `-u scripts/minimal-init.lua`
- Use `-c` to pass commands: `lua` for statements, `luafile` to source files

### Testing Rules

- **Never mock** vim internal functions or filesystem operations unless there is no alternative.
- Tests run against **real files** in `test_root/` — no mocking the filesystem.
- Tests must use `test_root` as the `wiki_root` and **never access files outside it**.

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

Keep `README.md`, `PROJECT_PLAN.md`, and `AGENTS.md` consistent with each other and with the actual state of the project. When making changes that affect project structure, conventions, or features, update all three documents.

## Commit Conventions

- Use **Conventional Commits** format.
- Use **feature branches** merged to main.