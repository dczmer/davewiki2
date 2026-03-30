# davewiki

A personal knowledge base system for neovim with journal-based note-taking, inspired by Logseq.

## What it does

- Manages a directory of markdown notes and daily journals
- Organizes notes using flat tags (`#tag-name`) with back-reference tracking
- Provides quick search and navigation between tags, notes, and journals
- Integrates with telescope.nvim for tag search and nvim-cmp for completion
- Generates synthetic tag views that aggregate all references to a tag across the wiki

## Key features

- Journal-based daily note-taking
- Tag-based organization with back-references
- Tag views for consolidated research across the entire wiki
- Markdown link navigation
- Tag autocomplete
- Telescope integration for tag search, heading search, and navigation

## How it works

### Wiki Root

All your notes are stored in a configurable `wiki_root` directory (e.g., `~/davewiki`). All paths mentioned below are relative to this root directory.

### Journals

Your daily notes live in `journals/`. Each journal file is a markdown document where you capture thoughts, ideas, and notes for that day.

### Tags

Tags (`#tag-name`) create connections between notes. When you add a tag to a block in your journal, that block becomes associated with the tag.

- Tags are flat (not hierarchical): `#my-tag`, `#another-tag`
- Tag files live under `sources/` as anchor files
- Jump to any tag file to see all back-references

### Markdown Links

Markdown links (`[text](path)`) provide navigation between notes and external resources.

- **Internal links**: Jump to other `.md` files within your wiki
  - Absolute paths (recommended): `[notes](/notes/recipes.md)` - paths starting with `/` are resolved relative to `wiki_root`
  - Relative paths: `[notes](./notes.md)` or `[notes](notes.md)` - resolved relative to the current file
- **External URLs**: Open in your system's default browser
  - `[website](https://example.com)`
- **Security**: All paths are validated to stay within `wiki_root`
- **Keybinding**: Press `<CR>` on any link to navigate (must be configured in your init.lua)
- **Inserting links**: Use `:DavewikiInsertLink` to insert a link - it will automatically generate an absolute path

### Blocks

Journals are organized into blocks separated by `---`. Each block can contain multiple tags. When you search for a tag, you find all blocks mentioning it.

```
---
Today I learned about #vim scripting.

Some notes on #markdown formatting.
---

Another block with #vim tips.
---
```

### Other Notes

Non-journal notes go in `notes/` and can mention tags, but aren't automatically indexed by the tagging system.

### Tag File Backlinks

When you open a tag file (a markdown file in `sources/`), davewiki automatically searches your entire wiki for references to that tag and displays them in the quickfix window.

**Features:**
- **Automatic display**: Quickfix window opens automatically when you enter a tag file
- **Navigation**: Press `<CR>` on any entry to jump to that reference
- **Smart summary**: Each entry shows an 80-character preview with the tag visible
- **Auto-close**: Quickfix closes automatically when you leave the tag file
- **Silent operation**: If no backlinks are found, nothing happens (no noise)
- **Refresh**: Use `:e` to reload the tag file and refresh the backlink list

**Configuration:**
Enable/disable with the `show_tag_backlinks` option (enabled by default):

```lua
require('davewiki').setup({
  wiki_root = "~/.davewiki",

  -- Enable automatic tag backlink display (default: true)
  -- When enabled, opening a tag file automatically shows all references
  -- to that tag in the quickfix window
  show_tag_backlinks = true,  -- Set to false to disable
})
```

### Tag Highlighting

Tags (`#tag-name`) are automatically highlighted with a custom highlight group `DavewikiTag` when viewing markdown files within your wiki. This feature can be disabled by setting `highlight_tags = false` in your configuration.

**Configuration:**
```lua
require('davewiki').setup({
  wiki_root = "~/.davewiki",
  highlight_tags = false,  -- Disable tag highlighting
})
```

**Default Style:**
- Bright orange foreground (`#FF8C00`)
- Dark charcoal background (`#2A2A2A`)
- Underline

**Customization:**
You can override the highlight group in your Neovim configuration after loading the plugin:

```lua
-- Example: Custom colors for tags
require('davewiki').setup({
  wiki_root = "~/.davewiki",
})

-- Override the highlight group (must be after setup)
vim.api.nvim_set_hl(0, "DavewikiTag", {
  fg = "#00FF00",  -- Green foreground
  bg = "#000000",  -- Black background
  underline = true,
})

-- Or use vim highlight command
vim.cmd("highlight DavewikiTag guifg=blue guibg=yellow gui=underline")
```

