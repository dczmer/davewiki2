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
    pickers = {
        find_files = {
            theme = "dropdown",
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
        },
        live_grep = {
            additional_args = function()
                return { "--hidden" }
            end,
        },
    },
})
telescope.load_extension("fzf")

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
        { name = "wiki_tags", keyword_length = 1, priority = 800 },
    }),
})

-- setup whichkey
require("which-key").setup({})
vim.keymap.set("n", "<leader>?", function()
    require("which-key").show()
end, { desc = "Show which-key" })

-- import davewiki with all modules disabled initially to keep tests simple.
-- when you need to test a sub-system, initialize it by calling it's `setup()` directly.
-- we use ./test_root as the location for our notes and the tests are allowed to modify this folder.
local davewiki = require("davewiki").setup({
    wiki_root = "./test_root",
    show_tag_backlinks = true,
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

-- davewiki telescope keymaps
vim.keymap.set("n", "<leader>wt", function()
    require("davewiki").telescope.tags()
end, { desc = "Open davewiki tags picker" })

vim.keymap.set("n", "<leader>wT", function()
    require("davewiki").telescope.tag_references()
end, { desc = "Search davewiki tag references" })
