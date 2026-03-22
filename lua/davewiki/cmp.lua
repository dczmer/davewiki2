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

--- Extracts the tag prefix from the current line
---@param line string The current line content
---@param col number The cursor column (0-indexed)
---@return string|nil The tag prefix (without #) or nil if not a valid tag position
local function get_tag_prefix(line, col)
	for i = col, 0, -1 do
		local char = line:sub(i + 1, i + 1)
		if char == "#" then
			if i == 0 then
				local prefix = line:sub(i + 2)
				if prefix and prefix:match("^[A-Za-z0-9]") then
					return prefix
				end
				return nil
			end
			local prev_char = line:sub(i, i)
			if prev_char:match("%s") or prev_char:match("%p") then
				local prefix = line:sub(i + 2)
				if prefix and prefix:match("^[A-Za-z0-9]") then
					return prefix
				end
			end
		end
	end
	return nil
end

--- Gets all tag names from tag files
---@return string[] Array of tag names with # prefix
local function get_all_tags()
	local core = require("davewiki.core")
	local tag_files = core.find_tag_files()
	local tags = {}

	for _, file_path in ipairs(tag_files) do
		local tag_name = file_path:match("([^/]+)%.md$")
		if tag_name then
			table.insert(tags, "#" .. tag_name)
		end
	end

	return tags
end

--- Wiki tags cmp source definition
local wiki_tags_source = {}

--- Creates a new wiki_tags cmp source instance
---@return table
function wiki_tags_source.new()
	local self = setmetatable({}, { __index = wiki_tags_source })
	local core = require("davewiki.core")
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
---@param params table Completion parameters (context, cursor, etc.)
---@return table[] Array of completion items
function wiki_tags_source:complete(params)
	local context = params
	if params.context then
		context = params.context
	end

	local line = context.line or ""
	local col = context.col or 1

	-- Check if there's a # in the line before the cursor
	local has_hash = false
	for i = 0, col do
		if line:sub(i + 1, i + 1) == "#" then
			has_hash = true
			break
		end
	end

	-- If no # before cursor, return empty
	if not has_hash then
		return {}
	end

	local prefix = get_tag_prefix(line, col)

	local all_tags = get_all_tags()

	-- If no prefix or empty prefix, return all tags
	if not prefix or prefix == "" then
		local matches = {}
		for _, tag in ipairs(all_tags) do
			table.insert(matches, {
				label = tag,
				kind = vim.lsp.protocol.CompletionItemKind.Reference,
				insertText = tag,
			})
		end
		return matches
	end

	local prefix_lower = prefix:lower()
	local matches = {}
	for _, tag in ipairs(all_tags) do
		local tag_lower = tag:lower()
		-- Skip the # prefix when comparing
		local tag_without_hash = tag_lower:sub(2)
		if tag_without_hash:sub(1, #prefix_lower) == prefix_lower then
			table.insert(matches, {
				label = tag,
				kind = vim.lsp.protocol.CompletionItemKind.Reference,
				insertText = tag,
			})
		end
	end

	return matches
end

--- Registers the wiki_tags cmp source for tag name completion
function cmp.register_tag_names()
	local cmp_module = _G.mock_cmp or require("cmp")
	cmp_module.register_source("wiki_tags", wiki_tags_source)
end

return cmp
