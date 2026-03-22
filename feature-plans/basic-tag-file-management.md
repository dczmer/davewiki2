---
name: "basic-tag-file-management"
status: "done"
---

# Basic Tag File Management

## Table of Contents

1. [Feature Name and Description](#section-1-feature-name-and-description)
2. [Feature Requirements](#section-2-feature-requirements)
3. [Constraints](#section-3-constraints)
4. [Feature Verification Testing](#section-4-feature-verification-testing)
5. [Deliverable Artifacts](#section-5-deliverable-artifacts)

---

## Section 1: Feature Name and Description

**Feature Name:**
Basic Tag File Management

**Purpose:**
The feature enables the KMS plugin to manage tag files as central anchor points in a web of links between tag files and all other files that reference those tags.

**Primary Users/Stakeholders:**
- Users of the KMS plugin who manage notes with tag files

**Expected Behavior:**
1. Detect valid tag names within document content
2. Enable navigation from tag references to their corresponding tag files
3. Automatically create tag files if they don't exist
4. Only operate within wiki_root directory (security constraint)
5. Store all tag files in the sources/ subdirectory
6. Validate that no files are created or modified outside wiki_root

---

## Section 2: Feature Requirements

**Functional Requirements:**
1. Scan documents for tags using ripgrep with pattern `#[A-Za-z0-9-_]+`
2. Search for existing tag files using ripgrep
3. When editing a markdown file, detect tag name under cursor and jump to tag file (creating the file if necessary)
4. Tags are created in `sources/` directory under wiki_root (flat structure, no nesting)
5. Tag files have YAML frontmatter with `name` (tag name without #) and `created` (date)
6. Template for frontmatter implemented as Lua table in `davewiki.core` with type annotations
7. Utility function scans all tag files to verify frontmatter matches template and reports violations
8. All new functions must be public (attached to the M module table) with proper type annotations

**User Interactions/Flows:**
- User edits markdown file → positions cursor on valid tag name → presses `<CR>` → jumps to tag file (creates if missing)

**Data Requirements:**
- **Input:** Document text, wiki_root path, sources/ directory path, cursor position
- **Output:** Tag files in sources/ with YAML frontmatter
- **Validation:** Tag pattern `#[A-Za-z0-9-_]+`, yaml frontmatter format

**Success Conditions:**
1. User can hit `<CR>` on valid tag name to jump to associated tag file (does nothing for invalid tags)
2. Missing tag files are automatically created with proper frontmatter before jumping
3. Existing files with invalid/missing frontmatter are auto-fixed
4. All tag files created within wiki_root/sources (security constraint)
5. Violation reporting utility lists all frontmatter mismatches

---

## Section 3: Constraints

**Technical Constraints:**
- Lua + ripgrep (ripgrep 13.0+, neovim 0.9+)
- Use existing utility functions and types from `davewiki.core`
- Use constants for often repeated literal values like the tag name pattern `#[A-Za-z0-9-_]+`
- Standalone implementation (not integrated with Telescope, obsidian, etc.)

**Business Constraints:**
- Keep it simple
- Single-user/local usage

**Operational Constraints:**
- Global wiki_root directory (configurable)
- Must never create or modify files outside wiki_root (security constraint)
- All tag files stored in sources/ subdirectory
- Flat tag structure (no nested sub-folders)

**Compatibility Requirements:**
- Recent versions only (ripgrep 13.0+, neovim 0.9+)

**Security/Privacy Constraints:**
- Validate all file operations stay within wiki_root
- Require ripgrep dependency

---

## Section 4: Feature Verification Testing

**Test Types:**
- Unit tests with actual filesystem access within test_root directory (no mocking)
- Manual acceptance tests by the user
- Type checking, linting, and formatting checks

**Test Frameworks:**
- Plenary.nvim (existing Lua testing framework)

**Test Patterns to Follow:**
- Follow AGENTS.md guidelines: use real files in test_root, never mock filesystem
- Test file structure mirrors lua/ folder under tests/lua/
- File naming: append `_spec.lua` to module name (e.g., `lua/davewiki/core.lua` → `tests/lua/davewiki/core_spec.lua`)

**Coverage Expectations:**
- Core functionality: all public functions tested

**Edge Cases to Test:**
- Invalid tags (malformed patterns)
- Missing tag files
- Path traversal attempts (security)
- Invalid/missing frontmatter in existing files
- Files outside wiki_root (should be rejected)
- Tag files in wrong locations (not in sources/)

**Success Criteria Description:**
The feature is correctly implemented when:
1. All unit tests pass using real filesystem operations in test_root
2. Type checking (lua-language-server) passes with no errors
3. Linting (luacheck) passes
4. Formatting (stylua) passes
5. User has approved with final manual acceptance test

---

## Section 5: Deliverable Artifacts

**1. Core Module (`lua/davewiki/core.lua`)**
- Constants table with `TAG_PATTERN = "#[A-Za-z0-9-_]+"`
- Frontmatter template (Lua table with type annotations) containing `name` and `created` fields
- `M.scan_for_tags()` - ripgrep-based tag detection (public)
- `M.find_tag_files()` - ripgrep-based tag file search (public)
- `M.create_tag_file(tag_name)` - creates tag file with YAML frontmatter (public)
- `M.validate_frontmatter()` - scans all tag files and reports violations (public)
- `M.get_tag_under_cursor()` - extracts tag from current cursor position (public)
- `M.jump_to_tag_file()` - navigation + auto-creation logic (public)

**2. Keymap Setup**
- Normal mode `<CR>` mapping for markdown files
- Integration with `M.jump_to_tag_file()`

**3. Type Definitions**
- Type annotations for all public functions (function signatures)
- Type definition for frontmatter structure

**4. Test Files (`tests/lua/davewiki/`)**
- `core_spec.lua` - unit tests for all public functions in core.lua
- Tests use real files in `test_root/` (no mocking)
- Edge case tests: invalid tags, path traversal, missing files, wrong locations

**5. Documentation**
- This feature plan document (`feature-plans/basic-tag-file-management.md`)
