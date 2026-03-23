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
    M.wiki_root = vim.fn.fnamemodify(M.wiki_root, ":p")
    M.wiki_root = vim.fn.resolve(M.wiki_root)
    -- Strip trailing slash for consistent path comparisons
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

-- ============================================================================
-- TAG FILE MANAGEMENT
-- ============================================================================

--- Pattern for matching valid tags (e.g., #tag-name)
--- @type string
M.TAG_PATTERN = "#[A-Za-z0-9-_]+"

--- Frontmatter template structure for tag files
--- @class TagFrontmatter
--- @field name string The tag name without the # prefix
--- @field created string ISO 8601 date (YYYY-MM-DD)
M.TagFrontmatter = {}

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

--- Validates a tag name against the TAG_PATTERN
--- @param tag_name string The tag name to validate (with # prefix)
--- @return boolean
M.is_valid_tag = function(tag_name)
    if not tag_name or type(tag_name) ~= "string" then
        return false
    end
    return tag_name:match("^" .. M.TAG_PATTERN .. "$") ~= nil
end

--- Scans all files in wiki_root for tags using ripgrep
--- @class TagScanResult
--- @field tag string The tag name (with # prefix)
--- @field count integer Number of occurrences
--- @field files table Array of file paths mentioning this tag

--- @return table Array of TagScanResult objects, sorted by count (descending)
M.scan_for_tags = function()
    if not M.wiki_root then
        return {}
    end

    local args = {
        "--only-matching",
        "--with-filename",
        M.TAG_PATTERN,
        M.wiki_root,
    }

    local lines = M.ripgrep(args)
    local tag_data = {}

    for _, line in ipairs(lines) do
        -- Parse "filename:tag" format from ripgrep
        local file_path, tag = line:match("^(.-):(#[A-Za-z0-9-_]+)$")
        if file_path and tag and M.is_valid_tag(tag) then
            if not tag_data[tag] then
                tag_data[tag] = {
                    tag = tag,
                    count = 0,
                    files = {},
                    files_set = {}, -- Track unique files
                }
            end
            tag_data[tag].count = tag_data[tag].count + 1

            -- Track unique files only
            if not tag_data[tag].files_set[file_path] then
                tag_data[tag].files_set[file_path] = true
                table.insert(tag_data[tag].files, file_path)
            end
        end
    end

    -- Convert to array and sort by count (descending)
    local results = {}
    for _, data in pairs(tag_data) do
        -- Remove the temporary files_set before returning
        data.files_set = nil
        table.insert(results, data)
    end

    table.sort(results, function(a, b)
        return a.count > b.count
    end)

    return results
end

--- Finds all tag files in the sources/ directory
--- @return table Array of file paths to tag files
M.find_tag_files = function()
    if not M.wiki_root then
        return {}
    end

    local sources_dir = M.wiki_root .. "/sources"
    if vim.fn.isdirectory(sources_dir) ~= 1 then
        return {}
    end

    local args = {
        "--files",
        "--glob",
        "*.md",
        sources_dir,
    }

    return M.ripgrep(args)
end

--- Creates a tag file with proper YAML frontmatter
--- @param tag_name string The tag name (with # prefix)
--- @return boolean Success
M.create_tag_file = function(tag_name)
    if not M.wiki_root or not M.is_valid_tag(tag_name) then
        return false
    end

    local name = tag_name:gsub("^#", "")

    -- Security: validate the tag name doesn't contain path traversal
    if name:match("[./\\]") then
        return false
    end

    local sources_dir = M.wiki_root .. "/sources"
    local tag_file_path = sources_dir .. "/" .. name .. ".md"

    -- Ensure sources directory exists
    if vim.fn.isdirectory(sources_dir) ~= 1 then
        vim.fn.mkdir(sources_dir, "p")
    end

    -- Check if file already exists
    if vim.fn.filereadable(tag_file_path) == 1 then
        return true -- File already exists, consider it success
    end

    -- Create frontmatter
    local frontmatter = M.create_frontmatter(tag_name)

    -- Build file content
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

    -- Write file
    local success = vim.fn.writefile(content, tag_file_path)
    return success == 0
end

--- Validates frontmatter in all tag files
--- Checks against required fields defined in the frontmatter template
--- @return table Array of violation objects { file = string, issue = string }
M.validate_frontmatter = function()
    local violations = {}
    local tag_files = M.find_tag_files()

    -- Get required fields from template (keys in a sample frontmatter)
    local template = M.create_frontmatter("#template")
    local required_fields = {}
    for key, _ in pairs(template) do
        table.insert(required_fields, key)
    end

    for _, file_path in ipairs(tag_files) do
        if vim.fn.filereadable(file_path) == 1 then
            local content = vim.fn.readfile(file_path)
            local content_str = table.concat(content, "\n")

            -- Check if file starts with frontmatter
            if not content_str:match("^%-%-%-\n") then
                table.insert(violations, {
                    file = file_path,
                    issue = "Missing YAML frontmatter",
                })
            else
                -- Extract frontmatter (find the closing --- after the opening line)
                -- Skip the first line (---) and search for the next ---
                -- Note: Must escape hyphens with %% in Lua patterns
                local content_after_opening = content_str:sub(5)
                -- Match \n---\n or \n--- at end of string
                local frontmatter_end_rel = content_after_opening:find("\n%-%-%-\n")
                    or content_after_opening:find("\n%-%-%-$")
                if not frontmatter_end_rel then
                    table.insert(violations, {
                        file = file_path,
                        issue = "Incomplete YAML frontmatter",
                    })
                else
                    local frontmatter = content_after_opening:sub(1, frontmatter_end_rel - 1)

                    -- Check for required fields dynamically
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

    -- Find all tags in the line
    local start_pos = 1
    while true do
        local tag_start, tag_end = line:find(M.TAG_PATTERN, start_pos)
        if not tag_start then
            break
        end

        -- Check if cursor is within this tag
        if col_num >= tag_start - 1 and col_num < tag_end then
            return line:sub(tag_start, tag_end)
        end

        start_pos = tag_end + 1
    end

    return nil
end

--- Jumps to a tag file, creating it if necessary
--- @param tag_name string The tag name (with # prefix)
--- @return boolean Success
M.jump_to_tag_file = function(tag_name)
    if not M.wiki_root or not M.is_valid_tag(tag_name) then
        return false
    end

    -- Create the tag file if it doesn't exist
    if not M.create_tag_file(tag_name) then
        return false
    end

    local name = tag_name:gsub("^#", "")
    local tag_file_path = M.wiki_root .. "/sources/" .. name .. ".md"

    -- Open the file
    vim.cmd("edit " .. vim.fn.fnameescape(tag_file_path))

    return true
end

-- ============================================================================
-- MARKDOWN HYPERLINK SUPPORT
-- ============================================================================

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

    -- Find all links in the line
    local start_pos = 1
    while true do
        local match_start, match_end, link_text, link_path = line:find(M.LINK_PATTERN, start_pos)
        if not match_start then
            break
        end

        -- Check if cursor is within the entire link (from '[' to ')')
        -- Convert to 0-indexed for cursor comparison
        local link_start_0indexed = match_start - 1
        local link_end_0indexed = match_end

        -- Cursor is within the link if col_num >= link_start_0indexed and col_num < link_end_0indexed
        if col_num >= link_start_0indexed and col_num < link_end_0indexed then
            -- Determine if this is a URL
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
    if not M.wiki_root then
        return nil, "wiki_root not configured"
    end

    -- Check if it's an absolute path within wiki_root
    if path:sub(1, 1) == "/" then
        local absolute_path = M.wiki_root .. path

        -- Security: validate path is within wiki_root
        if not M.is_path_within_wiki_root(absolute_path) then
            return nil, "path escapes wiki_root"
        end

        return absolute_path, nil
    end

    -- Relative path: resolve from current file's directory
    if current_file then
        local current_dir = vim.fn.fnamemodify(current_file, ":h")
        local resolved = vim.fn.resolve(current_dir .. "/" .. path)

        -- Security: validate path is within wiki_root
        if not M.is_path_within_wiki_root(resolved) then
            return nil, "path escapes wiki_root"
        end

        return resolved, nil
    end

    -- No current file, resolve relative to wiki_root
    local resolved = M.wiki_root .. "/" .. path
    return vim.fn.resolve(resolved), nil
end

--- Jumps to the linked file or opens URL in browser
--- @return boolean Success
M.jump_to_link = function()
    if not M.wiki_root then
        return false
    end

    local link = M.get_link_under_cursor()
    if not link then
        return false
    end

    -- Handle external URLs
    if link.is_url then
        vim.ui.open(link.path)
        return true
    end

    -- Only support .md files for internal links
    if not link.path:match("%.md$") then
        vim.notify("davewiki: Only .md files are supported for internal links", vim.log.levels.WARN)
        return false
    end

    -- Get current buffer's file path for relative path resolution
    local current_file = vim.api.nvim_buf_get_name(0)

    -- Resolve the path
    local target_path, err = M.resolve_link_path(link.path, current_file)

    if err then
        vim.notify("davewiki: " .. err, vim.log.levels.ERROR)
        return false
    end

    -- Security check: path must be within wiki_root
    if not M.is_path_within_wiki_root(target_path) then
        vim.notify("davewiki: path escapes wiki_root", vim.log.levels.ERROR)
        return false
    end

    -- Check if file exists
    if vim.fn.filereadable(target_path) ~= 1 then
        vim.notify("davewiki: file not found: " .. target_path, vim.log.levels.WARN)
        return false
    end

    -- Open the file
    vim.cmd("edit " .. vim.fn.fnameescape(target_path))
    return true
end

return M
