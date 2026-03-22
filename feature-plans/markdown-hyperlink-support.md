---
name: "markdown-hyperlink-support"
status: "done"
---

# Markdown Hyperlink Support

## Table of Contents

1. [Feature Name and Description](#section-1-feature-name-and-description)
2. [Feature Requirements](#section-2-feature-requirements)
3. [Constraints](#section-3-constraints)
4. [Feature Verification Testing](#section-4-feature-verification-testing)
5. [Deliverables and Artifacts](#section-5-deliverables-and-artifacts)

---

## Section 1: Feature Name and Description

**Feature Name:**
markdown hyperlink support

**Purpose:**
Improves navigation between hyperlinked markdown documents by detecting links and jumping to the linked file.

**Primary Users/Stakeholders:**
Users who manage a collection of markdown files with hyperlinks to other markdown files.

**Expected Behavior:**
- Detect standard markdown hyperlinks `[text](path)` when the cursor is over them
- Jump to the linked file if it exists (print message if file doesn't exist)
- Support both relative and absolute paths within wiki_root
- Open external URLs (http://, https://) in the system browser
- Validate all file paths stay within wiki_root (security)
- Support `.md` file extension only
- Exposed as a public function in `davewiki.core`
- Keybinding calls tag function first, then this function

---

## Section 2: Feature Requirements

**Functional Requirements:**
1. `get_link_under_cursor()` - detect if cursor is on a valid markdown hyperlink and return link info (path/URL)
2. `jump_to_link()` - navigate to linked file or open URL in browser
3. Both functions exposed as public API in `davewiki.core`

**Link Detection:**
- Cursor position logic similar to `jump_to_tag` implementation
- Pattern match for standard `[text](path)` markdown links

**Path Resolution:**
- Absolute paths (starting with `/`) resolve relative to wiki_root
- Relative paths resolve relative to current file location
- All paths validated to stay within wiki_root (security)

**URL Handling:**
- Detect http/https URLs in link targets
- Open in system default browser using `vim.ui.open` or equivalent

**Error Handling:**
- Show security error if path would escape wiki_root
- Show "file not found" message if target doesn't exist
- Silent no-op if cursor not on valid hyperlink
- Return nil/boolean + vim.notify for user messages

**Success Conditions:**
- Valid `.md` file links jump to the target file
- Valid URLs open in system browser
- Invalid/non-existent paths show appropriate error messages
- Security constraint enforced (no escape from wiki_root)

---

## Section 3: Constraints

**Technical Constraints:**
- Pure Lua/Neovim implementation (no additional dependencies)
- Follow existing patterns from `jump_to_tag` implementation
- Use existing utility functions and types from `davewiki.core`
- Neovim 0.9+, ripgrep 13+

**Business Constraints:**
- Keep it simple
- Single-user/local usage

**Operational Constraints:**
- Must work within wiki_root directory (security)
- Use vim.ui.open or system default for URL handling

**Compatibility Requirements:**
- Same as existing project: Neovim 0.9+, ripgrep 13+

**Security/Privacy Constraints:**
- All file paths must resolve within wiki_root
- No file operations outside configured wiki_root
- Path traversal attempts must be blocked and reported

---

## Section 4: Feature Verification Testing

**Test Types:**
- Unit tests for individual functions
- Manual acceptance tests by user

**Test Frameworks:**
- Plenary.nvim (existing Lua testing framework)

**Test Patterns to Follow:**
- Follow AGENTS.md guidelines: use real files in `test_root/`, no mocking
- Test file structure mirrors `lua/` folder under `tests/lua/`
- File naming: append `_spec.lua` to module name

**Edge Cases to Test:**
- Special characters in link paths
- Path traversal attempts (e.g., `../../../etc/passwd`)
- Missing target files (file not found)
- External URLs (http/https)

**Success Criteria Description:**
The feature is correctly implemented when:
1. A public function is defined that can be bound to a keymap
2. The function detects markdown link under cursor and jumps to it
3. Keymapping in `scripts/minimal-init.lua` is updated
4. Manual acceptance testing passes
5. All unit tests pass using real filesystem
6. Type checking (lua-language-server) passes
7. Linting (luacheck) passes
8. Formatting (stylua) passes

---

## Section 5: Deliverables and Artifacts

**Public Functions/APIs:**
- `M.get_link_under_cursor()` - returns link info (path/URL) if cursor is on a hyperlink
- `M.jump_to_link()` - navigates to linked file or opens URL in browser

**User-Facing Features:**
- Keymapping in `scripts/minimal-init.lua` updated to call hyperlink function (after tag function)

**Documentation:**
- Feature plan document (`feature-plans/markdown-hyperlink-support.md`)
- Type annotations for all public functions

**Configuration/Infrastructure:**
- No new configuration required
- Keymap in minimal-init.lua updated to integrate both tag and hyperlink navigation

**Deployment Artifacts:**
- None (Neovim plugin, no deployment artifacts)