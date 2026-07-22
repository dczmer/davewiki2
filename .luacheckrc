-- Luacheck configuration for davewiki Neovim plugin
-- See: https://luacheck.readthedocs.io/en/stable/config.html

globals = {
    "vim",
}

-- Don't report unused self arguments in methods
self = false

-- Don't report unused arguments
unused_args = false

-- Don't report accesses to undefined fields of global variables (for vim.*)
read_globals = {
    "vim",
}

-- Files and directories to exclude
exclude_files = {
    ".direnv/",
}

-- Allow mutating non-standard globals (vim.g, vim.b, etc.)
allow_defined = true
allow_defined_top = true

-- Per-file overrides
-- test_util.lua intentionally replaces vim.notify and vim.ui.open with test
-- mocks; this is the only place the plugin does so.
files["lua/davewiki/test_util.lua"] = {
    ignore = { "122" },
}

-- scripts/davewiki2-init.lua is a Neovim init script that sets leaders the
-- standard way (vim.g.mapleader, vim.g.maplocalleader).
files["scripts/davewiki2-init.lua"] = {
    ignore = { "122" },
}

-- scripts/minimal-init.lua is a minimal test init script that sets leaders the
-- standard way (vim.g.mapleader, vim.g.maplocalleader).
files["scripts/minimal-init.lua"] = {
    ignore = { "122" },
}