### Tag Views

Synthetic tag views aggregate all references to a specific tag into a single buffer, providing a consolidated research view across your entire wiki.

**Features:**
- Generates a synthetic view file containing tag file content, journal blocks, and wiki references
- Each section includes markdown links to source documents
- View is created as an unsaved buffer - you can save it manually if desired
- Automatically regenerates content when invoked for an existing view

**View Content:**
When you generate a tag view for `#cooking`, the buffer contains:
1. **Tag File Content**: Full content of the `sources/cooking.md` tag file (or "NO TAG FILE" placeholder)
2. **Journal Blocks**: Complete `---` separated blocks from journal files that mention `#cooking`
3. **Wiki References**: Paragraphs from non-journal wiki files that mention `#cooking`

**Commands:**

| Command | Description |
|---------|-------------|
| `:DavewikiGenerateView` | Open telescope picker to select a tag and generate its view |
| `:DavewikiGenerateViewFromCursor` | Generate view for the tag under cursor |
| `:DavewikiGenerateViewFromTagFile` | Generate view for the current tag file (when editing a tag file) |

**Keymap Examples:**
```lua
-- Generate view for tag under cursor
vim.keymap.set('n', '<leader>wv', '<cmd>DavewikiGenerateViewFromCursor<CR>', { desc = "Generate tag view from cursor" })

-- Pick a tag and generate view
vim.keymap.set('n', '<leader>wV', '<cmd>DavewikiGenerateView<CR>', { desc = "Pick tag and generate view" })
```

### Attachments

Optional attachments (images, files) can be stored in `attachments/` within your wiki root.

## Installation

### With lazy.nvim

```lua
require('lazy').setup({
  "dczmer/davewiki2",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-cmp",
  },
  config = function()
    require('davewiki').setup({})
  end,
})
```

### Dependencies

**Required:**
- `nvim-telescope/telescope.nvim` - search UI
- `nvim-cmp` - tag completion

**Development:**
- `nvim-lua/plenary.nvim` - testing framework

**Optional:**
- `cmp-buffer` - buffer word completion
- `cmp-path` - filesystem path completion
- `cmp-nvim-lsp` - LSP completion source
- `cmp-nvim-lsp-signature-help` - LSP signature help
- `telescope-fzf-native` - FZF sorter for telescope
- `vim-markdown` - Markdown syntax and ftplugin
- `which-key.nvim` - keybinding help

## Configuration

```lua
require('davewiki').setup({
  -- Required: set your wiki root directory
  wiki_root = "~/.davewiki",

  -- Enable/configure telescope integration (default: true)
  telescope = {
    enabled = true,
  },

  -- Enable/configure nvim-cmp integration (default: true)
  cmp = {
    enabled = true,
  },

  -- Enable/configure journal module (default: true)
  journal = {
    enabled = true,
  },

  -- Enable automatic tag backlink display (default: true)
  show_tag_backlinks = true,
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `wiki_root` | string | `~/davewiki` | Root directory for all notes (can also set `g:davewiki_wiki_root`) |
| `telescope.enabled` | boolean | `true` | Enable telescope integration |
| `cmp.enabled` | boolean | `true` | Enable nvim-cmp integration |
| `journal.enabled` | boolean | `true` | Enable journal module |
| `show_tag_backlinks` | boolean | `true` | Enable automatic backlink display when opening tag files |
| `highlight_tags` | boolean | `true` | Enable automatic tag syntax highlighting |

### Telescope Commands

When telescope integration is enabled, the following commands are available:

| Command | Description |
|---------|-------------|
| `:DavewikiTags` | Open a telescope picker to search and navigate to tag files |
| `:DavewikiTagReferences [tag_name]` | Search for tag references across the wiki |
| `:DavewikiHeadings` | Search for level-1 headings across all markdown files |
| `:DavewikiInsertLink` | Insert a markdown link to another wiki file using a telescope picker |
| `:DavewikiJournals` | Open a telescope picker to browse and open journal files (requires journal module) |
| `:DavewikiGenerateView` | Open telescope picker to select a tag and generate its synthetic view |

### Journal Commands

When the journal module is enabled, the following commands are available for daily journaling:

| Command | Description |
|---------|-------------|
| `:DavewikiJournalToday` | Open today's journal |
| `:DavewikiJournalYesterday` | Open yesterday's journal |
| `:DavewikiJournalTomorrow` | Open tomorrow's journal |
| `:DavewikiJournalOpen` | Prompt for a date and open that journal |

**Journal Features:**
- Journals are stored as `YYYY-MM-DD.md` files in `${wiki_root}/journals/`
- New journals automatically include YAML frontmatter with the date and sections for TASKS, AGENDA, and NOTES
- The journals directory is created automatically if it doesn't exist
- Multiple journals can be open simultaneously

**Journal Template:**
```markdown
---
date: 2026-03-26
---

