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
    telescope = {
        enabled = false,
    },
    cmp = {
        enabled = true,
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

-- setup cmp to test tag/link auto-completion
local cmp = require("cmp")
cmp.setup({
    completion = {
        completeopt = "menu,menuone,preview,noselect",
    },
    mappings = cmp.mapping.preset.insert({
        ["<Up>"] = cmp.mapping.select_prev_item(),
        ["<Down>"] = cmp.mapping.select_next_item(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping({
            i = function(fallback)
                if cmp.visible() and cmp.get_active_entry() then
                    cmp.confirm({ select = true })
                else
                    fallback()
                end
            end,
            c = cmp.mapping.confirm({ select = true }),
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { "i" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { "i" }),
    }),
    sources = cmp.config.sources({
        { name = "nvim_lsp", keyword_length = 1, priority = 1000 },
        { name = "wiki_tags", keyword_length = 1, priority = 800 },
        { name = "buffer", keyword_length = 3, priority = 500 },
        { name = "path", priority = 250 },
    }),
})

-- setup whichkey
require("which-key").setup({})
vim.keymap.set("n", "<leader>?", function()
    require("which-key").show()
end, { desc = "Show which-key" })
