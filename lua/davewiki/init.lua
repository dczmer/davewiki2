---
-- @module davewiki
-- @brief Public interface for davewiki plugin
-- @version 1.0

local M = {}

---@class DavewikiConfig
---@field wiki_root string Root directory for all notes (required)
---@field telescope DavewikiTelescopeConfig Telescope integration config
---@field cmp DavewikiCmpConfig nvim-cmp integration config
---@field journal DavewikiJournalConfig Journal module config
---@field show_tag_backlinks boolean Enable automatic backlink display in quickfix (default: true)

---@class DavewikiTelescopeConfig
---@field enabled boolean Enable telescope integration (default: true)

---@class DavewikiCmpConfig
---@field enabled boolean Enable nvim-cmp integration (default: true)

---@class DavewikiJournalConfig
---@field enabled boolean Enable journal module (default: true)

local default_config = {
    telescope = {
        enabled = true,
    },
    cmp = {
        enabled = true,
    },
    journal = {
        enabled = true,
    },
    show_tag_backlinks = true,
}

---@type DavewikiConfig
local config = vim.deepcopy(default_config)

local core = require("davewiki.core")

--- Setup the davewiki plugin with the given configuration
---@param user_config DavewikiConfig?
---@return table
function M.setup(user_config)
    if user_config then
        config = vim.tbl_deep_extend("force", config, user_config)
    end

    core.setup({ wiki_root = config.wiki_root })
    config.wiki_root = core.wiki_root

    -- Define custom highlight group for tag names
    vim.api.nvim_set_hl(0, "DavewikiTag", {
        fg = "#FF8C00", -- Bright orange foreground
        bg = "#2A2A2A", -- Dark charcoal background
        underline = true,
    })

    -- Set up syntax matching for tags in markdown files under wiki_root
    local augroup = vim.api.nvim_create_augroup("DaveWikiTagHighlight", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,
        pattern = config.wiki_root .. "/*.md," .. config.wiki_root .. "/**/*.md",
        desc = "Apply tag highlighting to markdown files in wiki",
        callback = function()
            -- Match tag pattern: #[A-Za-z0-9-_]+
            vim.fn.matchadd("DavewikiTag", core.TAG_PATTERN:gsub("+", "\\+") .. "\\>")
        end,
    })

    if config.cmp.enabled then
        M.cmp = require("davewiki.cmp")
        M.cmp.setup({ enabled = true })
        M.cmp.register_tag_names()
    end

    if config.telescope.enabled then
        M.telescope = require("davewiki.telescope")
        M.telescope.setup({ enabled = true })
    end

    if config.show_tag_backlinks then
        M.setup_backlinks_autocmd()
    end

    if config.journal.enabled then
        M.journal = require("davewiki.journal")
        M.journal.setup({ enabled = true })
        M.journal.create_user_commands()

        -- Create journal telescope command only if telescope is also enabled
        if config.telescope.enabled then
            vim.api.nvim_create_user_command("DavewikiJournals", function()
                M.journal.jump_to_journal()
            end, { desc = "Open telescope picker for journal files" })
        end
    end

    return M
end

--- Jump to the tag file under the cursor
--- Creates the tag file if it doesn't exist
---
--- @return boolean True if jump was successful, false otherwise
function M.jump_to_tag()
    local tag = core.get_tag_under_cursor()
    if tag then
        return core.jump_to_tag_file(tag)
    end
    return false
end

--- Jump to the hyperlink under the cursor
--- Opens the linked file or URL. For internal links, resolves relative to
--- the current file or wiki_root (for absolute paths). For external URLs,
--- opens in the system default browser.
---
--- @return boolean True if jump was successful, false otherwise
function M.jump_to_link()
    return core.jump_to_link()
end

--- Get the current configuration
---@return DavewikiConfig
function M.get_config()
    return config
end

--- Sets up autocommands for tag file backlink display
--- When a tag file is opened, automatically searches for backlinks and
--- populates the quickfix list. Quickfix closes when leaving the tag file.
function M.setup_backlinks_autocmd()
    local augroup = vim.api.nvim_create_augroup("DaveWikiBacklinks", { clear = true })

    -- Autocommand for when entering a tag file buffer
    vim.api.nvim_create_autocmd("BufReadPost", {
        group = augroup,
        pattern = config.wiki_root .. "/sources/*.md",
        desc = "Show backlinks when entering a tag file",
        callback = function(args)
            local file_path = vim.api.nvim_buf_get_name(args.buf)

            -- Extract tag name from filename
            local tag_name = core.extract_tag_from_filename(file_path)
            if not tag_name then
                return
            end

            -- Find all backlinks
            local backlinks = core.find_backlinks("#" .. tag_name)

            -- If no backlinks found, do nothing (silent behavior)
            if #backlinks == 0 then
                return
            end

            -- Format backlinks for quickfix
            local qf_list = {}
            for _, backlink in ipairs(backlinks) do
                table.insert(qf_list, {
                    filename = backlink.file,
                    lnum = backlink.lnum,
                    col = backlink.col,
                    text = backlink.line,
                })
            end

            -- Set quickfix list and open it
            vim.fn.setqflist(qf_list, "r")
            vim.cmd("copen")
        end,
    })

    -- Autocommand for when leaving a tag file buffer
    vim.api.nvim_create_autocmd("BufLeave", {
        group = augroup,
        pattern = config.wiki_root .. "/sources/*.md",
        desc = "Close quickfix when leaving a tag file",
        callback = function(args)
            local file_path = vim.api.nvim_buf_get_name(args.buf)

            -- Check if this is a tag file
            if not core.is_tag_file(file_path) then
                return
            end

            -- Close quickfix window
            vim.cmd("cclose")
        end,
    })
end

return M
