---
-- @module davewiki
-- @brief Public interface for davewiki plugin
-- @version 1.0

local M = {}

---@class DavewikiConfig
---@field wiki_root string Root directory for all notes (required)
---@field telescope DavewikiTelescopeConfig Telescope integration config
---@field cmp DavewikiCmpConfig nvim-cmp integration config
---@field journal DavewikiJournalConfig Journal module config

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
}

---@type DavewikiConfig
local config = vim.deepcopy(default_config)

local core = require("davewiki.core")

--- Setup the davewiki plugin with the given configuration
---@param user_config DavewikiConfig?
---@return table
function M.setup(user_config)
    if user_config then
        config = vim.tbl_deep_extend("force", config, user_config)
    end

    core.setup({ wiki_root = config.wiki_root })
    config.wiki_root = core.wiki_root

    if config.cmp.enabled then
        M.cmp = require("davewiki.cmp")
        M.cmp.setup({ enabled = true })
        M.cmp.register_tag_names()
    end

    return M
end

--- Jump to the tag file under the cursor
--- Creates the tag file if it doesn't exist
---
--- @return boolean True if jump was successful, false otherwise
function M.jump_to_tag()
    local tag = core.get_tag_under_cursor()
    if tag then
        return core.jump_to_tag_file(tag)
    end
    return false
end

--- Jump to the hyperlink under the cursor
--- Opens the linked file or URL. For internal links, resolves relative to
--- the current file or wiki_root (for absolute paths). For external URLs,
--- opens in the system default browser.
---
--- @return boolean True if jump was successful, false otherwise
function M.jump_to_link()
    return core.jump_to_link()
end

--- Get the current configuration
---@return DavewikiConfig
function M.get_config()
    return config
end

return M
