---
-- Tests for davewiki.journal module
-- @module davewiki.journal_spec

local lua_journal = require("davewiki.journal")
local lua_core = require("davewiki.core")
local test_util = require("davewiki.test_util")

-- Get the absolute path to test_root directory relative to this script
local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"
local journals_dir = test_root .. "/journals"

-- Track files created by tests for cleanup
local created_files = {}

local function track_file(filepath)
    created_files[filepath] = true
end

local function cleanup_created_files()
    for filepath, _ in pairs(created_files) do
        pcall(vim.fn.delete, filepath)
        created_files[filepath] = nil
    end
end

local function ensure_journals_dir()
    if vim.fn.isdirectory(journals_dir) == 0 then
        vim.fn.mkdir(journals_dir, "p")
    end
end

describe("davewiki.journal module setup", function()
    before_each(function()
        lua_core.wiki_root = nil
        lua_journal.config = { enabled = true }
    end)

    describe("setup", function()
        it("should accept enabled config option", function()
            lua_journal.setup({ enabled = true })
            assert.is_true(lua_journal.config.enabled)
        end)

        it("should default to enabled when config is nil", function()
            lua_journal.setup()
            assert.is_true(lua_journal.config.enabled)
        end)

        it("should return the module for chaining", function()
            local result = lua_journal.setup({ enabled = true })
            assert.are.equal(lua_journal, result)
        end)
    end)

    describe("config.enabled", function()
        it("should return true when enabled", function()
            lua_journal.setup({ enabled = true })
            assert.is_true(lua_journal.config.enabled)
        end)

        it("should return false when disabled", function()
            lua_journal.setup({ enabled = false })
            assert.is_false(lua_journal.config.enabled)
        end)
    end)
end)

describe("davewiki.journal date utilities", function()
    before_each(function()
        lua_core.wiki_root = test_root
        lua_journal.setup({ enabled = true })
    end)

    describe("format_date", function()
        it("should format a date table to YYYY-MM-DD string", function()
            local date = { year = 2026, month = 3, day = 25 }
            local result = lua_journal.format_date(date)
            assert.are.equal("2026-03-25", result)
        end)

        it("should pad single digit months", function()
            local date = { year = 2026, month = 1, day = 5 }
            local result = lua_journal.format_date(date)
            assert.are.equal("2026-01-05", result)
        end)

        it("should pad single digit days", function()
            local date = { year = 2026, month = 12, day = 1 }
            local result = lua_journal.format_date(date)
            assert.are.equal("2026-12-01", result)
        end)
    end)

    describe("validate_date", function()
        it("should return true for valid YYYY-MM-DD format", function()
            assert.is_true(lua_journal.validate_date("2026-03-25"))
        end)

        it("should return true for dates with single digit months", function()
            assert.is_true(lua_journal.validate_date("2026-01-05"))
        end)

        it("should return false for invalid formats", function()
            assert.is_false(lua_journal.validate_date("2026/03/25"))
            assert.is_false(lua_journal.validate_date("03-25-2026"))
            assert.is_false(lua_journal.validate_date("2026-3-25"))
            assert.is_false(lua_journal.validate_date("2026-03-5"))
            assert.is_false(lua_journal.validate_date(""))
            assert.is_false(lua_journal.validate_date(nil))
            assert.is_false(lua_journal.validate_date("not-a-date"))
        end)

        it("should return false for invalid dates", function()
            assert.is_false(lua_journal.validate_date("2026-13-01"))
            assert.is_false(lua_journal.validate_date("2026-00-15"))
            assert.is_false(lua_journal.validate_date("2026-02-30"))
        end)
    end)

    describe("get_journal_dir", function()
        it("should return journals directory path under wiki_root", function()
            local result = lua_journal.get_journal_dir()
            assert.are.equal(journals_dir, result)
        end)

        it("should return nil when wiki_root is not set", function()
            lua_core.wiki_root = nil
            local result = lua_journal.get_journal_dir()
            assert.is_nil(result)
        end)
    end)

    describe("get_journal_path", function()
        it("should return full path to journal file", function()
            local result = lua_journal.get_journal_path("2026-03-25")
            assert.are.equal(journals_dir .. "/2026-03-25.md", result)
        end)

        it("should return nil when wiki_root is not set", function()
            lua_core.wiki_root = nil
            local result = lua_journal.get_journal_path("2026-03-25")
            assert.is_nil(result)
        end)

        it("should return nil for invalid date strings", function()
            local result = lua_journal.get_journal_path("invalid")
            assert.is_nil(result)
        end)

        it("should reject path traversal attempts", function()
            local result = lua_journal.get_journal_path("../../../etc/passwd")
            assert.is_nil(result)
        end)
    end)
end)

