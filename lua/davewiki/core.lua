---
-- @module davewiki.core
-- @brief Core utilities for davewiki plugin
-- @version 1.0

local M = {}

--- @type string|nil
M.wiki_root = nil

--- @class DavewikiCoreConfig
--- @field wiki_root string|nil Root directory for wiki

--- Setup davewiki.core with configuration options
--- @param opts DavewikiCoreConfig?
--- @return DavewikiCoreConfig
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
    M.wiki_root = vim.fn.fnamemodify(M.wiki_root, ":p")
    M.wiki_root = vim.fn.resolve(M.wiki_root)
    M.wiki_root = M.wiki_root:gsub("/+$", "")

    if not vim.fn.isdirectory(M.wiki_root) then
        if not opts.wiki_root and not vim.g.davewiki_wiki_root then
            vim.schedule(function()
                vim.api.nvim_echo({
                    {
                        "davewiki: wiki_root directory does not exist: " .. M.wiki_root,
                        "WarningMsg",
                    },
                    { "\n" },
                    {
                        "Using default path. Set g:davewiki_wiki_root or pass wiki_root to setup().",
                        "Normal",
                    },
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

--- Check if telescope.nvim is installed
--- @return boolean
M.is_telescope_installed = function()
    local ok, _ = pcall(require, "telescope")
    return ok
end

--- Pattern for matching valid tags (e.g., #tag-name)
--- @type string
M.TAG_PATTERN = "#[A-Za-z0-9-_]+"

--- Validates a tag name against the TAG_PATTERN
--- @param tag_name string The tag name to validate (with # prefix)
--- @return boolean
M.is_valid_tag = function(tag_name)
    if not tag_name or type(tag_name) ~= "string" then
        return false
    end
    return tag_name:match("^" .. M.TAG_PATTERN .. "$") ~= nil
end

--- Checks if a resolved path is within wiki_root (security validation).
--- @param path string The absolute path to validate (callers must resolve relative paths first)
--- @return boolean True if path is within wiki_root, false otherwise
M.is_path_within_wiki_root = function(path)
    if not M.wiki_root then
        return false
    end

    local real_wiki_root = vim.fn.resolve(M.wiki_root)
    local real_path = vim.fn.resolve(path)

    return real_path:sub(1, #real_wiki_root) == real_wiki_root
end

--- URL-encodes a path for use in markdown links
--- Only encodes characters that need encoding in local file paths
--- Keeps path separators (/) unencoded
--- @param str string The path to encode
--- @return string The URL-encoded path
M.url_encode = function(str)
    if not str or str == "" then
        return ""
    end

    local result = ""
    for i = 1, #str do
        local char = str:sub(i, i)

        if char:match("[A-Za-z0-9%-_./~]") then
            result = result .. char
        else
            result = result .. string.format("%%%02X", string.byte(char))
        end
    end

    return result
end

--- Checks if a file path is a tag file in the sources/ directory
--- @param file_path string The file path to check
--- @return boolean True if the file is a tag file
M.is_tag_file = function(file_path)
    if not file_path or not M.wiki_root then
        return false
    end

    if not file_path:match("%.md$") then
        return false
    end

    local sources_dir = M.wiki_root .. "/sources/"
    local resolved_path = vim.fn.resolve(file_path)
    local resolved_sources = vim.fn.resolve(sources_dir)

    return resolved_path:sub(1, #resolved_sources) == resolved_sources
end

--- Generate an absolute path from wiki_root for a target file
--- Returns path starting with "/" that is relative to wiki_root
--- @param target_file string The absolute path to the target file
--- @return string|nil The absolute path from wiki_root (e.g., "/notes/file.md"), or nil if outside wiki_root
M.generate_absolute_path = function(target_file)
    if not M.wiki_root or not target_file then
        return nil
    end

    local resolved_wiki_root = vim.fn.resolve(M.wiki_root)
    local resolved_target = vim.fn.resolve(target_file)

    if not M.is_path_within_wiki_root(resolved_target) then
        return nil
    end

    local relative_path = resolved_target:sub(#resolved_wiki_root + 1)

    if relative_path:sub(1, 1) ~= "/" then
        relative_path = "/" .. relative_path
    end

    return M.url_encode(relative_path)
end

return M
