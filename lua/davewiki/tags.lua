---
-- @module davewiki.tags
-- @brief Tag file management and tag operations
-- @version 1.0

local M = {}

local core = require("davewiki.core")

--- Pattern for matching valid tags (e.g., #tag-name)
--- @type string
M.TAG_PATTERN = "#[A-Za-z0-9-_]+"

--- Frontmatter template structure for tag files
--- @class TagFrontmatter
--- @field name string The tag name without the # prefix
--- @field created string ISO 8601 date (YYYY-MM-DD)

--- Creates a new frontmatter table for a tag file
--- @param tag_name string The tag name (with or without # prefix)
--- @return TagFrontmatter
M.create_frontmatter = function(tag_name)
    local name = tag_name:gsub("^#", "")
    local created = os.date("%Y-%m-%d")
    return {
        name = name,
        created = created,
    }
end

--- Scans all files in wiki_root for tags using ripgrep
--- @class TagScanResult
--- @field tag string The tag name (with # prefix)
--- @field count integer Number of occurrences
--- @field files table Array of file paths mentioning this tag

--- @return table Array of TagScanResult objects, sorted by count (descending)
M.scan_for_tags = function()
    if not core.wiki_root then
        return {}
    end

    local args = {
        "--only-matching",
        "--with-filename",
        M.TAG_PATTERN,
        core.wiki_root,
    }

    local lines = core.ripgrep(args)
    local tag_data = {}

    for _, line in ipairs(lines) do
        local file_path, tag = line:match("^(.-):(#[A-Za-z0-9-_]+)$")
        if file_path and tag and core.is_valid_tag(tag) then
            if not tag_data[tag] then
                tag_data[tag] = {
                    tag = tag,
                    count = 0,
                    files = {},
                    files_set = {},
                }
            end
            tag_data[tag].count = tag_data[tag].count + 1

            if not tag_data[tag].files_set[file_path] then
                tag_data[tag].files_set[file_path] = true
                table.insert(tag_data[tag].files, file_path)
            end
        end
    end

    local results = {}
    for _, data in pairs(tag_data) do
        data.files_set = nil
        table.insert(results, data)
    end

    table.sort(results, function(a, b)
        return a.count > b.count
    end)

    return results
end

--- Finds all tag files in the sources/ directory
--- @return table Array of file paths to tag files, sorted alphabetically
M.find_tag_files = function()
    if not core.wiki_root then
        return {}
    end

    local sources_dir = core.wiki_root .. "/sources"
    if vim.fn.isdirectory(sources_dir) ~= 1 then
        return {}
    end

    local args = {
        "--files",
        "--glob",
        "*.md",
        sources_dir,
    }

    local files = core.ripgrep(args)
    table.sort(files)
    return files
end

--- Creates and opens a tag file buffer with YAML frontmatter
--- The buffer is opened but not saved - user can save or quit to cancel.
--- @param tag_name string The tag name (with # prefix)
--- @return boolean Success
M.create_tag_file = function(tag_name)
    if not core.wiki_root or not core.is_valid_tag(tag_name) then
        return false
    end

    local name = tag_name:gsub("^#", "")

    if name:match("[./\\]") then
        return false
    end

    local tag_file_path = M.get_tag_file_path(tag_name)

    local sources_dir = core.wiki_root .. "/sources"
    if vim.fn.isdirectory(sources_dir) ~= 1 then
        vim.fn.mkdir(sources_dir, "p")
    end

    if vim.fn.filereadable(tag_file_path) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(tag_file_path))
        return true
    end

    local frontmatter = M.create_frontmatter(tag_name)

    local content = {
        "---",
        "name: " .. frontmatter.name,
        "created: " .. frontmatter.created,
        "---",
        "",
        "# " .. frontmatter.name,
        "",
        "Tag file for " .. tag_name .. " related notes.",
    }

    vim.cmd("edit " .. vim.fn.fnameescape(tag_file_path))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

    return true
end

--- Validates frontmatter in all tag files
--- Checks against required fields defined in the frontmatter template
--- @return table Array of violation objects { file = string, issue = string }
M.validate_frontmatter = function()
    local violations = {}
    local tag_files = M.find_tag_files()

    local template = M.create_frontmatter("#template")
    local required_fields = {}
    for key, _ in pairs(template) do
        table.insert(required_fields, key)
    end

    for _, file_path in ipairs(tag_files) do
        if vim.fn.filereadable(file_path) == 1 then
            local content = vim.fn.readfile(file_path)
            local content_str = table.concat(content, "\n")

            if not content_str:match("^%-%-%-\n") then
                table.insert(violations, {
                    file = file_path,
                    issue = "Missing YAML frontmatter",
                })
            else
                local content_after_opening = content_str:sub(5)
                local frontmatter_end_rel = content_after_opening:find("\n%-%-%-\n")
                    or content_after_opening:find("\n%-%-%-$")
                if not frontmatter_end_rel then
                    table.insert(violations, {
                        file = file_path,
                        issue = "Incomplete YAML frontmatter",
                    })
                else
                    local frontmatter = content_after_opening:sub(1, frontmatter_end_rel - 1)

                    for _, field in ipairs(required_fields) do
                        if not frontmatter:match(field .. ":%s*") then
                            table.insert(violations, {
                                file = file_path,
                                issue = "Missing '" .. field .. "' field in frontmatter",
                            })
                        end
                    end
                end
            end
        end
    end

    return violations
end

--- Gets the tag under the current cursor position
--- @return string|nil The tag name with # prefix, or nil if cursor is not on a tag
M.get_tag_under_cursor = function()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local col_num = cursor_pos[2]

    local line = vim.api.nvim_get_current_line()

    local start_pos = 1
    while true do
        local tag_start, tag_end = line:find(M.TAG_PATTERN, start_pos)
        if not tag_start then
            break
        end

        if col_num >= tag_start - 1 and col_num < tag_end then
            return line:sub(tag_start, tag_end)
        end

        start_pos = tag_end + 1
    end

    return nil
end

--- Jumps to a tag file, creating it if necessary
--- Opens a buffer with the file content so user can save or discard.
--- @param tag_name string The tag name (with # prefix)
--- @return boolean Success
M.jump_to_tag_file = function(tag_name)
    if not core.wiki_root or not core.is_valid_tag(tag_name) then
        return false
    end

    return M.create_tag_file(tag_name)
end

--- Jumps to the tag file under the cursor
--- Creates the tag file if it doesn't exist
--- @return boolean True if jump was successful, false otherwise
M.jump_to_tag = function()
    local tag = M.get_tag_under_cursor()
    if tag then
        return M.jump_to_tag_file(tag)
    end
    return false
end

--- Gets the file path for a tag's source file
--- @param tag_name string The tag name (with or without # prefix)
--- @return string|nil The path to the tag file, or nil if wiki_root not set
M.get_tag_file_path = function(tag_name)
    if not core.wiki_root or not tag_name then
        return nil
    end

    local name = tag_name:gsub("^#", "")
    return core.wiki_root .. "/sources/" .. name .. ".md"
end

--- Extracts the tag name from a tag file path
--- Returns the tag name (without # prefix) if path is a valid tag file, nil otherwise
--- @param file_path string The file path
--- @return string|nil The tag name or nil
M.extract_tag_from_filename = function(file_path)
    if not file_path then
        return nil
    end

    if not core.is_tag_file(file_path) then
        return nil
    end

    local filename = vim.fn.fnamemodify(file_path, ":t:r")
    return filename
end

--- Extracts a summary of a line, centered around the tag position
--- Truncates to max_length while ensuring the tag is visible
--- @param line_content string The full line content
--- @param tag_start_col integer The column position (0-indexed) where the tag starts
--- @param max_length integer|nil Maximum length of summary (default: 80)
--- @return string The extracted summary
M.extract_summary = function(line_content, tag_start_col, max_length)
    max_length = max_length or 80

    if not line_content or #line_content <= max_length then
        return line_content or ""
    end

    local half_window = math.floor(max_length / 2)

    local start_pos = tag_start_col - half_window
    local end_pos = tag_start_col + half_window

    if start_pos < 0 then
        end_pos = end_pos - start_pos
        start_pos = 0
    end

    if end_pos > #line_content then
        start_pos = start_pos - (end_pos - #line_content)
        end_pos = #line_content
        if start_pos < 0 then
            start_pos = 0
        end
    end

    local summary = line_content:sub(start_pos + 1, end_pos)

    return summary
end

--- Formats a backlink match into a quickfix-compatible entry
--- @param file_path string The file path
--- @param line_num integer The line number (1-indexed)
--- @param col_num integer The column number (1-indexed)
--- @param line_content string The full line content
--- @param tag_name string The tag name being searched for
--- @return table Quickfix entry with filename, lnum, col, and text fields
M.format_quickfix_entry = function(file_path, line_num, col_num, line_content, tag_name)
    local summary = M.extract_summary(line_content, col_num - 1, 80)

    return {
        filename = file_path,
        lnum = line_num,
        col = col_num,
        text = summary,
    }
end

--- @class BacklinkMatch
--- @field file string The file path containing the reference
--- @field lnum integer The line number (1-indexed)
--- @field col integer The column number (1-indexed)
--- @field line string The line content (truncated to 80 chars)

--- Finds all backlinks (references) to a tag across wiki_root
--- Uses ripgrep to search for exact tag matches
--- @param tag_name string The tag name to search for (with # prefix)
--- @return table Array of BacklinkMatch objects
M.find_backlinks = function(tag_name)
    if not core.wiki_root or not tag_name then
        return {}
    end

    if not core.is_valid_tag(tag_name) then
        return {}
    end

    local args = {
        "--line-number",
        "--column",
        "--fixed-strings",
        tag_name,
        core.wiki_root,
    }

    local lines = core.ripgrep(args)
    local backlinks = {}

    for _, line in ipairs(lines) do
        local file_path, line_num, col_num, content = line:match("^(.-):(%d+):(%d+):(.*)$")

        if file_path and line_num and col_num then
            line_num = tonumber(line_num)
            col_num = tonumber(col_num)

            if not core.is_tag_file(file_path) then
                table.insert(backlinks, {
                    file = file_path,
                    lnum = line_num,
                    col = col_num,
                    line = content,
                })
            end
        end
    end

    return backlinks
end

--- Get a sorted list of unique tags from the wiki
--- Uses core.scan_for_tags() to find all tags across wiki_root
---@return table Array of tag names (with # prefix), sorted alphabetically
M.get_tags_list = function()
    if not core.wiki_root then
        return {}
    end

    local tag_data = M.scan_for_tags()
    local tags = {}

    for _, data in ipairs(tag_data) do
        table.insert(tags, data.tag)
    end

    table.sort(tags)

    return tags
end

--- Get all references for a tag or all tag references in the wiki
--- When tag_name is provided, returns references to that specific tag
--- When tag_name is nil, returns all references to any tag
---@param tag_name string? The tag name to search for (with # prefix), optional
---@return table Array of reference objects with file, lnum, col, line, tag fields
M.get_tag_references = function(tag_name)
    if not core.wiki_root then
        return {}
    end

    if tag_name then
        if not core.is_valid_tag(tag_name) then
            return {}
        end
        return M.find_backlinks(tag_name)
    end

    local args = {
        "--line-number",
        "--column",
        "--only-matching",
        M.TAG_PATTERN,
        core.wiki_root,
    }

    local lines = core.ripgrep(args)
    local references = {}
    local seen = {}

    for _, line in ipairs(lines) do
        local file_path, line_num, col_num, tag = line:match("^(.-):(%d+):(%d+):(#.+)$")
        if file_path and line_num and col_num then
            if not core.is_tag_file(file_path) then
                local key = file_path .. ":" .. line_num .. ":" .. col_num
                if not seen[key] then
                    seen[key] = true
                    table.insert(references, {
                        file = file_path,
                        lnum = tonumber(line_num),
                        col = tonumber(col_num),
                        line = tag,
                        tag = tag,
                    })
                end
            end
        end
    end

    return references
end

--- Setup user commands and autocommands for tag functionality
---@param config table Configuration table with show_tag_backlinks and wiki_root
function M.setup_commands(config)
    if config.show_tag_backlinks then
        local augroup = vim.api.nvim_create_augroup("DaveWikiBacklinks", { clear = true })

        vim.api.nvim_create_autocmd("BufReadPost", {
            group = augroup,
            pattern = config.wiki_root .. "/sources/*.md",
            desc = "Show backlinks when entering a tag file",
            callback = function(args)
                local file_path = vim.api.nvim_buf_get_name(args.buf)
                local tag_name = M.extract_tag_from_filename(file_path)
                if not tag_name then
                    return
                end

                local backlinks = M.find_backlinks("#" .. tag_name)
                if #backlinks == 0 then
                    return
                end

                local qf_list = {}
                for _, backlink in ipairs(backlinks) do
                    table.insert(qf_list, {
                        filename = backlink.file,
                        lnum = backlink.lnum,
                        col = backlink.col,
                        text = backlink.line,
                    })
                end

                vim.fn.setqflist(qf_list, "r")
                vim.cmd("copen")
            end,
        })

        vim.api.nvim_create_autocmd("BufLeave", {
            group = augroup,
            pattern = config.wiki_root .. "/sources/*.md",
            desc = "Close quickfix when leaving a tag file",
            callback = function(args)
                local file_path = vim.api.nvim_buf_get_name(args.buf)
                if not core.is_tag_file(file_path) then
                    return
                end
                vim.cmd("cclose")
            end,
        })
    end
end

return M
