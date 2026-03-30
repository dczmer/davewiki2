# Manual Acceptance Testing Plan for Davewiki2

This document provides a comprehensive manual testing plan for all user-facing functions in the Davewiki2 Neovim plugin.

## Prerequisites

Before testing, ensure:
- Neovim with lazy.nvim or package manager installed
- telescope.nvim installed
- nvim-cmp installed (optional, for completion testing)
- A test wiki_root directory with sample files

---

## 1. Vim Commands

### 1.1 Journal Commands

| Command | Test Steps | Expected Result |
|---------|------------|-----------------|
| `:DavewikiJournalToday` | Execute command | Opens today's journal file (YYYY-MM-DD.md) in journal/ directory |
| `:DavewikiJournalYesterday` | Execute command | Opens yesterday's journal file |
| `:DavewikiJournalTomorrow` | Execute command | Opens tomorrow's journal file |
| `:DavewikiJournalOpen` | Execute command, enter date | Prompts for date, opens that journal file |

### 1.2 Telescope Commands

| Command | Test Steps | Expected Result |
|---------|------------|-----------------|
| `:DavewikiTags` | Execute command | Opens telescope picker listing all tag files |
| `:DavewikiTagReferences` | Execute command | Opens picker showing all tag references across wiki |
| `:DavewikiTagReferences #my-tag` | Execute with tag name | Opens picker showing references to specific tag |
| `:DavewikiHeadings` | Execute command | Opens picker listing all level-1 headings |
| `:DavewikiInsertLink` | Execute in insert mode | Opens picker to select wiki file and insert `[]()` link |
| `:DavewikiGenerateView` | Execute command | Opens picker to select tag, then generates view |
| `:DavewikiJournals` | Execute command | Opens picker listing all journal files |

### 1.3 View Commands

| Command | Test Steps | Expected Result |
|---------|------------|-----------------|
| `:DavewikiGenerateViewFromCursor` | Place cursor on `#tag`, execute | Generates synthetic view buffer for tag under cursor |
| `:DavewikiGenerateViewFromTagFile` | Execute in a tag file (sources/tag.md) | Generates view for current tag file |

---

## 2. Keymaps (via scripts/davewiki2-init.lua)

### 2.1 Navigation Keymaps

| Keymap | Test Steps | Expected Result |
|--------|------------|-----------------|
| `<CR>` in markdown | Place cursor on `#tag`, press Enter | Jumps to tag file (creates if needed) |
| `<CR>` on markdown link | Place cursor on `[text](path)`, press Enter | Jumps to linked file or opens URL in browser |
| `<leader>wt` | Press keymap | Opens telescope tags picker |
| `<leader>wT` | Press keymap | Opens telescope tag references picker |
| `<leader>wh` | Press keymap | Opens telescope headings picker |

### 2.2 Link Keymaps

| Keymap | Test Steps | Expected Result |
|--------|------------|-----------------|
| `<leader>wl` | Press in insert/normal mode | Opens picker to insert markdown link |

### 2.3 View Keymaps

| Keymap | Test Steps | Expected Result |
|--------|------------|-----------------|
| `<leader>wv` | Place cursor on `#tag`, press | Generates view from cursor tag |
| `<leader>wV` | Press keymap | Opens picker to select tag for view generation |

### 2.4 Journal Keymaps

| Keymap | Test Steps | Expected Result |
|--------|------------|-----------------|
| `<leader>wjt` | Press keymap | Opens today's journal |
| `<leader>wjy` | Press keymap | Opens yesterday's journal |
| `<leader>wjT` | Press keymap | Opens tomorrow's journal |
| `<leader>wjo` | Press keymap | Prompts for date, opens that journal |
| `<leader>wj` | Press keymap | Opens journal file picker |

---

## 3. Cmp Module (Autocompletion)

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Tag completion | Type `#` in markdown file | Shows dropdown with existing tags |
| Tag completion (no matches) | Type `#nonexistent` | Shows no suggestions or shows "No matches" |
| Setup with config | Call `require('davewiki').cmp.setup({})` | Registers wiki_tags source |

---

## 4. Autocommands (if enabled)

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Backlinks on BufEnter | Open a tag file | Shows backlinks buffer/window |
| Tag highlighting on BufEnter | Open markdown file | Tags are syntax highlighted |

---

## 5. Integration Scenarios

### 5.1 Tag Workflow

1. Create new tag via `#new-idea` in a journal entry
2. Press `<CR>` to jump to tag file
3. Verify tag file created in `sources/new-idea.md`
4. Add content to tag file
5. Use `:DavewikiTagReferences #new-idea` to find all mentions
6. Generate view with `<leader>wv`

### 5.2 Journal Workflow

1. Open today's journal with `<leader>wjt`
2. Add content with `#project-notes` tag
3. Tomorrow, use `<leader>wjy` to review yesterday's notes
4. Use `<leader>wj` to browse all journals

### 5.3 Link Creation Workflow

1. In a note, type some text
2. Press `<leader>wl` to insert a link
3. Select target file from picker
4. Verify `[]()` link inserted at cursor

---

## Summary

This plan covers:

- **15 Vim Commands**: Journal (4), Telescope (7), View (2)
- **12+ Keymaps**: Navigation (5), Link (1), View (2), Journal (5)
- **3 Integration Scenarios** for end-to-end testing

All commands follow the `:Davewiki*` naming convention and all functions include type annotations and docstrings.
