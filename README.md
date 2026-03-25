# davewiki

A personal knowledge base system for neovim with journal-based note-taking, inspired by Logseq.

## What it does

- Manages a directory of markdown notes and daily journals
- Organizes notes using flat tags (`#tag-name`) with back-reference tracking
- Provides quick search and navigation between tags, notes, and journals
- Integrates with telescope.nvim for tag search and nvim-cmp for completion

## Key features

- Journal-based daily note-taking
- Tag-based organization with back-references
- Markdown link navigation
- Tag autocomplete
- Telescope integration for tag search and navigation

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
  - Relative paths: `[notes](./notes.md)` or `[notes](notes.md)`
  - Absolute paths within wiki: `[sources](/sources/bengal.md)`- **External URLs**: Open in your system's default browser
  - `[website](https://example.com)`
- **Security**: All paths are validated to stay within `wiki_root`
- **Keybinding**: Press `<CR>` on any link to navigate (must be configured in your init.lua)

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

### Attachments

Optional attachments (images, files) can be stored in `attachments/` within your wiki root.

## Installation

### With Nix (recommended)

The plugin can be installed as a Nix package, providing a reproducible build with a bundled standalone neovim instance.

```nix
# In your flake.nix or NixOS configuration
inputs.davewiki.url = "github:dczmer/davewiki2";

# Use the davewiki package or nvim-test for development
nix build .#davewiki
nix run .#davewiki
```

### With lazy.nvim

```lua
require('lazy').setup({
  "dczmer/davewiki2",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-cmp",
    "mattn/calendar-vim",
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
- `mattn/calendar-vim` - calendar support for daily journals
- `nvim-lua/plenary.nvim` - testing framework (required for development)

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

**Note:** The `journal` configuration option is a placeholder for future features and is not yet functional.

### Telescope Commands

When telescope integration is enabled, the following commands are available:

| Command | Description |
|---------|-------------|
| `:DavewikiTags` | Open a telescope picker to search and navigate to tag files |
| `:DavewikiTagReferences [tag_name]` | Search for tag references across the wiki |

**Usage Examples:**

```vim
" Open tags picker - fuzzy find and jump to tag file
:DavewikiTags

" Search for all references to #bengal
:DavewikiTagReferences #bengal

" Show all tag references across the entire wiki
:DavewikiTagReferences
```

**Keymap Examples:**

```lua
-- Open tags picker with <leader>wt
vim.keymap.set('n', '<leader>wt', function()
    require('davewiki').telescope.tags()
end, { desc = 'Open davewiki tags picker' })

-- Search for references to tag under cursor with <leader>wr
vim.keymap.set('n', '<leader>wr', function()
    local tag = require('davewiki').core.get_tag_under_cursor()
    if tag then
        require('davewiki').telescope.tag_references(tag)
    else
        -- Show all tag references if cursor not on a tag
        require('davewiki').telescope.tag_references()
    end
end, { desc = 'Search tag references' })

-- Show all tag references with <leader>wR
vim.keymap.set('n', '<leader>wR', function()
    require('davewiki').telescope.tag_references()
end, { desc = 'Show all tag references' })
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
nix run .#nvim-test
```

This opens neovim with the `scripts/minimal-init.lua` configuration, which:
- Sets up davewiki with `./test_root` as the wiki root
- Includes example keybindings for jump-to-tag functionality
- Provides a minimal environment for testing features interactively

You can test the tag navigation by opening any markdown file in `test_root/` and pressing `<CR>` on a tag (e.g., `#bengal`).

You can test hyperlink navigation by pressing `<CR>` on a markdown link like `[notes](./notes.md)`or `[website](https://example.com)`.

### Running Tests

```sh
nix run .#nvim-test -- -u scripts/minimal-init.lua --headless -c 'PlenaryBustedDirectory tests' -c 'qa!'
```