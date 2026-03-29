---
-- @module davewiki
-- @brief Public interface for davewiki plugin
-- @version 1.0

local M = {}

local cmp = require("davewiki.cmp")
local core = require("davewiki.core")
local journal = require("davewiki.journal")
local telescope = require("davewiki.telescope")
local view = require("davewiki.view")

---@class DavewikiConfig
---@field wiki_root string Root directory for all notes (required)
---@field telescope DavewikiTelescopeConfig Telescope integration config
---@field cmp DavewikiCmpConfig nvim-cmp integration config
---@field journal DavewikiJournalConfig Journal module config
---@field show_tag_backlinks boolean Enable automatic backlink display in quickfix (default: true)
---@field highlight_tags boolean Enable tag syntax highlighting (default: true)

---@class DavewikiTelescopeConfig
---@field enabled boolean Enable telescope integration (default: true)

---@class DavewikiCmpConfig
---@field enabled boolean Enable nvim-cmp integration (default: true)

---@class DavewikiJournalConfig
---@field enabled boolean Enable journal module (default: true)

local default_config = {
    telescope = {
        enabled = true,
    },
    cmp = {
        enabled = true,
    },
    journal = {
        enabled = true,
    },
    show_tag_backlinks = true,
    highlight_tags = true,
}

---@type DavewikiConfig
local config = vim.deepcopy(default_config)

--- Setup the davewiki plugin with the given configuration
---@param user_config DavewikiConfig?
---@return table
function M.setup(user_config)
    if user_config then
        config = vim.tbl_deep_extend("force", config, user_config)
    end

    core.setup({ wiki_root = config.wiki_root })
    config.wiki_root = core.wiki_root

    core.setup_commands(config)

    if config.highlight_tags then
        vim.api.nvim_set_hl(0, "DavewikiTag", {
            fg = "#FF8C00",
            bg = "#2A2A2A",
            underline = true,
        })

        local augroup = vim.api.nvim_create_augroup("DaveWikiTagHighlight", { clear = true })
        vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            pattern = config.wiki_root .. "/*.md," .. config.wiki_root .. "/**/*.md",
            desc = "Apply tag highlighting to markdown files in wiki",
            callback = function()
                vim.fn.matchadd("DavewikiTag", core.TAG_PATTERN:gsub("+", "\\+") .. "\\>")
            end,
        })
    end

    if config.cmp.enabled then
        M.cmp = cmp
        M.cmp.setup({ enabled = true })
        M.cmp.register_tag_names()
    end

    if config.telescope.enabled then
        M.telescope = telescope
        M.telescope.setup({ enabled = true })
    end

    view.setup_commands()

    if config.journal.enabled then
        M.journal = journal
        M.journal.setup({ enabled = true })
        M.journal.setup_commands()
    end

    M.core = core

    return M
end

--- Get the current configuration
---@return DavewikiConfig
function M.get_config()
    return config
end

return M
