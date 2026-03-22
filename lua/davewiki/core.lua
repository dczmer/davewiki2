---
-- @module davewiki.core
-- @brief General utilities library for davewiki
-- @version 1.0

local core = {}

---@class DavewikiCoreConfig
local default_config = {
	wiki_root = "",
}

core.config = default_config

--- Validate that wiki_root is set and exists
---@return boolean
function core.validate_wiki_root()
	local wiki_root = core.config.wiki_root
	if not wiki_root or wiki_root == "" then
		return false
	end
	return true
end

--- Get the wiki root directory path
---@return string
function core.get_wiki_root()
	return core.config.wiki_root
end

--- Path join utility
---@param ... string Path components to join
---@return string
function core.path_join(...)
	return table.concat({ ... }, "/")
end

return core
