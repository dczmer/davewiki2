---
name: "cmp-tag-completion"
status: "open"
---

# CMP Tag Completion

## Table of Contents

1. [Feature Name and Description](#section-1-feature-name-and-description)
2. [Feature Requirements](#section-2-feature-requirements)
3. [Constraints](#section-3-constraints)
4. [Feature Verification Testing](#section-4-feature-verification-testing)
5. [Deliverables and Artifacts](#section-5-deliverables-and-artifacts)

---

## Section 1: Feature Name and Description

**Feature Name:** cmp completion of tagnames

**Purpose:** Allow nvim-cmp to auto-complete tag names for convenience when editing wiki markdown files.

**Primary Users/Stakeholders:** Users managing notes who use cmp for auto-completion.

**Expected Behavior:** When the user types a tag name (starting with "#" followed by 2+ valid tag characters), the cmp window should populate a list of matching tag names to auto-complete.

---

## Section 2: Feature Requirements

**Functional Requirements:**
1. New `cmp` module in davewiki that provides `register_tag_names()` function
2. `setup()` automatically calls `register_tag_names()` when `cmp` module is enabled
3. Module attached to `davewiki.init` module, exposing cmp support functions
4. `register_tag_names()` calls `cmp.register_source('wiki_tags', ...)` to register the source
5. Users add `wiki_tags` source name to their cmp configuration

**User Interactions/Flows:**
- User enables `cmp` in their `davewiki.setup({ cmp = true })`
- During setup, `register_tag_names()` is called automatically
- Source is registered under name `wiki_tags`
- User types `#ta` in a markdown file
- cmp activates the `wiki_tags` source
- Source returns matching tag names from tag files
- User selects tag → full `#tagname` is inserted
- If no matches → completion window is hidden

**Data Requirements:**
- Input: partial tag name after `#` (minimum 2 chars)
- Output: list of valid tag names matching prefix (case-insensitive)
- Source: tag file names in `wiki_root/sources/` directory

**Success Conditions:**
- cmp source correctly registers under name `wiki_tags` when `cmp=true` in setup
- Completion appears only when valid partial tag is typed
- Invalid tag names are never suggested
- Empty results hide the completion window

---

## Section 3: Constraints

**Technical Constraints:**
- Must work within standard davewiki architecture
- Module must follow existing patterns for `cmp` module vs `init` module

**Business Constraints:**
- None specified

**Operational Constraints:**
- None specified

**Compatibility Requirements:**
- Standard Neovim compatibility
- Must work with nvim-cmp plugin

**Security/Privacy Constraints:**
- Only look for tag files within `wiki_root/sources/` directory
- Never access files outside the configured wiki_root

---

## Section 4: Feature Verification Testing

**Test Types:**
- Unit tests for cmp source logic
- Manual testing for actual cmp integration behavior

**Test Frameworks:**
- plenary.nvim (standard for this project)

**Test Patterns to Follow:**
- Follow existing test structure in `tests/lua/davewiki/`
- Use `test_root/` for test files
- Mock vim functions only when necessary

**Coverage Expectations:**
- Unit tests for the cmp source module
- Test trigger detection and tag matching logic

**Edge Cases to Test:**
- Empty partial tag (less than 2 chars after #)
- No matching tags found
- Tag names with valid/invalid characters
- Case-insensitive matching

**Success Criteria Description:**
1. cmp module initializes a cmp source called `wiki_tags` when enabled in setup
2. User completes a successful manual test of cmp completion behavior
3. All unit tests pass
4. Linter and type checker pass

---

## Section 5: Deliverables and Artifacts

**Public Functions/APIs:**
- `davewiki.cmp` - New module namespace
- `davewiki.cmp.register_tag_names()` - Registers `wiki_tags` cmp source (called by setup)
- cmp source name: `wiki_tags` (user adds to their cmp config)

**User-Facing Features:**
- Auto-completion of tag names in markdown files via cmp
- Only activates when `cmp = true` in davewiki.setup()

**Documentation:**
- README.md - Document the cmp feature and configuration

**Configuration/Infrastructure:**
- New `lua/davewiki/cmp.lua` module
- Tests in `tests/lua/davewiki/cmp_spec.lua`

**Deployment Artifacts:**
- None (standard nvim plugin distribution)
