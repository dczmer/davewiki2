---
name: "telescope-tag-search"
status: "open"
---

# Telescope Tag Search

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
telescope-tag-search

**Purpose:**
Provides quick navigation to tag files and to locations where a tag is mentioned in other files. Enables users to discover available tags, jump to the canonical tag file, and find all references to a tag across their wiki.

**Primary Users/Stakeholders:**
Plugin users - end users who write journals and notes and need to efficiently navigate their tag-based knowledge base.

**Expected Behavior:**
Two separate telescope pickers:

1. **Tags List Picker** (`:DavewikiTags`)
   - Lists all tags found via grep of `#tag-name` patterns within `wiki_root`
   - Allows fuzzy filtering/searching
   - Pressing Enter jumps to the selected tag file (`sources/tag-name.md`)

2. **Tag References Picker** (`:DavewikiTagReferences`)
   - Prompts for a tag name to search
   - Searches all files for `#tag-name` references using ripgrep
   - Shows results as file+line matches with file content preview in telescope
   - Pressing Enter jumps to the selected location

Both pickers exposed as Vim commands and Lua functions (e.g., `require('davewiki.telescope').tags()` and `.tag_references()`). No default keybindings - users configure their own.

**User Interaction Flows:**
- **Tags flow:** `:DavewikiTags` → picker opens → user types filter → Enter → jumps to tag file
- **References flow:** `:DavewikiTagReferences` (or with argument) → prompt/input → picker shows matches → Enter → jumps to location
- **Escape handling:** Pressing `<Esc>` at any prompt/picker closes the picker gracefully

---

## 2. Feature Requirements

**Functional Requirements:**

1. **Tags List Picker** (`:DavewikiTags` command / `require('davewiki.telescope').tags()` function)
   - Use ripgrep to search all `#tag-name` patterns within `wiki_root`
   - Extract unique tag names from grep results
   - Present tag list in telescope picker with alphabetical sorting
   - File content preview shown for selected tag
   - Pressing Enter opens the corresponding tag file (`sources/tag-name.md`)

2. **Tag References Picker** (`:DavewikiTagReferences` command / `require('davewiki.telescope').tag_references(tag_name)` function)
   - Accept optional `tag_name` parameter; if not provided, prompt user for input
   - Use ripgrep to search for `#tag-name` pattern across all files in `wiki_root`
   - Show results as file+line matches with file content preview in telescope
   - Skip tag files (`sources/*.md`) from results - only show references in journals and notes
   - Pressing Enter jumps to the selected location

**Data Requirements:**
- **Input:** Tag name (from prompt or function argument)
- **Output:** Telescope picker displaying tags or file+line references
- **Pattern:** `#[A-Za-z0-9-_]+` at word boundaries (existing pattern from core.lua)

**Success Conditions:**
- Tags picker navigation works: can filter tags, jump to correct tag file
- References picker works: can search tag references, jump to correct location
- Graceful failure when telescope.nvim not installed: returns `false`, logs warning
- Security: All searches constrained to `wiki_root` directory

**Error Handling:**
- **No tags found:** Show telescope message "No tags found in wiki_root"
- **No references found:** Show telescope message "No references to #tag-name found"
- **wiki_root not configured:** Log error "wiki_root is not configured"
- **Telescope not installed:** Log warning, function returns `false`

**Sorting:**
- Tag list sorted alphabetically

**Preview:**
- File content preview shown in telescope for both pickers

**Lua API:**
- `require('davewiki.telescope').tags()` - opens tags picker, returns `false` on failure
- `require('davewiki.telescope').tag_references(tag_name?)` - opens references picker, prompts if tag_name not provided, returns `false` on failure

**Vim Commands:**
- `:DavewikiTags` - opens tags picker
- `:DavewikiTagReferences [tag_name]` - opens references picker, prompts if tag_name not provided

**Integration:**
- `init.lua` conditionally loads telescope module when `setup({ telescope = { enabled = true } })` is called

---

## 3. Constraints

**Technical Constraints:**
- Neovim 0.9+ (LuaJIT bundled)
- Requires telescope.nvim for picker functionality
- plenary.nvim only needed for testing (dev dependency)
- telescope-fzf-native is optional for better fuzzy matching
- Must reuse existing core functions: `core.scan_for_tags()`, `core.find_backlinks()`, `core.get_wiki_root()`
- Must use `core.ripgrep()` for shell command execution (security requirement)
- Tag pattern must match `core.TAG_PATTERN`: `#[A-Za-z0-9-_]+`