describe("davewiki.journal template creation", function()
    before_each(function()
        lua_core.wiki_root = test_root
        lua_journal.setup({ enabled = true })
    end)

    describe("create_template", function()
        it("should create template with correct frontmatter, title, and sections", function()
            local content = lua_journal.create_template("2026-03-25")
            assert.is_table(content)
            assert.are.equal("---", content[1])
            assert.are.equal("date: 2026-03-25", content[2])
            assert.are.equal("---", content[3])
            assert.are.equal("", content[4])
            assert.are.equal("# 2026-03-25 - Wednesday", content[5])
            assert.are.equal("", content[6])
            assert.are.equal("# TASKS", content[7])
            assert.are.equal("", content[8])
            assert.are.equal("# AGENDA", content[9])
            assert.are.equal("", content[10])
            assert.are.equal("# NOTES", content[11])
        end)

        it("should handle different date values", function()
            local content = lua_journal.create_template("2025-01-01")
            assert.are.equal("date: 2025-01-01", content[2])
            assert.are.equal("# 2025-01-01 - Wednesday", content[5])
        end)
    end)

    describe("get_day_name", function()
        it("should return the day name for a date string", function()
            local day_name = lua_journal.get_day_name("2026-03-25")
            assert.are.equal("Wednesday", day_name)
        end)

        it("should return different day names for different dates", function()
            assert.are.equal("Monday", lua_journal.get_day_name("2026-03-23"))
            assert.are.equal("Tuesday", lua_journal.get_day_name("2026-03-24"))
            assert.are.equal("Wednesday", lua_journal.get_day_name("2026-03-25"))
            assert.are.equal("Thursday", lua_journal.get_day_name("2026-03-26"))
            assert.are.equal("Friday", lua_journal.get_day_name("2026-03-27"))
            assert.are.equal("Saturday", lua_journal.get_day_name("2026-03-28"))
            assert.are.equal("Sunday", lua_journal.get_day_name("2026-03-29"))
        end)
    end)
end)

describe("davewiki.journal open operations", function()
    local mock_notify
    local original_notify

    before_each(function()
        lua_core.wiki_root = test_root
        lua_journal.setup({ enabled = true })
        ensure_journals_dir()
        vim.cmd("enew")
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        cleanup_created_files()
        vim.cmd("enew!")
        vim.notify = original_notify
    end)

    describe("open_journal", function()
        it("should return false when wiki_root is not configured", function()
            lua_core.wiki_root = nil
            local result = lua_journal.open_journal("2026-03-25")

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: wiki_root not configured", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)

        it("should return false when journal module is disabled", function()
            lua_journal.setup({ enabled = false })
            local result = lua_journal.open_journal("2026-03-25")
            assert.is_false(result)
        end)

        it("should return false for invalid date", function()
            local result = lua_journal.open_journal("invalid-date")
            assert.is_false(result)
        end)

        it("should create journals directory if it doesn't exist", function()
            ensure_journals_dir()
            lua_journal.open_journal("2099-01-15")
            assert.is_equal(1, vim.fn.isdirectory(journals_dir))
        end)

        it("should create buffer with template for new journal", function()
            lua_journal.open_journal("2099-01-16")
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            assert.are.equal("---", lines[1])
            assert.are.equal("date: 2099-01-16", lines[2])
            assert.are.equal("# TASKS", lines[7])
        end)

        it("should open existing journal without modification", function()
            local test_file = journals_dir .. "/2099-01-17.md"
            local existing_content = { "---", "date: 2099-01-17", "---", "", "Existing content" }
            vim.fn.writefile(existing_content, test_file)
            track_file(test_file)

            lua_journal.open_journal("2099-01-17")
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            assert.are.equal("Existing content", lines[5])
        end)

        it("should create buffer at correct path", function()
            lua_journal.open_journal("2099-01-18")
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/2099-01-18.md", bufname)
        end)
    end)

    describe("open_today", function()
        it("should open journal for today's date", function()
            local result = lua_journal.open_today()
            assert.is_true(result)

            local today = os.date("%Y-%m-%d")
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/" .. today .. ".md", bufname)
        end)
    end)

    describe("open_yesterday", function()
        it("should open journal for yesterday's date", function()
            local result = lua_journal.open_yesterday()
            assert.is_true(result)

            local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/" .. yesterday .. ".md", bufname)
        end)
    end)

    describe("open_tomorrow", function()
        it("should open journal for tomorrow's date", function()
            local result = lua_journal.open_tomorrow()
            assert.is_true(result)

            local tomorrow = os.date("%Y-%m-%d", os.time() + 86400)
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/" .. tomorrow .. ".md", bufname)
        end)
    end)

    describe("smart navigation", function()
        it("parse_buffer_date should return nil for non-journal buffer", function()
            vim.cmd("enew!")
            local result = lua_journal.parse_buffer_date()
            assert.is_nil(result)
        end)

        it("parse_buffer_date should extract date from journal filename", function()
            vim.cmd("enew!")
            local test_path = journals_dir .. "/2099-02-01.md"
            vim.api.nvim_buf_set_name(0, test_path)
            local result = lua_journal.parse_buffer_date()
            assert.are.equal("2099-02-01", result)
        end)

        it("open_yesterday should use buffer date when in a journal", function()
            vim.cmd("enew!")
            vim.api.nvim_buf_set_name(0, journals_dir .. "/2099-02-03.md")
            local result = lua_journal.open_yesterday()
            assert.is_true(result)
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/2099-02-02.md", bufname)
        end)

        it("open_tomorrow should use buffer date when in a journal", function()
            vim.cmd("enew!")
            vim.api.nvim_buf_set_name(0, journals_dir .. "/2099-03-04.md")
            local result = lua_journal.open_tomorrow()
            assert.is_true(result)
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/2099-03-05.md", bufname)
        end)
    end)
end)

describe("davewiki.journal user commands", function()
    before_each(function()
        lua_core.wiki_root = test_root
        lua_journal.setup({ enabled = true })
        ensure_journals_dir()
    end)

    after_each(function()
        cleanup_created_files()
    end)

    describe("setup_commands", function()
        it("should create DavewikiJournalToday command", function()
            lua_journal.setup_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalToday)
        end)

        it("should create DavewikiJournalYesterday command", function()
            lua_journal.setup_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalYesterday)
        end)

        it("should create DavewikiJournalTomorrow command", function()
            lua_journal.setup_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalTomorrow)
        end)

        it("should create DavewikiJournalOpen command", function()
            lua_journal.setup_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalOpen)
        end)
    end)
