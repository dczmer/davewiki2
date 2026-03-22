-- Minimal neovim configuration for testing davewiki plugin

-- Set runtimepath to include plugin and dependencies
vim.opt.runtimepath:append(vim.fn.fnamemodify(debug.getinfo(1).source:match("@(.*/)"), ":p") .. "..")
vim.opt.runtimepath:append(vim.fn.fnamemodify(debug.getinfo(1).source:match("@(.*/)"), ":p") .. "../../lua")

-- Set wiki_root to test_root for tests
vim.g.davewiki_test_root = vim.fn.fnamemodify(debug.getinfo(1).source:match("@(.*/)"), ":p") .. "../test_root"

-- Minimal plugin setup for testing
vim.opt.runtimepath:append(vim.g.davewiki_test_root)

-- Suppress startup messages
vim.opt.shortmess:append("I")

-- Minimal UI
vim.opt.number = false
vim.opt.relativenumber = false