**Business Constraints:**
- None specific to this feature

**Operational Constraints:**
- No caching required - ripgrep is fast enough for typical wiki scale (tens to hundreds of files)
- Standard telescope integration - users can use telescope's built-in mappings

**Compatibility Requirements:**
- Must integrate with existing davewiki setup configuration
- `init.lua` conditionally loads telescope module when `setup({ telescope = { enabled = true } })` is called
- Must work with existing keybinding conventions (no default keymaps)

**Security/Privacy Constraints:**
- All searches must be constrained to `wiki_root` directory
- Use `vim.system()` for shell commands (already handled by `core.ripgrep()`)
- Validate tag names using `core.is_valid_tag()` before processing

---

## 4. Feature Verification Testing

**Test Types:**
- Integration tests with real files in `test_root/` (no mocking)
- Command tests for `:DavewikiTags` and `:DavewikiTagReferences`

**Test Frameworks:**
- plenary.nvim tests (following pattern in `tests/lua/davewiki/*.lua`)

**Test Files:**
- `tests/lua/davewiki/telescope_spec.lua` - Tests for telescope module

**Test Patterns to Follow:**
- Use `test_root/` as wiki_root (never access files outside)
- Reset module state in `before_each`
- Use `core.ripgrep()` for shell commands
- Define new test files in `test_root/` as needed

**Coverage Expectations:**
- Tags picker: listing tags, filtering, selection
- References picker: searching, displaying results, navigation
- Error handling: telescope not installed, wiki_root not set

**Edge Cases to Test:**
- No tags in wiki (empty `sources/` or no tags found via grep)
- No references found (search returns zero results)
- Tags with hyphens, underscores, numbers (`#my-tag`, `#my_tag`, `#MyTag92`)
- Telescope not installed (function returns `false`, logs warning)
- wiki_root not configured (function returns `false`, logs error)

**Success Criteria Description:**
- Automated: All tests pass in plenary.nvim test suite
- Manual: `nix run .#nvim-test`, invoke `:DavewikiTags`, verify picker shows tags, filter works, Enter jumps to tag file
- Manual: `nix run .#nvim-test`, invoke `:DavewikiTagReferences`, enter tag name, verify results show file+line matches, Enter jumps to location
- Manual: Press `<Esc>` in pickers, verify graceful exit

**Manual Testing Checklist:**
1. Tags picker: Run `:DavewikiTags`, verify tag list appears, fuzzy filter works, Enter opens tag file
2. References picker: Run `:DavewikiTagReferences`, enter tag name, verify file+line results appear, Enter jumps to correct location
3. Error cases: Run both commands without telescope.nvim installed, verify graceful error message

---

## 5. Deliverables and Artifacts

**Public Functions/APIs:**
- `require('davewiki.telescope').tags()` - Opens the tag list picker, returns `false` on failure
- `require('davewiki.telescope').tag_references(tag_name? string)` - Opens the references picker, prompts for tag_name if not provided, returns `false` on failure

**Vim Commands:**
- `:DavewikiTags` - Opens the tag list picker
- `:DavewikiTagReferences [tag_name]` - Opens the references picker, prompts for tag_name if not provided

**User-Facing Features:**
- Fuzzy-findable list of all tags in wiki with navigation to tag files
- Searchable list of all references to a specific tag across all files
- Automatic integration when `telescope = { enabled = true }` in setup config

**Documentation:**
- README.md: Add telescope feature description, commands, and usage examples
- Lua docstrings: Add `@module`, `@param`, `@return` annotations to all new functions

**Configuration/Infrastructure:**
- `setup({ telescope = { enabled = true } })` - Add telescope config table with enabled field (default: true)
- Update init.lua to conditionally load telescope module based on config
- Verify `scripts/minimal-init.lua` includes telescope.nvim plugin for testing

**Files to Create/Modify:**
1. `lua/davewiki/telescope.lua` - Implement pickers using `core.scan_for_tags()` and `core.find_backlinks()`
2. `lua/davewiki/init.lua` - Add telescope module loading and command definitions
3. `tests/lua/davewiki/telescope_spec.lua` - Integration tests for telescope module
4. `scripts/minimal-init.lua` - Verify telescope.nvim is included

**No Deployment Artifacts:**
- Standard neovim plugin, no special deployment needed