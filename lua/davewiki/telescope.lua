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

--- Check if telescope.nvim is installed
---@return boolean
local function is_telescope_installed()
    local ok, _ = pcall(require, "telescope")
    return ok
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
    if not is_telescope_installed() then
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
    if not is_telescope_installed() then
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
end

return telescope
