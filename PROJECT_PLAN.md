# Project Plan: davewiki

**Generated**: 2026-03-21
**Version**: 1.0
**Last Updated**: 2026-03-21

---

## Table of Contents
1. [Overview](#1-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture Overview](#3-architecture-overview)
4. [Development and Testing Process](#4-development-and-testing-process)
5. [Conventions and Rules](#5-conventions-and-rules)
6. [Security Considerations](#6-security-considerations)

---

## 1. Overview

**What it is:**
A neovim plugin implementing a personal knowledge base system with journal-based note-taking, similar to Logseq. It focuses on simplicity and command-line workflow for neovim users.

**Primary users/stakeholders:**
Command-line neovim users who want a simple journal-based note-taking system.

**Scope (IN):**
- Manages a directory of markdown-based note files and daily journals
- Manages "tags" (`#tag-name`) backed by flat files in the `sources/` directory, supporting search, jump-to-tag, and back-reference finding
- Markdown editing convenience features:
  - Jump to file for tag under cursor
  - Jump to target of markdown link under cursor
  - Auto-complete tags with nvim-cmp
  - Generate synthetic tag views aggregating all references to a tag
- Search for tags, headings, etc. across all files
- Integration with nvim-cmp and telescope.nvim

**Scope (OUT):**
- This is NOT a markdown LSP
- No HTML export/generation of documents

**Key context/constraints:**
- **Scale:** Small scale (tens to hundreds of notes) - personal use case
- **Tag format:** Flat tags (not hierarchical), stored as files under `sources/` directory within the `wiki_root`
- **Back-references:** Search-based reference finding (not full backlink tracking)

---

## 2. Tech Stack

**Languages:**
- Lua (LuaJIT bundled with neovim)
- Nix (for build/packaging and dev shell)

**Frameworks & Libraries:**

**Required:**
- Neovim 0.9+ - target platform
- nvim-cmp - tag auto-completion
- telescope.nvim - search UI
- plenary.nvim - testing utilities

**Optional:**
- cmp-buffer - buffer word completion source
- cmp-path - filesystem path completion source
- cmp-nvim-lsp - LSP completion source
- cmp-nvim-lsp-signature-help - LSP signature help
- telescope-fzf-native - FZF sorter for telescope
- vim-markdown - Markdown syntax and ftplugin
- which-key.nvim - keybinding help/discovery

**Build Tools:**
- Nix flakes - build, packaging, and reproducibility
- Nix dev shell - development environment

**Databases & Storage:**
- Filesystem only - notes stored as plain markdown files

**External Services:**
- None

**Development Tools:**
- luacheck - linting
- stylua - Lua formatter
- lua-language-server - type checking
- git - version control
- ripgrep - search utility
- fd - file finder
- lz.n - lazy loading support (optional for users)
- plenary.nvim tests - testing framework

**CI/CD:**
- None planned

**Versioning:**
- Semantic Versioning (Semver)

---

## 3. Architecture Overview

**System Components:**

1. **Lua Modules (in `lua/` directory):**
   - `davewiki/init.lua` - Public interface, provides `setup()` function
   - `davewiki/core.lua` - Core utilities (wiki_root, ripgrep wrapper, validation functions)
   - `davewiki/tags.lua` - Tag file management and tag operations
   - `davewiki/markdown.lua` - Markdown link and file operations
   - `davewiki/cmp.lua` - nvim-cmp integration
   - `davewiki/telescope.lua` - Telescope integration for tag and heading search
   - `davewiki/journal.lua` - Daily journal management and navigation
   - `davewiki/view.lua` - Synthetic tag view generation

2. **Tests:**
   - `tests/` - plenary.nvim test suite
   - `test_root/` directory - sample notes and tags for testing

4. **Scripts:**
   - `scripts/` - Testing and development scripts
   - `scripts/minimal-init.lua` - Minimal neovim config for testing (telescope and journal enabled)
   - `scripts/davewiki2-init.lua` - Full neovim config with all plugin features enabled

**Project Directory Structure:**
```
lua/                     (lua modules)
└── davewiki/
    ├── init.lua         (public interface)
    ├── core.lua         (utility functions)
    ├── tags.lua         (tag operations)
    ├── markdown.lua     (markdown operations)
    ├── cmp.lua
    ├── telescope.lua
    ├── journal.lua
    └── view.lua         (synthetic tag views)
tests/                   (plenary tests)
tests/lua/davewiki/      (test files mirroring lua/ structure)
test_root/               (example/test wiki)
scripts/                 (testing and dev scripts)
README.md
PROJECT_PLAN.md
AGENTS.md
flake.nix                (nix build configuration)
feature-plans/           (feature specification documents)
```

**Wiki Directory Structure (managed by plugin for users):**
```
wiki_root/               (configurable, e.g., ~/.davewiki)
├── journals/            (daily journal files)
├── notes/               (other notes)
├── sources/             (tag files)
└── attachments/         (optional attachments)
```

**Data Flow:**
- User takes notes in daily journals
- Journal notes broken into "blocks" separated by `---`
- Tags (`#tag-name`) in blocks associate those blocks with the tag
- Tag associations discovered via on-demand ripgrep search (no persisted index)
- Searching for tags finds all associated blocks/mentions across all files
- Tag files act as anchor files for quick jump and back-link references
- Non-journal notes stored in `notes/` directory (not managed by tag system but can mention tags)

**Key Design Decisions:**
1. Nix package for reproducible build with bundled standalone neovim instance - can still be installed as regular neovim plugin
2. Journal-based approach inspired by Logseq
3. Avoids Electron-based alternatives (Logseq, Obsidian), prefers vim keybindings and CLI
4. On-demand ripgrep search for tag associations (no persisted database/index)
5. Block-based organization with `---` delimiters

**Configuration Options:**
- `wiki_root` - root directory for all notes
- `telescope` - enable/configure telescope integration
- `cmp` - enable/configure nvim-cmp integration
- `journal` - enable/configure journal module

**Existing Patterns:**
- `davewiki.lua` exposes `setup()` function taking options table, returns initialized module
- Prefer runtime import errors over startup crashes - load third-party modules (telescope, cmp) at setup time, not import time

---

## 4. Development and Testing Process

**Environment Setup:**
1. **Nix users:** Run `nix develop` to enter development shell
2. **Non-Nix users:** Manually install:
   - neovim (0.9+)
   - Required plugins and dependencies
   - Add plugin to neovim's `rtp` setting

**Build Process:**
- `nix build .#nvim-test` - Build test neovim instance
- `nix build .#davewiki` - Build davewiki package

**Running Locally:**
- `nix run .#nvim-test` - Run test neovim instance
- `nix run .#davewiki` - Run davewiki application
- Or enter dev shell: `nix develop` then use `nvim-test` and `davewiki` commands

**Testing:**
- **Unit tests:** `nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c ...`
- **Integration tests:** Combined module/functionality testing
- **Manual testing:** `nix run .#nvim-test` to open an interactive neovim instance with davewiki pre-configured using `scripts/minimal-init.lua`. The minimal init includes a working example of jump-to-tag functionality bound to `<CR>` in markdown files.

**Testing Commands:**
- Always use minimal init: `-u scripts/minimal-init.lua`
- Use `PlenaryBustedFile` to run a specific test file
- Use `PlenaryBustedDirectory` to run all tests in a directory
- Always end with `-c 'qa!'` to exit after tests complete
- Example: `nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedFile tests/file_spec.lua' -c 'qa!'`

**Test Environment:**
- Tests run against **real files** in `test_root/` directory - no mocking
- Plugin only accesses files under `wiki_root`
- Tests must use `test_root` and never access files outside `wiki_root`

**Project Scripts Directory:**
- `scripts/` - Testing and development scripts
- `scripts/minimal-init.lua` - Minimal neovim config for testing and manual acceptance testing. Pre-configures davewiki with `test_root/` as wiki_root and includes a working example of `<CR>` keybinding for jump-to-tag functionality in markdown files.

**Debugging:**
1. Run linters and type checker
2. Run test code: `nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c "lua ..."`

**Linting/Formatting/Type Checking:**
- luacheck - Lua linter
- stylua - Lua formatter
- lua-language-server - Type checking (all code requires type annotations)

**Code Quality Requirements:**
- All Lua code must include type annotations
- Type checking via lua-language-server must pass

**Typical Workflows:**
1. Write unit tests first (stub out to avoid errors, but tests should fail)
2. Iterate on implementation until tests pass (testing against real files in `test_root/`, not mocks)
3. Verify all tests pass
4. Run linter and type checker after every edit
5. Test manually with `nix run`
6. Run tests, linter, formatter, type checker before committing

**Branching Strategy:**
- Feature branches merged to main

**Commit Message Format:**
- Conventional Commits specification

---

## 5. Conventions and Rules

**Code Organization:**
- Follow neovim plugin conventions
- Module structure as documented in Architecture Overview:
- `lua/davewiki/init.lua` - Public interface with `setup()`
   - `lua/davewiki/core.lua` - General utilities
   - `lua/davewiki/cmp.lua` - nvim-cmp integration
   - `lua/davewiki/telescope.lua` - Telescope integration
   - `lua/davewiki/journal.lua` - Daily journal management and navigation
   - `lua/davewiki/view.lua` - Synthetic tag view generation

**Naming Conventions:**
- Follow lua-language-server (LuaLS) naming conventions
- Type annotations for all functions and modules

**Documentation Standards:**
- **README.md** - Project overview and usage
- **PROJECT_PLAN.md** - Overall project plan document
- **AGENTS.md** - Instructions for AI coding assistants
- **Lua files:** Module and file-level docstrings, function docstrings with type annotations
- **Nix files:** File-level descriptions and inline comments
- **Tests:** Clear description of intent - what is being tested, why, and why this approach

**Code Review Practices:**
- Peer review via pull requests

**Antipatterns to Avoid:**
1. **Over-mocking in unit tests** - Can produce passing tests for incorrect code. Use real `test_root/` files instead.
2. **Requiring third-party modules at import time** - Raises unnecessary startup errors. Load third-party Lua just before use (at setup time, not import time).

**File/Folder Organization:**
```
davewiki/
├── lua/davewiki/        (lua modules)
├── tests/lua/davewiki/  (test files, mirroring lua/ structure)
├── test_root/           (example/test wiki)
├── scripts/             (testing and dev scripts)
├── README.md
├── PROJECT_PLAN.md
├── AGENTS.md
└── flake.nix            (nix build configuration)
```

---

## 6. Security Considerations

**Authentication:**
- Not applicable - this is a local neovim plugin with no authentication requirements

**Authorization:**
- Not applicable - operates within user's file system permissions

**File Access Security:**
- Plugin should **only** write or search files under the configured `wiki_root`
- Must not access files outside the configured wiki root directory
- Tests must use `test_root` and never access files outside `wiki_root`

**User Input Handling:**
1. **Tag names:** Must be validated against `#[A-Za-z0-9-_]+` (at word boundaries)
2. **Shell command execution:** Use `vim.system` for all shell commands (preferred method)
3. **Input escaping:** All user input (tag names, file paths, search queries) must be properly escaped or encoded when used in shell commands
4. **Markdown hyperlinks:** Target paths must be URL-encoded

**Known Vulnerabilities/Mitigations:**
- **Arbitrary shell execution:** Injection into shell commands for searching, or via tag names/file paths
  - Mitigation: Use `vim.system` for all shell command execution
  - Mitigation: Validate tag names against strict regex pattern
  - Mitigation: Always escape/encode user input before using in shell commands

**Security Review Requirements:**
- Self-code review before commit (see Code Review Practices in Section 5)
- Check for shell command injection vulnerabilities during review
- Verify file access is limited to `wiki_root`

**Secrets Management:**
- Not applicable - no secrets or credentials handled by this plugin