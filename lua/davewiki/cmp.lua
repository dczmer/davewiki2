---
-- @module davewiki.cmp
-- @brief nvim-cmp integration for tag auto-completion
-- @version 1.0

local cmp = {}
local core = require("davewiki.core")

---@class DavewikiCmpConfig
---@field enabled boolean Enable cmp integration

cmp.config = {
    enabled = true,
}

--- Setup cmp integration
---@param config DavewikiCmpConfig?
function cmp.setup(config)
    if config then
        cmp.config = vim.tbl_deep_extend("force", cmp.config, config)
    end
end

--- Wiki tags cmp source definition
local wiki_tags_source = {}

--- Creates a new wiki_tags cmp source instance
---@return table
function wiki_tags_source.new()
    local self = setmetatable({}, { __index = wiki_tags_source })
    self.wiki_root = core.wiki_root
    return self
end

--- Gets the trigger characters for this source
---@return string[]
function wiki_tags_source:get_trigger_characters()
    return { "#" }
end

--- Checks if this source is available in the current context
---@return boolean
function wiki_tags_source:is_available()
    local buf = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[buf].filetype
    return filetype == "markdown"
end

--- Performs completion for tag names
function wiki_tags_source:complete(params, callback)
    local tags = core.scan_for_tags()

    local items = {}
    for _, tag_data in ipairs(tags) do
        table.insert(items, {
            label = tag_data.tag,
            kind = require("cmp").lsp.CompletionItemKind.Text,
            documentation = "Used " .. tag_data.count .. " times",
            insertText = tag_data.tag,
        })
    end

    callback({ items = items, isIncomplete = false })
end

--- Registers the wiki_tags cmp source for tag name completion
function cmp.register_tag_names()
    local cmp_module = _G.mock_cmp or require("cmp")
    cmp_module.register_source("wiki_tags", wiki_tags_source)
end

return cmp
