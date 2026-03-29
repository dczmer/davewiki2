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

local telescope = require("telescope")
telescope.setup({
    defaults = {
        file_ignore_patterns = {
            "^%.git/",
            "result/",
            ".direnv/",
        },
    },
})
telescope.load_extension("fzf")

-- we use ./test_root as the location for our notes and the tests are allowed to modify this folder.
local davewiki = require("davewiki").setup({
    wiki_root = "./test_root",
    show_tag_backlinks = true,
    highlight_tags = true,
    telescope = {
        enabled = true,
    },
    cmp = {
        enabled = true,
    },
    journal = {
        enabled = true,
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
