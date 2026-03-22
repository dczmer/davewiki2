# wiki-root-configuration

## Metadata

- **Date:** 2026-03-21
- **Version:** 1.0
- **Status:** Approved

## Table of Contents

1. [Feature Name and Description](#1-feature-name-and-description)
2. [Feature Requirements](#2-feature-requirements)
3. [Constraints](#3-constraints)
4. [Feature Verification Testing](#4-feature-verification-testing)

---

## 1. Feature Name and Description

**Feature Name:**
wiki_root configuration

**Purpose:**
Allows the user to configure the wiki_root option as either a vim global `g:davewiki_wiki_root` variable or as an option passed to the setup function. Provides a utility function to resolve the correct wiki_root path.

**Primary Users/Stakeholders:**
Personal wiki users

**Expected Behavior:**
- Entry point is `lua/davewiki/init.lua` setup function
- `wiki_root` option passed to setup takes precedence over global variable
- Global variable `g:davewiki_wiki_root` is the fallback
- If neither is provided, use default `"~/davewiki"` and print a warning if directory doesn't exist
- The resolving function should be a public API exported from `davewiki.core`

---

## 2. Feature Requirements

**Functional Requirements:**

1. `setup()` function accepts `wiki_root` option and stores it
2. Check global variable `g:davewiki_wiki_root` if no setup option
3. Use default `"~/davewiki"` with warning if directory doesn't exist
4. Export a public API function from `davewiki.core` to resolve wiki_root

**User Interactions/Flows:**

- User calls `require('davewiki').setup({ wiki_root = '/path/to/wiki' })`
- Or user sets `g:davewiki_wiki_root = '/path/to/wiki'` in vimrc
- Plugin resolves wiki_root using priority: setup option > global > default

**Data Requirements:**

- Input: Configuration table with optional `wiki_root` key
- Input: Vim global variable `g:davewiki_wiki_root`
- Output: String path to wiki root directory

**Success Conditions:**

- `setup()` accepts and stores wiki_root option
- Global variable is checked when no setup option
- Default is used with warning if directory doesn't exist
- Function is exported as public API
- Path is validated to exist on filesystem
- `~` is expanded to user's home directory

---

## 3. Constraints

**Technical Constraints:**

- Pure Lua/Neovim only (no external dependencies)
- Must use lua-language-server type annotations

**Business Constraints:**

- None

**Operational Constraints:**

- Must work as a Neovim plugin

**Security/Privacy Constraints:**

- Path validation to ensure only access files under wiki_root

---

## 4. Feature Verification Testing

**Test Types:**

- Unit tests using real file I/O on `test_root/` directory
- Manual testing by the user
- Linting and type-checking

**Test Frameworks:**

- plenary.nvim for testing Neovim plugins
- Follow existing test patterns in the project

**Edge Cases to Test:**

- Missing wiki_root (neither option nor global set)
- Non-existent path (wiki_root points to missing directory)
- Tilde expansion (~ properly expanded to home)

**Success Criteria:**

- Unit tests pass for wiki_root resolution
- Function returns expected value based on configuration
- Warning shown when default path used and directory is missing
- All linters and type checker pass
