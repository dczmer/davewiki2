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

# Run tags module tests
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedFile tests/lua/davewiki/tags_spec.lua' -c 'qa!'

# Run markdown module tests
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedFile tests/lua/davewiki/markdown_spec.lua' -c 'qa!'

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

- `tests/lua/davewiki/core_spec.lua` - Core module tests (wiki_root resolution, utility functions)
- `tests/lua/davewiki/tags_spec.lua` - Tags module tests (tag file management, tag operations)
- `tests/lua/davewiki/markdown_spec.lua` - Markdown module tests (markdown links, file operations)
- `tests/lua/davewiki/init_spec.lua` - Init module tests (public API)
- `tests/lua/davewiki/cmp_spec.lua` - Cmp module tests (nvim-cmp tag completion)
- `tests/lua/davewiki/telescope_spec.lua` - Telescope module tests (telescope.nvim integration)
- `tests/lua/davewiki/journal_spec.lua` - Journal module tests (daily journal management, telescope journal picker)
- `tests/lua/davewiki/view_spec.lua` - View module tests (synthetic tag view generation)
- Total: 273 tests covering all implemented features

### Testing Rules

- **Never mock** vim internal functions or filesystem operations unless there is no alternative.
- Tests run against **real files** in `test_root/` — no mocking the filesystem.
- Tests must use `test_root` as the `wiki_root` and **never access files outside it**.
- **Tests must run with zero warnings.** If a test triggers a warning because it exercises code that calls `vim.notify`, use `MockNotify` to capture and assert the notification message.

### Testing Warning Notifications

When testing code that produces user-facing warnings via `vim.notify`:

1. **Use `MockNotify`** from `davewiki.test_util` to capture notifications
2. **Set up in `before_each`** and restore in `after_each`
3. **Assert the notification** message and level in the test

Example:

```lua
local test_util = require("davewiki.test_util")

describe("module with warnings", function()
    local mock_notify
    local original_notify

    before_each(function()
        -- Set up MockNotify before each test
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        -- Always restore original vim.notify
        vim.notify = original_notify
    end)

    it("should notify on error condition", function()
        local result = some_function_that_warns()

        assert.is_false(result)
        assert.are.equal(1, #mock_notify.calls)
        assert.are.equal("davewiki: expected warning message", mock_notify.calls[1].msg)
        assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)  -- or vim.log.levels.WARN
    end)
end)
```

Note: Check the actual code to determine whether it uses `vim.log.levels.ERROR` (4) or `vim.log.levels.WARN` (3).

### Test File Management

When creating, reading, or modifying files in `test_root/` during tests:

1. **Do not modify or delete** files tracked by git (e.g., existing test fixtures)
2. **Use unique names** for each test's files to avoid collisions (e.g., `test-view-unique-*.md`, dates like `2099-01-15`)
3. **Cleanup only files created** by that test in `after_each` — never delete all files in a directory
4. **Create files before testing deletion** — if testing file deletion, create the file first
5. **Never add test files to git** — files created during tests should remain untracked
6. **Tests are broken if they fail from test pollution** — each test must be isolated and not depend on state from other tests

Example pattern for tracked cleanup:
```lua
local created_files = {}

local function track_file(filepath)
    created_files[filepath] = true
end

local function cleanup_created_files()
    for filepath, _ in pairs(created_files) do
        pcall(vim.fn.delete, filepath)
        created_files[filepath] = nil
    end
end

describe("some tests", function()
    after_each(function()
        cleanup_created_files()
    end)

    it("creates a file", function()
        local test_file = test_root .. "/unique-filename.md"
        vim.fn.writefile({ "content" }, test_file)
        track_file(test_file)
        -- assertions...
    end)
end)
```

### Test File Structure

- **Directory layout:** Tests mirror the `lua/` folder structure under `tests/lua/`
- **File naming:** Append `_spec.lua` to the corresponding module name
- **Examples:**
  - `lua/davewiki/init.lua` → `tests/lua/davewiki/init_spec.lua`
  - `lua/davewiki/core.lua` → `tests/lua/davewiki/core_spec.lua`

## Module Dependencies

**No circular dependencies between modules.** The module hierarchy must remain acyclic.

```
Level 0 (leaf):    core.lua, test_util.lua (no dependencies)
Level 1:           tags.lua, markdown.lua, journal.lua → core
Level 2:           cmp.lua → tags; view.lua → core, markdown, tags
Level 3:           telescope.lua → core, markdown, tags (lazy: view, journal)
Level 4 (root):    init.lua → cmp, core, journal, markdown, tags, telescope, view
```

All dependency paths terminate at `core.lua`. When adding new modules, maintain this layered structure.

## Code Quality

- All Lua code must include **type annotations**.
- Type checking via lua-language-server must pass.
- Follow lua-language-server (LuaLS) naming conventions.
- Run `luacheck` (linter) and `stylua` (formatter) before committing.
- **Avoid useless wrapper functions.** Do not create single-line functions that just call another function directly without adding any value. Use the underlying function instead.

### Keymaps and Autocommands

- All keymaps must include a `desc` property describing their function.
- All autocommands must include a `desc` property describing their function.
- Example:
  ```lua
  vim.keymap.set('n', '<leader>tw', function() require('davewiki').jump_to_tag() end, { desc = 'Jump to tag file under cursor' })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = "*.md",
    desc = "Show backlinks when entering a tag file",
    callback = function() ... end,
  })
  ```

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

Use the `documentation-consistency` skill to check that README.md, PROJECT_PLAN.md, AGENTS.md, and flake.nix are consistent with each other and with the actual project state. Run this skill when making changes that affect project structure, conventions, or features.

## Commit Conventions

- Use **Conventional Commits** format.
- Use **feature branches** merged to main.

## GitHub Operations

Use `gh` for all GitHub CLI operations (issues, PRs, releases):

```sh
nix run .#gh -- pr create --title "feat: add new feature" --body "$(cat <<'EOF'
## Summary
- New feature description
EOF
)"
```
