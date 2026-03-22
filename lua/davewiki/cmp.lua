---
-- @module davewiki.cmp
-- @brief nvim-cmp integration for tag auto-completion
-- @version 1.0

local cmp = {}

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

--- Check if cmp integration is enabled
---@return boolean
function cmp.is_enabled()
	return cmp.config.enabled
end

return cmp
