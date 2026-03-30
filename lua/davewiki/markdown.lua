---
-- @module davewiki.markdown
-- @brief Markdown link and file operations
-- @version 1.0

local M = {}

local core = require("davewiki.core")

--- Pattern for matching markdown links [text](path)
--- @type string
M.LINK_PATTERN = "%[([^%]]*)%]%(([^)]+)%)"

--- @class LinkInfo
--- @field text string The link text (display text)
--- @field path string The link target (URL or file path)
--- @field is_url boolean Whether the link is an external URL
--- @field start_col integer The starting column of the link (0-indexed)
--- @field end_col integer The ending column of the link (0-indexed, exclusive)

--- Gets the markdown link under the current cursor position
--- @return LinkInfo|nil Link info if cursor is on a valid markdown link, nil otherwise
M.get_link_under_cursor = function()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local col_num = cursor_pos[2]

    local line = vim.api.nvim_get_current_line()

    local start_pos = 1
    while true do
        local match_start, match_end, link_text, link_path = line:find(M.LINK_PATTERN, start_pos)
        if not match_start then
            break
        end

        local link_start_0indexed = match_start - 1
        local link_end_0indexed = match_end

        if col_num >= link_start_0indexed and col_num < link_end_0indexed then
            local is_url = link_path:match("^https?://") ~= nil

            return {
                text = link_text,
                path = link_path,
                is_url = is_url,
                start_col = link_start_0indexed,
                end_col = link_end_0indexed,
            }
        end

        start_pos = match_end + 1
    end

    return nil
end

--- Resolves a link path relative to the directory containing the current file or wiki_root.
---
--- Path resolution:
--- - Absolute paths (starting with `/`) are resolved relative to wiki_root
--- - Relative paths are resolved relative to the directory containing current_file
--- - If no current_file, relative paths resolve against wiki_root
---
--- @param path string The link path (relative or absolute within wiki_root)
--- @param current_file string? The current buffer's file path
--- @return string|nil resolved_path The resolved absolute path, or nil if invalid
--- @return string|nil error Error message if resolution failed
M.resolve_link_path = function(path, current_file)
    if not core.wiki_root then
        return nil, "wiki_root not configured"
    end

    if path:sub(1, 1) == "/" then
        local absolute_path = core.wiki_root .. path

        if not core.is_path_within_wiki_root(absolute_path) then
            return nil, "path escapes wiki_root"
        end

        return absolute_path, nil
    end

    if current_file then
        local current_dir = vim.fn.fnamemodify(current_file, ":h")
        local resolved = vim.fn.resolve(current_dir .. "/" .. path)

        if not core.is_path_within_wiki_root(resolved) then
            return nil, "path escapes wiki_root"
        end

        return resolved, nil
    end

    local resolved = core.wiki_root .. "/" .. path
    return vim.fn.resolve(resolved), nil
end

--- Jumps to the linked file or opens URL in browser
--- @return boolean Success
M.jump_to_link = function()
    if not core.wiki_root then
        return false
    end

    local link = M.get_link_under_cursor()
    if not link then
        return false
    end

    if link.is_url then
        vim.ui.open(link.path)
        return true
    end

    if not link.path:match("%.md$") then
        vim.notify("davewiki: Only .md files are supported for internal links", vim.log.levels.WARN)
        return false
    end

    local current_file = vim.api.nvim_buf_get_name(0)

    local target_path, err = M.resolve_link_path(link.path, current_file)

    if err then
        vim.notify("davewiki: " .. err, vim.log.levels.ERROR)
        return false
    end

    if not core.is_path_within_wiki_root(target_path) then
        vim.notify("davewiki: path escapes wiki_root", vim.log.levels.ERROR)
        return false
    end

    if vim.fn.filereadable(target_path) ~= 1 then
        vim.notify("davewiki: file not found: " .. target_path, vim.log.levels.WARN)
        return false
    end

    vim.cmd("edit " .. vim.fn.fnameescape(target_path))
    return true
end

--- Gets a list of all markdown files under wiki_root, excluding tag files and attachments
--- Uses ripgrep for efficient file searching
--- @return table Array of markdown file paths
M.get_markdown_files = function()
    if not core.wiki_root then
        return {}
    end

    local args = {
        "--files",
        "--type",
        "md",
        core.wiki_root,
    }

    local lines = core.ripgrep(args)
    local files = {}

    for _, line in ipairs(lines) do
        local resolved_line = vim.fn.resolve(line)
        local is_tag_file = core.is_tag_file(resolved_line)
        local is_attachment = resolved_line:match("/attachments/") ~= nil

        if not is_tag_file and not is_attachment then
            table.insert(files, resolved_line)
        end
    end

    return files
end

--- Extracts the first H1 heading from a file, or returns the filename without extension
--- @param file_path string The file path to read
--- @return string|nil The title (H1 content or filename), or nil if file doesn't exist
M.extract_h1_or_filename = function(file_path)
    if not file_path then
        return nil
    end

    local expanded_path = vim.fn.expand(file_path)
    expanded_path = vim.fn.fnamemodify(expanded_path, ":p")

    local file = io.open(expanded_path, "r")
    if not file then
        return nil
    end

    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    for _, line in ipairs(lines) do
        local heading = line:match("^#%s+(.+)$")
        if heading then
            return heading
        end
    end

    local filename = vim.fn.fnamemodify(expanded_path, ":t:r")
    return filename
end

--- Creates a markdown link from an absolute file path
--- @param file_path string The absolute file path
--- @param title string|nil Optional title for the link (defaults to filename without extension)
--- @return string|nil Markdown link in format [title](/path), or nil if path is outside wiki_root
M.make_markdown_link = function(file_path, title)
    local encoded_path = core.generate_absolute_path(file_path)

    if not encoded_path then
        return nil
    end

    local link_title = title or vim.fn.fnamemodify(file_path, ":t:r")
    return "[" .. link_title .. "](" .. encoded_path .. ")"
end

--- Get a sorted list of all level-1 headings from the wiki
--- Uses ripgrep to find lines starting with "# " (but not "##")
---@return table Array of heading objects with text, file, and lnum fields
M.get_headings_list = function()
    if not core.wiki_root then
        return {}
    end

    local args = {
        "--line-number",
        "--column",
        "^# [^#].*$",
        core.wiki_root,
        "--type",
        "md",
    }

    local lines = core.ripgrep(args)
    local headings = {}

    for _, line in ipairs(lines) do
        local file_path, line_num, _, content = line:match("^(.-):(%d+):(%d+):(.*)$")

        if file_path and line_num and content then
            table.insert(headings, {
                text = content,
                file = file_path,
                lnum = tonumber(line_num),
            })
        end
    end

    table.sort(headings, function(a, b)
        return a.text < b.text
    end)

    return headings
end

return M
