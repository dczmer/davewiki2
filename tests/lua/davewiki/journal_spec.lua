---
-- Tests for davewiki.journal module
-- @module davewiki.journal_spec

local lua_journal = require("davewiki.journal")
local lua_core = require("davewiki.core")

local test_root = "/home/dave/source/davewiki2/test_root"
local journals_dir = test_root .. "/journals"

local function cleanup_journals_dir()
    if vim.fn.isdirectory(journals_dir) == 1 then
        vim.fn.delete(journals_dir, "rf")
    end
end

local function setup_journals_dir()
    cleanup_journals_dir()
    vim.fn.mkdir(journals_dir, "p")
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

    describe("is_enabled", function()
        it("should return true when enabled", function()
            lua_journal.setup({ enabled = true })
            assert.is_true(lua_journal.is_enabled())
        end)

        it("should return false when disabled", function()
            lua_journal.setup({ enabled = false })
            assert.is_false(lua_journal.is_enabled())
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
        it("should create template with correct frontmatter and sections", function()
            local content = lua_journal.create_template("2026-03-25")
            assert.is_table(content)
            assert.are.equal("---", content[1])
            assert.are.equal("date: 2026-03-25", content[2])
            assert.are.equal("---", content[3])
            assert.are.equal("", content[4])
            assert.are.equal("# TASKS", content[5])
            assert.are.equal("", content[6])
            assert.are.equal("# AGENDA", content[7])
            assert.are.equal("", content[8])
            assert.are.equal("# NOTES", content[9])
        end)

        it("should handle different date values", function()
            local content = lua_journal.create_template("2025-01-01")
            assert.are.equal("date: 2025-01-01", content[2])
        end)
    end)
end)

describe("davewiki.journal open operations", function()
    before_each(function()
        lua_core.wiki_root = test_root
        lua_journal.setup({ enabled = true })
        cleanup_journals_dir()
        vim.cmd("enew")
    end)

    after_each(function()
        cleanup_journals_dir()
        vim.cmd("enew!")
    end)

    describe("open_journal", function()
        it("should return false when wiki_root is not configured", function()
            lua_core.wiki_root = nil
            local result = lua_journal.open_journal("2026-03-25")
            assert.is_false(result)
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
            assert.is_equal(0, vim.fn.isdirectory(journals_dir))
            lua_journal.open_journal("2026-03-25")
            assert.is_equal(1, vim.fn.isdirectory(journals_dir))
        end)

        it("should create buffer with template for new journal", function()
            lua_journal.open_journal("2026-03-25")
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            assert.are.equal("---", lines[1])
            assert.are.equal("date: 2026-03-25", lines[2])
            assert.are.equal("# TASKS", lines[5])
        end)

        it("should open existing journal without modification", function()
            setup_journals_dir()
            local existing_content = { "---", "date: 2025-12-25", "---", "", "Existing content" }
            vim.fn.writefile(existing_content, journals_dir .. "/2025-12-25.md")

            lua_journal.open_journal("2025-12-25")
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            assert.are.equal("Existing content", lines[5])
        end)

        it("should create buffer at correct path", function()
            lua_journal.open_journal("2026-03-25")
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/2026-03-25.md", bufname)
        end)
    end)

    describe("open_today", function()
        it("should open journal for today's date", function()
            cleanup_journals_dir()
            local result = lua_journal.open_today()
            assert.is_true(result)

            local today = os.date("%Y-%m-%d")
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/" .. today .. ".md", bufname)
        end)
    end)

    describe("open_yesterday", function()
        it("should open journal for yesterday's date", function()
            cleanup_journals_dir()
            local result = lua_journal.open_yesterday()
            assert.is_true(result)

            local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/" .. yesterday .. ".md", bufname)
        end)
    end)

    describe("open_tomorrow", function()
        it("should open journal for tomorrow's date", function()
            cleanup_journals_dir()
            local result = lua_journal.open_tomorrow()
            assert.is_true(result)

            local tomorrow = os.date("%Y-%m-%d", os.time() + 86400)
            local bufname = vim.api.nvim_buf_get_name(0)
            assert.are.equal(journals_dir .. "/" .. tomorrow .. ".md", bufname)
        end)
    end)
end)

describe("davewiki.journal user commands", function()
    before_each(function()
        lua_core.wiki_root = test_root
        lua_journal.setup({ enabled = true })
        cleanup_journals_dir()
    end)

    after_each(function()
        cleanup_journals_dir()
    end)

    describe("create_user_commands", function()
        it("should create DavewikiJournalToday command", function()
            lua_journal.create_user_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalToday)
        end)

        it("should create DavewikiJournalYesterday command", function()
            lua_journal.create_user_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalYesterday)
        end)

        it("should create DavewikiJournalTomorrow command", function()
            lua_journal.create_user_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalTomorrow)
        end)

        it("should create DavewikiJournalOpen command", function()
            lua_journal.create_user_commands()
            local commands = vim.api.nvim_get_commands({ builtin = false })
            assert.is_not_nil(commands.DavewikiJournalOpen)
        end)
    end)
end)
