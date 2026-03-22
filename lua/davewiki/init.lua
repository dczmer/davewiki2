---
-- @module davewiki
-- @brief Public interface for davewiki plugin
-- @version 1.0

local davewiki = {}

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
	wiki_root = "",
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

--- Setup the davewiki plugin with the given configuration
---@param user_config DavewikiConfig?
---@return DavewikiConfig
function davewiki.setup(user_config)
	if user_config then
		config = vim.tbl_deep_extend("force", config, user_config)
	end
	return config
end

--- Get the current configuration
---@return DavewikiConfig
function davewiki.get_config()
	return config
end

return davewiki
