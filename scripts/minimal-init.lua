vim.opt.runtimepath:append(".")

-- some minimal config
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"
vim.cmd([[
    filetype on
    filetype indent on
    filetype plugin on
    syntax on
]])
vim.cmd.colorscheme("elflord")

-- import davewiki with all modules disabled initially to keep tests simple.
-- when you need to test a sub-system, initialize it by calling it's `setup()` directly.
-- we use ./test_root as the location for our notes and the tests are allowed to modify this folder.
local davewiki = require("davewiki").setup({
    wiki_root = "./test_root",
    show_tag_backlinks = true,
    telescope = {
        enabled = false,
    },
    cmp = {
        enabled = false,
    },
    journal = {
        enabled = false,
    },
})

-- example of how to bind `jump_to_tag` to `<CR>` for navigation
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.keymap.set("n", "<CR>", function()
            -- Try tag first, then link
            if not davewiki.jump_to_tag() then
                davewiki.jump_to_link()
            end
        end, { buffer = true, desc = "Jump to tag or link under cursor" })
    end,
})

-- setup whichkey
require("which-key").setup({})
vim.keymap.set("n", "<leader>?", function()
    require("which-key").show()
end, { desc = "Show which-key" })
