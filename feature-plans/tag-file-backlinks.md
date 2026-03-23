---
name: "tag-file-backlinks"
status: "done"
---

# Tag File Backlinks

## Table of Contents

1. [Feature Name and Description](#section-1-feature-name-and-description)
2. [Feature Requirements](#section-2-feature-requirements)
3. [Constraints](#section-3-constraints)
4. [Feature Verification Testing](#section-4-feature-verification-testing)
5. [Deliverables and Artifacts](#section-5-deliverables-and-artifacts)

---

## Section 1: Feature Name and Description

**Feature Name:**
Tag file backlinks

**Purpose:**
Allows users to quickly find, browse, and jump to places in other notes that reference a specific tag, making it easy to discover related content across the entire wiki.

**Primary Users/Stakeholders:**
Users who want to find references to the current tag file across the entire wiki_root

**Expected Behavior:**
- When a tag file is loaded, the system searches wiki_root for lines that mention the tag
- When the tag file buffer is active, the quickfix window opens with a list of all locations where the tag is referenced
- Quickfix entries show file path + line content (limited to 80 characters with tag visible in window)
- Pressing `<CR>` on an entry jumps to the file and location where the tag is referenced
- If no references are found, nothing happens (silent behavior)
- Quickfix window auto-closes when leaving the tag file buffer
- Uses exact tag name matching only

---

## Section 2: Feature Requirements

**Functional Requirements:**
1. Find all backlinks to the current tag file ("#tag") across wiki_root
2. Populate the quickfix list with backlink references when a tag file is loaded
3. Allow users to jump to reference locations by pressing `<CR>` in the quickfix list
4. Auto-close quickfix when leaving the tag file buffer
5. Only populate on file load (not on save of other files)

**User Interactions/Flows:**
1. User opens or jumps to a tag file → quickfix list appears with backlink references
2. User navigates the quickfix list and presses `<CR>` to jump to location
3. User navigates away from tag file → quickfix list closes
4. User can refresh with `:e` command

**Data Requirements:**
- Input: Tag name from current tag file filename
- Output: File name, line number, column, and 80-character preview of each reference
- Preview window must contain the tag reference

**Formats/Interfaces:**
- Quickfix list format: `filename:linenumber:summary`
- Integrates with vim's built-in quickfix system

**Success Conditions:**
- Expected behavior is achieved
- All unit tests, checks and audits pass
- Manual testing completed by user

---

## Section 3: Constraints

**Technical Constraints:**
- None additional beyond existing project stack (Lua, Neovim API)

**Business Constraints:**
- None

**Operational Constraints:**
- Must rely on manual acceptance testing for quickfix list interactions
- Use ripgrep for searches (no timeout)
- No caching or visual progress indicators at this time

**Compatibility Requirements:**
- Integrate with existing tag management functions from core module
- Reuse existing functions with refactoring if needed (prompt user with plan)

**Security/Privacy Constraints:**
- None additional

**Configuration:**
- Feature should be configurable (enable/disable via config option)

---

## Section 4: Feature Verification Testing

**Test Types:**
- Unit tests (with real files in test_root)
- Manual acceptance testing for quickfix interactions
- Type checking and audits

**Test Frameworks:**
- plenary.nvim for unit tests

**Test Patterns to Follow:**
- Follow existing patterns in tests/lua/davewiki/
- Use test_root for real file testing (no mocking filesystem)

**Coverage Expectations:**
- Cover all public interfaces
- Inform user of any areas that cannot be covered with unit tests (e.g., dialog/floating window interactions)

**Unit Testable Behaviors:**
- Finding links in other files
- Extracting summary text (80-char preview with tag visible)
- Formatting data to populate quickfix list
- Quickfix format verification

**Manual Testing Required:**
- Verifying quickfix list contents display correctly
- Verifying `<CR>` jumps to target location
- Verifying quickfix list closes when navigating away from tag file

**Success Criteria Description:**
Feature passes manual acceptance testing and code review. All unit tests, type checks, and audits pass. Both unit tests (for data processing) and manual tests (for UI interactions) are completed.

---

## Section 5: Deliverables and Artifacts

**Public Functions/APIs:**
- `core.find_backlinks(tag_name)` - Find all backlinks to a tag across wiki_root
- `core.format_quickfix_entry(file_path, line_num, col_num, line_content, tag_name)` - Format a single backlink match into quickfix-compatible entry structure
- `core.is_tag_file(file_path)` - Check if a file path is a tag file in the sources/ directory
- `core.extract_tag_from_filename(file_path)` - Extract the tag name from a tag file path
- `core.extract_summary(line_content, tag_start_col, max_length)` - Extract a summary of a line centered around the tag position
- `init.setup_backlinks_autocmd()` - Set up autocommand for tag file backlink display
- Configuration option: `show_tag_backlinks` (boolean, default: true)

**User-Facing Features:**
- Quickfix window automatically populated with backlinks when opening a tag file
- Quickfix window auto-closes when navigating to non-tag file
- `<CR>` in quickfix jumps to reference location

**Documentation:**
- Update README.md with:
  - Feature description and behavior
  - Configuration option documentation
  - Example setup with autocommand

**Configuration/Infrastructure:**
- Add `show_tag_backlinks` option to setup configuration (default: true)
- `init.setup_backlinks_autocmd()` function sets up autocommands automatically when option is enabled
- Autocommands use `BufReadPost` and `BufLeave` events with `desc` properties
- Add example manual autocommand configuration to README for users who want custom behavior

**Deployment Artifacts:**
- None additional (part of existing plugin)

---

*Feature plan created on: Mon Mar 23 2026*
