---
-- @module davewiki.telescope
-- @brief Telescope integration for search UI
-- @version 1.0

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