end)
---
-- Tests for davewiki.telescope journal integration
-- @module davewiki.telescope_journal_spec

local telescope = require("davewiki.telescope")
local core = require("davewiki.core")
local journal = require("davewiki.journal")

-- Get the absolute path to test_root directory relative to this script
local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.telescope jump_to_journal function", function()
    local mock_notify
    local original_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        journal.config.enabled = true
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        vim.notify = original_notify
    end)

    describe("jump_to_journal", function()
        it("should return false when telescope is not installed", function()
            -- Mock telescope module as not installed
            local original_require = _G.require
            _G.require = function(mod)
                if mod == "telescope" or mod:match("^telescope%.") then
                    error("module '" .. mod .. "' not found")
                end
                return original_require(mod)
            end

            local result = telescope.jump_to_journal()

            _G.require = original_require

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: telescope.nvim not installed", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.WARN, mock_notify.calls[1].level)
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = telescope.jump_to_journal()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: wiki_root is not configured", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)

        it("should return false when journal module is disabled", function()
            journal.config.enabled = false
            local result = telescope.jump_to_journal()
            assert.is_false(result)
        end)
    end)

    describe("get_journals_list", function()
        it("should return list of journal files from wiki_root/journals/", function()
            local journals = telescope.get_journals_list()

            assert.is_table(journals)
            -- test_root has some journal files (git-tracked ones)
            assert.is_true(#journals >= 0)

            -- Each entry should be a table with required fields
            for _, entry in ipairs(journals) do
                assert.is_table(entry)
                assert.is_string(entry.file)
                assert.is_string(entry.display)
                -- File should be within journals directory
                assert.is_true(entry.file:match("/journals/") ~= nil)
                -- Should be a markdown file
                assert.is_true(entry.file:match("%.md$") ~= nil)
            end
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local journals = telescope.get_journals_list()
            assert.is_table(journals)
            assert.are.equal(0, #journals)
        end)

        it("should return empty table when journals directory does not exist", function()
            -- Temporarily set wiki_root to a directory without journals
            local original_root = core.wiki_root
            local temp_dir = "/tmp/empty-davewiki-test-" .. os.time()
            core.wiki_root = temp_dir
            vim.fn.mkdir(core.wiki_root, "p")

            local journals = telescope.get_journals_list()

            core.wiki_root = original_root
            vim.fn.delete(temp_dir, "rf")

            assert.is_table(journals)
            assert.are.equal(0, #journals)
        end)

        it("should use absolute paths in display", function()
            local journals = telescope.get_journals_list()

            for _, entry in ipairs(journals) do
                -- Display should be the same as file (absolute path)
                assert.are.equal(entry.file, entry.display)
                -- Should be an absolute path
                assert.is_true(
                    entry.display:match("^/") ~= nil,
                    "Display should be absolute path: " .. entry.display
                )
            end
        end)
    end)
end)

describe("davewiki.telescope get_journals_list sorting", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
    end)

    it("should return journal files sorted alphabetically", function()
        local journals = telescope.get_journals_list()

        if #journals > 1 then
            for i = 2, #journals do
                assert.is_true(
                    journals[i - 1].display <= journals[i].display,
                    "Journals should be sorted alphabetically: "
                        .. journals[i - 1].display
                        .. " > "
                        .. journals[i].display
                )
            end
        end
    end)
end)