# 2026-03-26 - Wednesday

# TASKS

# AGENDA

# NOTES
```

**Keymap Examples:**

```lua
-- Open today's journal
vim.keymap.set('n', '<leader>wjt', '<cmd>DavewikiJournalToday<CR>', { desc = "Open today's journal" })

-- Open yesterday's journal
vim.keymap.set('n', '<leader>wjy', '<cmd>DavewikiJournalYesterday<CR>', { desc = "Open yesterday's journal" })

-- Open tomorrow's journal
vim.keymap.set('n', '<leader>wjT', '<cmd>DavewikiJournalTomorrow<CR>', { desc = "Open tomorrow's journal" })

-- Open journal for specific date
vim.keymap.set('n', '<leader>wjo', '<cmd>DavewikiJournalOpen<CR>', { desc = "Open journal for specific date" })
```

**Smart Navigation:**

The `:DavewikiJournalYesterday` and `:DavewikiJournalTomorrow` commands are context-aware:
- If the current buffer is a journal file, they navigate relative to that journal's date
- Otherwise, they navigate relative to today's date

**Usage Examples:**

```vim
" Open tags picker - fuzzy find and jump to tag file
:DavewikiTags

" Search for all references to #bengal
:DavewikiTagReferences #bengal

" Show all tag references across the entire wiki
:DavewikiTagReferences

" Search for headings across all markdown files
:DavewikiHeadings
```

**Keymap Examples:**

```lua
-- Open tags picker with <leader>wt
vim.keymap.set('n', '<leader>wt', function()
    require('davewiki').telescope.tags()
end, { desc = 'Open davewiki tags picker' })

-- Search for tag references with <leader>wT
vim.keymap.set('n', '<leader>wT', function()
    require('davewiki').telescope.tag_references()
end, { desc = 'Search davewiki tag references' })

-- Search for headings with <leader>wh
vim.keymap.set('n', '<leader>wh', function()
    require('davewiki').telescope.headings()
end, { desc = 'Search davewiki headings' })

-- Insert markdown link with <leader>wl
vim.keymap.set('n', '<leader>wl', function()
    require('davewiki').telescope.insert_link()
end, { desc = 'Insert markdown link to wiki file' })

-- Browse journal files with <leader>wjp
vim.keymap.set('n', '<leader>wjp', function()
    require('davewiki').telescope.jump_to_journal()
end, { desc = 'Browse journal files with telescope' })
```

### nvim-cmp Configuration

To enable tag autocomplete, add the `wiki_tags` source to your cmp setup:

```lua
-- In your cmp setup
require('cmp').setup({
  sources = {
    { name = 'wiki_tags' },
    -- other sources...
  },
})
```

When you type `#` followed by tag characters in a markdown file, davewiki will suggest matching tag names from your `sources/` directory.

### Alternative Configuration

You can also set `wiki_root` via a vim global variable:

```vim
let g:davewiki_wiki_root = '~/my-wiki'
```

The priority for wiki_root is: setup option > `g:davewiki_wiki_root` > default `~/davewiki`

## Development

### Manual Testing

For manual acceptance testing, you can run an interactive neovim instance pre-configured with davewiki:

```sh
nix run .#nvim-test -- -u scripts/minimal-init.lua
```

This opens neovim with the `scripts/minimal-init.lua` configuration, which:
- Sets up davewiki with `./test_root` as the wiki root
- Includes example keybindings for jump-to-tag functionality
- Provides a minimal environment for testing features interactively

You can test the tag navigation by opening any markdown file in `test_root/` and pressing `<CR>` on a tag (e.g., `#bengal`).

You can test hyperlink navigation by pressing `<CR>` on a markdown link like `[notes](./notes.md)`or `[website](https://example.com)`.

For a fuller configuration with all features enabled and keymaps configured:

```sh
nix run .#nvim-test -- -u scripts/davewiki2-init.lua
```

### Running Tests

```sh
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedDirectory tests' -c 'qa!'
```