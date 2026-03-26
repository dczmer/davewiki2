---
-- @module davewiki.journal
-- @brief Daily journal management for davewiki
-- @version 1.0

local M = {}

local core = require("davewiki.core")

---@class DavewikiJournalConfig
---@field enabled boolean Enable journal module

M.config = {
    enabled = true,
}

--- Setup the journal module
---@param config DavewikiJournalConfig?
---@return table
function M.setup(config)
    if config then
        M.config = vim.tbl_deep_extend("force", M.config, config)
    end
    return M
end

--- Check if journal module is enabled
---@return boolean
function M.is_enabled()
    return M.config.enabled
end

--- Format a date table to YYYY-MM-DD string
---@param date table Date table with year, month, day fields
---@return string Formatted date string
function M.format_date(date)
    return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

--- Validate a date string in YYYY-MM-DD format
---@param date_string string|nil The date string to validate
---@return boolean True if valid, false otherwise
function M.validate_date(date_string)
    if not date_string or type(date_string) ~= "string" then
        return false
    end

    local year, month, day = date_string:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if not year or not month or not day then
        return false
    end

    year, month, day = tonumber(year), tonumber(month), tonumber(day)

    if month < 1 or month > 12 then
        return false
    end

    if day < 1 or day > 31 then
        return false
    end

    local days_in_month = {
        31,
        28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    }

    local is_leap_year = (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
    if is_leap_year then
        days_in_month[2] = 29
    end

    if day > days_in_month[month] then
        return false
    end

    return true
end

--- Get the journals directory path
---@return string|nil The journals directory path, or nil if wiki_root not set
function M.get_journal_dir()
    if not core.wiki_root then
        return nil
    end
    return core.wiki_root .. "/journals"
end

--- Get the full path to a journal file
---@param date_string string The date in YYYY-MM-DD format
---@return string|nil The full path to the journal file, or nil if invalid
function M.get_journal_path(date_string)
    if not core.wiki_root then
        return nil
    end

    if not M.validate_date(date_string) then
        return nil
    end

    if date_string:match("[/\\]") then
        return nil
    end

    return core.wiki_root .. "/journals/" .. date_string .. ".md"
end

--- Create template content for a new journal entry
---@param date_string string The date in YYYY-MM-DD format
---@return table Array of lines for the template
function M.create_template(date_string)
    return {
        "---",
        "date: " .. date_string,
        "---",
        "",
        "# TASKS",
        "",
        "# AGENDA",
        "",
        "# NOTES",
    }
end

--- Open a journal file for a specific date
--- Creates the journals directory if it doesn't exist
--- Creates a new buffer with template if journal doesn't exist
---@param date_string string The date in YYYY-MM-DD format
---@return boolean True if successful, false otherwise
function M.open_journal(date_string)
    if not M.is_enabled() then
        return false
    end

    if not core.wiki_root then
        vim.notify("davewiki: wiki_root not configured", vim.log.levels.ERROR)
        return false
    end

    if not M.validate_date(date_string) then
        vim.notify("davewiki: invalid date format: " .. tostring(date_string), vim.log.levels.ERROR)
        return false
    end

    local journal_path = M.get_journal_path(date_string)
    if not journal_path then
        return false
    end

    local journals_dir = M.get_journal_dir()
    if not journals_dir then
        return false
    end

    if vim.fn.isdirectory(journals_dir) ~= 1 then
        vim.fn.mkdir(journals_dir, "p")
    end

    if vim.fn.filereadable(journal_path) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(journal_path))
        return true
    end

    local content = M.create_template(date_string)
    vim.cmd("edit " .. vim.fn.fnameescape(journal_path))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

    return true
end

--- Open today's journal
---@return boolean True if successful, false otherwise
function M.open_today()
    local today = os.date("*t")
    local date_string = M.format_date(today)
    return M.open_journal(date_string)
end

--- Open yesterday's journal
---@return boolean True if successful, false otherwise
function M.open_yesterday()
    local yesterday_time = os.time() - 86400
    local yesterday = os.date("*t", yesterday_time)
    local date_string = M.format_date(yesterday)
    return M.open_journal(date_string)
end

--- Open tomorrow's journal
---@return boolean True if successful, false otherwise
function M.open_tomorrow()
    local tomorrow_time = os.time() + 86400
    local tomorrow = os.date("*t", tomorrow_time)
    local date_string = M.format_date(tomorrow)
    return M.open_journal(date_string)
end

--- Prompt user for a date and open the corresponding journal
---@return boolean True if successful, false otherwise
function M.open_date()
    vim.ui.input({
        prompt = "Enter date (YYYY-MM-DD): ",
        default = os.date("%Y-%m-%d"),
    }, function(input)
        if not input then
            return
        end

        if not M.validate_date(input) then
            vim.notify("davewiki: invalid date format. Use YYYY-MM-DD", vim.log.levels.ERROR)
            return
        end

        M.open_journal(input)
    end)

    return true
end

--- Create user commands for journal operations
function M.create_user_commands()
    vim.api.nvim_create_user_command("DavewikiJournalToday", function()
        M.open_today()
    end, { desc = "Open today's journal" })

    vim.api.nvim_create_user_command("DavewikiJournalYesterday", function()
        M.open_yesterday()
    end, { desc = "Open yesterday's journal" })

    vim.api.nvim_create_user_command("DavewikiJournalTomorrow", function()
        M.open_tomorrow()
    end, { desc = "Open tomorrow's journal" })

    vim.api.nvim_create_user_command("DavewikiJournalOpen", function()
        M.open_date()
    end, { desc = "Open journal for a specific date" })
end

return M
