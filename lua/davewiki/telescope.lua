---
-- @module davewiki.telescope
-- @brief Telescope integration for tag search and navigation
-- @version 1.0

local telescope = {}

local core = require("davewiki.core")

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

    -- Register user commands
    telescope.setup_commands()
end

--- Check if telescope integration is enabled
---@return boolean
function telescope.is_enabled()
    return telescope.config.enabled
end

--- Generate an absolute path from wiki_root for a target file
--- Returns path starting with "/" that is relative to wiki_root
---
--- @param target_file string The absolute path to the target file
--- @return string|nil The absolute path from wiki_root (e.g., "/notes/file.md"), or nil if outside wiki_root
function telescope.generate_absolute_path(target_file)
    if not core.wiki_root or not target_file then
        return nil
    end

    -- Resolve paths to handle any symlinks
    local resolved_wiki_root = vim.fn.resolve(core.wiki_root)
    local resolved_target = vim.fn.resolve(target_file)

    -- Security check: ensure target is within wiki_root
    if not core.is_path_within_wiki_root(resolved_target) then
        return nil
    end

    -- Get the relative path from wiki_root
    local relative_path = resolved_target:sub(#resolved_wiki_root + 1)

    -- Ensure the path starts with "/"
    if relative_path:sub(1, 1) ~= "/" then
        relative_path = "/" .. relative_path
    end

    -- URL-encode the path for use in markdown links
    return core.url_encode(relative_path)
end

--- Get a sorted list of unique tags from the wiki
--- Uses core.scan_for_tags() to find all tags across wiki_root
---@return table Array of tag names (with # prefix), sorted alphabetically
function telescope.get_tags_list()
    if not core.wiki_root then
        return {}
    end

    local tag_data = core.scan_for_tags()
    local tags = {}

    for _, data in ipairs(tag_data) do
        table.insert(tags, data.tag)
    end

    -- Sort alphabetically
    table.sort(tags)

    return tags
end

--- Get all references for a tag or all tag references in the wiki
--- When tag_name is provided, returns references to that specific tag
--- When tag_name is nil, returns all references to any tag
---@param tag_name string? The tag name to search for (with # prefix), optional
---@return table Array of reference objects with file, lnum, col, line, tag fields
function telescope.get_all_references(tag_name)
    if not core.wiki_root then
        return {}
    end

    -- If specific tag provided, use find_backlinks
    if tag_name then
        if not core.is_valid_tag(tag_name) then
            return {}
        end
        return core.find_backlinks(tag_name)
    end

    -- Otherwise, find all tag references using ripgrep
    local args = {
        "--line-number",
        "--column",
        "--only-matching",
        core.TAG_PATTERN,
        core.wiki_root,
    }

    local lines = core.ripgrep(args)
    local references = {}
    local seen = {}

    for _, line in ipairs(lines) do
        -- Parse: file:line:col:tag
        local file_path, line_num, col_num, tag = line:match("^(.-):(%d+):(%d+):(#.+)$")
        if file_path and line_num and col_num then
            -- Skip tag files
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

--- Open telescope picker to list all tags
--- Allows fuzzy filtering and navigation to tag files
---@return boolean True if picker opened successfully, false otherwise
function telescope.tags()
    if not core.is_telescope_installed() then
        vim.notify("davewiki: telescope.nvim not installed", vim.log.levels.WARN)
        return false
    end

    if not core.wiki_root then
        vim.notify("davewiki: wiki_root is not configured", vim.log.levels.ERROR)
        return false
    end

    local tag_files = core.find_tag_files()

    if #tag_files == 0 then
        vim.notify("davewiki: No tags found in wiki_root", vim.log.levels.INFO)
        return false
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    pickers
        .new({}, {
            prompt_title = "Tags",
            finder = finders.new_table({
                results = tag_files,
                entry_maker = function(entry)
                    local tag_name = core.extract_tag_from_filename(entry)
                    return {
                        value = entry,
                        display = tag_name or entry,
                        ordinal = tag_name or entry,
                        filename = entry,
                    }
                end,
            }),
            sorter = conf.file_sorter({}),
            previewer = conf.grep_previewer({}),
            attach_mappings = function(_, map)
                map("i", "<CR>", function(bufnr)
                    local selection = require("telescope.actions.state").get_selected_entry()
                    require("telescope.actions").close(bufnr)
                    if selection then
                        vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
                    end
                end)
                return true
            end,
        })
        :find()

    return true
end

--- Open telescope picker to search for tag references
--- If tag_name is provided, shows references to that tag
--- If no tag_name provided, shows all references to any tag in the wiki
---@param tag_name string? The tag name to search for (with # prefix), optional
---@return boolean True if picker opened successfully, false otherwise
function telescope.tag_references(tag_name)
    if not core.is_telescope_installed() then
        vim.notify("davewiki: telescope.nvim not installed", vim.log.levels.WARN)
        return false
    end

    if not core.wiki_root then
        vim.notify("davewiki: wiki_root is not configured", vim.log.levels.ERROR)
        return false
    end

    -- If tag_name provided, validate it
    if tag_name and not core.is_valid_tag(tag_name) then
        vim.notify("davewiki: Invalid tag name: " .. tag_name, vim.log.levels.ERROR)
        return false
    end

    -- Get references (either for specific tag or all tags)
    local references = telescope.get_all_references(tag_name)

    if #references == 0 then
        if tag_name then
            vim.notify("davewiki: No references to " .. tag_name .. " found", vim.log.levels.INFO)
        else
            vim.notify("davewiki: No tag references found in wiki_root", vim.log.levels.INFO)
        end
        return false
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    local prompt_title = tag_name and ("References to " .. tag_name) or "All Tag References"

    pickers
        .new({}, {
            prompt_title = prompt_title,
            finder = finders.new_table({
                results = references,
                entry_maker = function(entry)
                    local display = entry.file .. ":" .. entry.lnum .. ":" .. entry.tag
                    return {
                        value = entry,
                        display = display,
                        ordinal = entry.file .. ":" .. entry.lnum .. " " .. entry.tag,
                        filename = entry.file,
                        lnum = entry.lnum,
                        col = entry.col,
                    }
                end,
            }),
            sorter = conf.file_sorter({}),
            previewer = conf.grep_previewer({}),
            attach_mappings = function(_, map)
                map("i", "<CR>", function(bufnr)
                    local selection = require("telescope.actions.state").get_selected_entry()
                    require("telescope.actions").close(bufnr)
                    if selection then
                        vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
                        vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col - 1 })
                    end
                end)
                return true
            end,
        })
        :find()

    return true
end

--- Get a sorted list of all level-1 headings from the wiki
--- Uses ripgrep to find lines starting with "# " (but not "##")
---@return table Array of heading objects with text, file, and lnum fields
function telescope.get_headings_list()
    if not core.wiki_root then
        return {}
    end

    -- Pattern for level-1 headings: lines starting with "# " followed by non-space text
    -- ripgrep will output: file:line:column:content
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
        -- Parse ripgrep output: file:line:column:content
        local file_path, line_num, _, content = line:match("^(.-):(%d+):(%d+):(.*)$")

        if file_path and line_num and content then
            table.insert(headings, {
                text = content,
                file = file_path,
                lnum = tonumber(line_num),
            })
        end
    end

    -- Sort alphabetically by heading text
    table.sort(headings, function(a, b)
        return a.text < b.text
    end)

    return headings
end

--- Open telescope picker to list all level-1 headings
--- Allows fuzzy filtering and navigation to headings
---@return boolean True if picker opened successfully, false otherwise
function telescope.headings()
    if not core.is_telescope_installed() then
        vim.notify("davewiki: telescope.nvim not installed", vim.log.levels.WARN)
        return false
    end

    if not core.wiki_root then
        vim.notify("davewiki: wiki_root is not configured", vim.log.levels.ERROR)
        return false
    end

    local headings_list = telescope.get_headings_list()

    if #headings_list == 0 then
        -- Silent behavior when no headings found (per spec)
        return false
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    pickers
        .new({}, {
            prompt_title = "Headings",
            finder = finders.new_table({
                results = headings_list,
                entry_maker = function(entry)
                    -- Get filename for display
                    local filename = vim.fn.fnamemodify(entry.file, ":t")
                    local display = entry.text .. " (" .. filename .. ")"
                    return {
                        value = entry,
                        display = display,
                        ordinal = entry.text,
                        filename = entry.file,
                        lnum = entry.lnum,
                    }
                end,
            }),
            sorter = conf.file_sorter({}),
            previewer = conf.grep_previewer({}),
            attach_mappings = function(_, map)
                map("i", "<CR>", function(bufnr)
                    local selection = require("telescope.actions.state").get_selected_entry()
                    require("telescope.actions").close(bufnr)
                    if selection then
                        vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
                        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
                    end
                end)
                return true
            end,
        })
        :find()

    return true
end

--- Open telescope picker to insert a markdown link
--- Shows all non-tag markdown files and inserts a link at cursor position
---@return boolean True if picker opened successfully, false otherwise
function telescope.insert_link()
    if not core.is_telescope_installed() then
        vim.notify("davewiki: telescope.nvim not installed", vim.log.levels.WARN)
        return false
    end

    if not core.wiki_root then
        vim.notify("davewiki: wiki_root is not configured", vim.log.levels.ERROR)
        return false
    end

    -- Get current file path for relative path calculation
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == "" then
        vim.notify("davewiki: No file open in current buffer", vim.log.levels.ERROR)
        return false
    end

    -- Validate current file is within wiki_root
    if not core.is_path_within_wiki_root(current_file) then
        vim.notify("davewiki: Current file is not within wiki_root", vim.log.levels.ERROR)
        return false
    end

    -- Get all markdown files
    local markdown_files = core.get_markdown_files()

    if #markdown_files == 0 then
        vim.notify("davewiki: No markdown files found in wiki_root", vim.log.levels.INFO)
        return false
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    pickers
        .new({}, {
            prompt_title = "Insert Link",
            finder = finders.new_table({
                results = markdown_files,
                entry_maker = function(entry)
                    -- Extract title from file
                    local title = core.extract_h1_or_filename(entry)
                    local filename = vim.fn.fnamemodify(entry, ":t")
                    local display = title .. " (" .. filename .. ")"
                    return {
                        value = entry,
                        display = display,
                        ordinal = title .. " " .. filename,
                        filename = entry,
                        title = title,
                    }
                end,
            }),
            sorter = conf.file_sorter({}),
            previewer = conf.grep_previewer({}),
            attach_mappings = function(_, map)
                map("i", "<CR>", function(bufnr)
                    local selection = require("telescope.actions.state").get_selected_entry()
                    require("telescope.actions").close(bufnr)

                    if selection then
                        -- Generate absolute path from wiki_root
                        local absolute_path = telescope.generate_absolute_path(selection.filename)

                        if absolute_path then
                            -- Build the markdown link
                            local link_text = "[" .. selection.title .. "](" .. absolute_path .. ")"

                            -- Insert at cursor position
                            vim.api.nvim_put({ link_text }, "c", true, true)
                        end
                    end
                end)
                return true
            end,
        })
        :find()

    return true
end

--- Open telescope picker to select a tag and generate view
--- @return boolean True if picker opened successfully, false otherwise
function telescope.tag_view()
    if not core.is_telescope_installed() then
        vim.notify("davewiki: telescope.nvim not installed", vim.log.levels.WARN)
        return false
    end

    if not core.wiki_root then
        vim.notify("davewiki: wiki_root is not configured", vim.log.levels.ERROR)
        return false
    end

    local tag_files = core.find_tag_files()

    if #tag_files == 0 then
        vim.notify("davewiki: No tags found in wiki_root", vim.log.levels.INFO)
        return false
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local view = require("davewiki.view")

    pickers
        .new({}, {
            prompt_title = "Generate Tag View",
            finder = finders.new_table({
                results = tag_files,
                entry_maker = function(entry)
                    local tag_name = core.extract_tag_from_filename(entry)
                    return {
                        value = entry,
                        display = tag_name or entry,
                        ordinal = tag_name or entry,
                        filename = entry,
                    }
                end,
            }),
            sorter = conf.file_sorter({}),
            previewer = conf.grep_previewer({}),
            attach_mappings = function(_, map)
                map("i", "<CR>", function(bufnr)
                    local selection = require("telescope.actions.state").get_selected_entry()
                    require("telescope.actions").close(bufnr)
                    if selection then
                        local tag_name = "#" .. selection.display
                        view.generate_view(tag_name)
                    end
                end)
                return true
            end,
        })
        :find()

    return true
end

--- Set up user commands for telescope integration
function telescope.setup_commands()
    -- Command to open tags picker
    vim.api.nvim_create_user_command("DavewikiTags", function()
        telescope.tags()
    end, {
        desc = "Open davewiki tags picker",
    })

    -- Command to open tag references picker
    vim.api.nvim_create_user_command("DavewikiTagReferences", function(opts)
        local tag_name = opts.args
        if tag_name == "" then
            tag_name = nil
        end
        telescope.tag_references(tag_name)
    end, {
        nargs = "?",
        desc = "Open davewiki tag references picker",
        complete = function(_, cmdline, _)
            -- Provide basic tag completion if possible
            local tags = core.scan_for_tags()
            local results = {}
            for _, tag_data in ipairs(tags) do
                table.insert(results, tag_data.tag)
            end
            return results
        end,
    })

    -- Command to open headings picker
    vim.api.nvim_create_user_command("DavewikiHeadings", function()
        telescope.headings()
    end, {
        desc = "Open davewiki headings picker",
    })

    -- Command to open insert link picker
    vim.api.nvim_create_user_command("DavewikiInsertLink", function()
        telescope.insert_link()
    end, {
        desc = "Insert a markdown link to another wiki file",
    })
end

return telescope
