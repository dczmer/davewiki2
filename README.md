# davewiki

A personal knowledge base system for neovim with journal-based note-taking, inspired by Logseq.

## What it does

- Manages a directory of markdown notes and daily journals
- Organizes notes using flat tags (`#tag-name`) with back-reference tracking
- Provides quick search and navigation between tags, notes, and journals
- Integrates with telescope.nvim and nvim-cmp for completion

## Key features

- Journal-based daily note-taking
- Tag-based organization with back-references
- Markdown link navigation
- Tag autocomplete
- Full-text search across all notes

## How it works

### Wiki Root

All your notes are stored in a configurable `wiki_root` directory (e.g., `~/.davewiki`). All paths mentioned below are relative to this root directory.

### Journals

Your daily notes live in `journals/`. Each journal file is a markdown document where you capture thoughts, ideas, and notes for that day.

### Tags

Tags (`#tag-name`) create connections between notes. When you add a tag to a block in your journal, that block becomes associated with the tag.

- Tags are flat (not hierarchical): `#my-tag`, `#another-tag`
- Tag files live under `sources/` as anchor files
- Jump to any tag file to see all back-references

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
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `wiki_root` | string | **Required** | Root directory for all notes |
| `telescope.enabled` | boolean | `true` | Enable telescope integration |
| `cmp.enabled` | boolean | `true` | Enable nvim-cmp integration |
| `journal.enabled` | boolean | `true` | Enable journal module |