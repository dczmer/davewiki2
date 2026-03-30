---
-- @module davewiki.telescope
-- @brief Telescope integration for tag search and navigation
-- @version 1.0

local telescope = {}

local core = require("davewiki.core")
local markdown = require("davewiki.markdown")
local tags = require("davewiki.tags")

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

    local tag_files = tags.find_tag_files()

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
                    local tag_name = tags.extract_tag_from_filename(entry)
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
    local references = tags.get_tag_references(tag_name)

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

    local headings_list = markdown.get_headings_list()

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
    local markdown_files = markdown.get_markdown_files()

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
                    local title = markdown.extract_h1_or_filename(entry)
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
                        local link_text = core.make_markdown_link(selection.filename, selection.title)

                        if link_text then
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

    local tag_files = tags.find_tag_files()

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
                    local tag_name = tags.extract_tag_from_filename(entry)
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
            local tag_list = tags.scan_for_tags()
            local results = {}
            for _, data in ipairs(tag_list) do
                table.insert(results, data.tag)
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

    -- Command to open tag view picker
    vim.api.nvim_create_user_command("DavewikiGenerateView", function()
        telescope.tag_view()
    end, {
        desc = "Open picker to generate tag view",
    })

    -- Command to open journals picker
    vim.api.nvim_create_user_command("DavewikiJournals", function()
        telescope.jump_to_journal()
    end, {
        desc = "Open telescope picker for journal files",
    })
end

--- Get a list of all journal files under wiki_root/journals/
--- Returns files sorted alphabetically with relative paths for display
---@return table Array of journal file entries with file, display, and ordinal fields
function telescope.get_journals_list()
    if not core.wiki_root then
        return {}
    end

    local journals_dir = core.wiki_root .. "/journals"
    if vim.fn.isdirectory(journals_dir) ~= 1 then
        return {}
    end

    local args = {
        "--files",
        "--type",
        "md",
        journals_dir,
    }

    local lines = core.ripgrep(args)
    local journals = {}

    for _, line in ipairs(lines) do
        local resolved_path = vim.fn.resolve(line)

        if resolved_path:sub(1, #journals_dir) == journals_dir then
            table.insert(journals, {
                file = resolved_path,
                display = resolved_path,
                ordinal = resolved_path,
            })
        end
    end

    table.sort(journals, function(a, b)
        return a.display < b.display
    end)

    return journals
end

--- Get the journals directory path
---@return string|nil The journals directory path, or nil if wiki_root not set
function telescope.get_journal_dir()
    if not core.wiki_root then
        return nil
    end
    return core.wiki_root .. "/journals"
end

--- Open telescope picker to list all journal files
--- Allows fuzzy filtering and navigation to journal files with preview
---@return boolean True if picker opened successfully, false otherwise
function telescope.jump_to_journal()
    local journal = require("davewiki.journal")
    if not journal.config.enabled then
        return false
    end

    if not core.is_telescope_installed() then
        vim.notify("davewiki: telescope.nvim not installed", vim.log.levels.WARN)
        return false
    end

    if not core.wiki_root then
        vim.notify("davewiki: wiki_root is not configured", vim.log.levels.ERROR)
        return false
    end

    local journals_list = telescope.get_journals_list()

    if #journals_list == 0 then
        vim.notify("davewiki: No journal files found in wiki_root/journals/", vim.log.levels.INFO)
        return false
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values

    pickers
        .new({}, {
            prompt_title = "Journals",
            finder = finders.new_table({
                results = journals_list,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = entry.display,
                        ordinal = entry.ordinal,
                        filename = entry.file,
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

return telescope
