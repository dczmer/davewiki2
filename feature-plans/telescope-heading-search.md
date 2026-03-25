---
name: "telescope-heading-search"
status: "done"
---

# Telescope Heading Search

**Generated**: 2026-03-24
**Version**: 1.0

## Table of Contents
1. [Feature Name and Description](#1-feature-name-and-description)
2. [Feature Requirements](#2-feature-requirements)
3. [Constraints](#3-constraints)
4. [Feature Verification Testing](#4-feature-verification-testing)
5. [Deliverables and Artifacts](#5-deliverables-and-artifacts)

---

## 1. Feature Name and Description

**Feature Name:**
telescope-heading-search

**Purpose:**
Provides quick navigation to level-1 markdown headings (`# Title`) across the wiki. Enables users to discover document structure and jump to specific sections within their knowledge base documents.

**Primary Users/Stakeholders:**
Wiki/note-taking users who need to navigate their markdown documents efficiently.

**Expected Behavior:**
- Single telescope picker command (`:DavewikiHeadings`)
- Lists all level-1 headings (`# Title`) found across all markdown files in `wiki_root`
- Each picker entry displays: heading text + filename
- Headings sorted alphabetically by heading text
- Fuzzy filtering/searching supported via telescope
- Pressing Enter jumps to the selected heading location (file + line)
- File content preview shown for selected heading
- Pressing `<Esc>` closes the picker gracefully

---

## 2. Feature Requirements

**Functional Requirements:**

1. **Heading Search** (`:DavewikiHeadings` command / `require('davewiki.telescope').headings()` function)
   - Use ripgrep to search for `^# ` patterns across all markdown files in `wiki_root`
   - Extract heading text and file path from grep results
   - Present heading list in telescope picker with alphabetical sorting by heading text
   - Each entry displays: heading text + filename
   - File content preview shown for selected heading
   - Pressing Enter jumps to the heading location (file + line)

**Data Requirements:**
- **Input:** None (picker opens directly)
- **Output:** Telescope picker displaying level-1 heading entries
- **Pattern:** `^# [^#].*$` (lines starting with single # followed by non-space text)

**Success Conditions:**
- Picker displays all level-1 headings from all `.md` files in `wiki_root`
- Each entry shows heading text + filename
- Selecting entry jumps to correct file and line
- Headings sorted alphabetically by heading text
- Graceful handling when no headings found

**Error Handling:**
- **No headings found:** No message shown (silent)
- **Telescope not installed:** Log warning, function returns `false`
- **wiki_root not configured:** Log error, function returns `false`

---

## 3. Constraints

**Technical Constraints:**
- Neovim 0.9+ (LuaJIT bundled)
- Requires telescope.nvim for picker functionality
- Must use `core.ripgrep()` for shell command execution (security requirement)
- Heading pattern: `^# [^#].*$` (level-1 headings only)

**Operational Constraints:**
- No caching required - ripgrep is fast enough for typical wiki scale
- Standard telescope integration - users can use telescope's built-in mappings

**Compatibility Requirements:**
- Must integrate with existing davewiki setup configuration
- `init.lua` conditionally loads telescope module when `setup({ telescope = { enabled = true } })` is called
- Must work with existing keybinding conventions (no default keymaps)

**Security/Privacy Constraints:**
- All searches must be constrained to `wiki_root` directory
- Use `vim.system()` for shell commands (via `core.ripgrep()`)

**Business Constraints:**
- None specific

---

## 4. Feature Verification Testing

**Test Types:**
- Integration tests with real files in `test_root/` (no mocking)
- Command tests for `:DavewikiHeadings`

**Test Framework:**
- plenary.nvim tests (following pattern in `tests/lua/davewiki/*.lua`)

**Test File:**
- `tests/lua/davewiki/telescope_spec.lua` (extend existing telescope tests)

**Test Patterns to Follow:**
- Use `test_root/` as wiki_root (never access files outside)
- Reset module state in `before_each`
- Use `core.ripgrep()` for shell commands
- Define test markdown files in `test_root/` with various level-1 headings

**Coverage Expectations:**
- Heading picker: listing headings, filtering, selection
- Error handling: telescope not installed, wiki_root not set

**Edge Cases to Test:**
- No headings found in wiki
- Multiple files with headings
- Headings with special characters
- Empty heading lines (just `# `)
- Files with ## and ### headings (should be ignored)
- Telescope not installed (function returns false, logs warning)
- wiki_root not configured (function returns false, logs error)

**Success Criteria:**
- Automated: All tests pass in plenary.nvim test suite
- Manual: `nix run .#nvim-test`, invoke `:DavewikiHeadings`, verify picker shows headings, filter works, Enter jumps to heading

---

## 5. Deliverables and Artifacts

**Public Functions/APIs:**
- `require('davewiki.telescope').headings()` - Opens the heading list picker, returns `false` on failure

**Vim Commands:**
- `:DavewikiHeadings` - Opens the heading list picker

**User-Facing Features:**
- Fuzzy-findable list of all level-1 headings across wiki with navigation

**Documentation:**
- README.md: Add heading search feature description, commands, and usage examples
- Lua docstrings: Add `@module`, `@param`, `@return` annotations to new functions

**Configuration:**
- `setup({ telescope = { enabled = true } })` - Already configured, just add heading picker
- Update `lua/davewiki/telescope.lua` to expose `headings()` function
- Update `lua/davewiki/init.lua` to register `:DavewikiHeadings` command

**Files to Create/Modify:**
1. `lua/davewiki/telescope.lua` - Add `headings()` function using ripgrep
2. `lua/davewiki/init.lua` - Add command registration for `:DavewikiHeadings`
3. `tests/lua/davewiki/telescope_spec.lua` - Add tests for heading picker
4. Create test markdown files in `test_root/` with level-1 headings for testing

**No Deployment Artifacts:**
- Standard neovim plugin, no special deployment needed
