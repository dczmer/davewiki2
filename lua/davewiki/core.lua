local M = {}

---@type string|nil
M.wiki_root = nil

---@class DavewikiCoreConfig
---@field wiki_root string|nil Root directory for wiki

--- Setup davewiki.core with configuration options
---@param opts DavewikiCoreConfig?
---@return DavewikiCoreConfig
M.setup = function(opts)
	opts = opts or {}

	local default_wiki_root = "~/davewiki"

	if opts.wiki_root then
		M.wiki_root = opts.wiki_root
	elseif vim.g.davewiki_wiki_root then
		M.wiki_root = vim.g.davewiki_wiki_root
	else
		M.wiki_root = default_wiki_root
	end

	M.wiki_root = vim.fn.expand(M.wiki_root)

	if not vim.fn.isdirectory(M.wiki_root) then
		if not opts.wiki_root and not vim.g.davewiki_wiki_root then
			vim.schedule(function()
				vim.api.nvim_echo({
					{ "davewiki: wiki_root directory does not exist: " .. M.wiki_root, "WarningMsg" },
					{ "\n" },
					{ "Using default path. Set g:davewiki_wiki_root or pass wiki_root to setup().", "Normal" },
				}, false, {})
			end)
		end
	end

	return M
end

--- Executes a ripgrep command and returns the matching lines.
--- Uses vim.system() to avoid shell injection vulnerabilities.
--- @param args table Array of string arguments to pass to ripgrep
--- @return table Array of matching lines from ripgrep output, or empty table on failure
M.ripgrep = function(args)
	local result = vim.system({ "rg", unpack(args) }, { text = true }):wait()

	if result.code ~= 0 then
		return {}
	end

	local lines = {}
	for line in result.stdout:gmatch("[^\n]+") do
		table.insert(lines, line)
	end
	return lines
end

return M
