---
-- @module davewiki.telescope
-- @brief Telescope integration for search UI (placeholder for future implementation)
-- @version 1.0
-- @deprecated This module is a placeholder stub. The telescope integration
-- is not yet implemented. The config options are accepted for forward
-- compatibility, but no telescope functions are called.

local telescope = {}

---@class DavewikiTelescopeConfig
---@field enabled boolean Enable telescope integration

telescope.config = {
    enabled = true,
}

--- Setup telescope integration
---@param config DavewikiTelescopeConfig?
function telescope.setup(config)
    if config then
        telescope.config = vim.tbl_deep_extend("force", telescope.config, config)
    end
end

--- Check if telescope integration is enabled
---@return boolean
function telescope.is_enabled()
    return telescope.config.enabled
end

return telescope
