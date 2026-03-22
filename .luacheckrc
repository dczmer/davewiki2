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
	"test_root/",
}

-- Allow mutating non-standard globals (vim.g, vim.b, etc.)
allow_defined = true
allow_defined_top = true
