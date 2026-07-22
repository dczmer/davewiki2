---
-- Tests for davewiki.core utility functions
-- @module davewiki.core_spec

local core = require("davewiki.core")

local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.core wiki_root resolution", function()
    before_each(function()
        core.wiki_root = nil
        pcall(vim.api.nvim_del_var, "davewiki_wiki_root")
    end)

    describe("setup with wiki_root option", function()
        it("should accept wiki_root from setup options", function()
            core.setup({ wiki_root = "/test/path" })
            assert.are.equal("/test/path", core.wiki_root)
        end)
    end)

    describe("setup with global variable", function()
        it("should use g:davewiki_wiki_root when no option provided", function()
            vim.api.nvim_set_var("davewiki_wiki_root", "/global/path")
            core.setup({})
            assert.are.equal("/global/path", core.wiki_root)
            pcall(vim.api.nvim_del_var, "davewiki_wiki_root")
        end)
    end)

    describe("setup with default path", function()
        it("should use ~/davewiki when neither option nor global set", function()
            pcall(vim.api.nvim_del_var, "davewiki_wiki_root")
            core.setup({})
            local wiki_root = core.wiki_root
            assert.is_not_nil(wiki_root)
            assert.is_string(wiki_root)
        end)
    end)

    describe("get wiki_root", function()
        it("should return the wiki_root after setup", function()
            core.setup({ wiki_root = "/my/wiki" })
            assert.are.equal("/my/wiki", core.wiki_root)
        end)

        it("should return nil before setup is called", function()
            core.wiki_root = nil
            assert.are.equal(nil, core.wiki_root)
        end)
    end)
end)

describe("davewiki.core constants", function()
    it("should have TAG_PATTERN defined", function()
        assert.is_not_nil(core.TAG_PATTERN)
        assert.are.equal("#[A-Za-z0-9-_]+", core.TAG_PATTERN)
    end)
end)

describe("davewiki.core is_valid_tag", function()
    it("should return true for valid tags", function()
        assert.is_true(core.is_valid_tag("#test"))
        assert.is_true(core.is_valid_tag("#test-tag"))
        assert.is_true(core.is_valid_tag("#test_tag"))
        assert.is_true(core.is_valid_tag("#Test123"))
    end)

    it("should return false for invalid tags", function()
        assert.is_false(core.is_valid_tag("test"))
        assert.is_false(core.is_valid_tag("#"))
        assert.is_false(core.is_valid_tag("#tag@invalid"))
        assert.is_false(core.is_valid_tag("#tag space"))
        assert.is_false(core.is_valid_tag("#tag#invalid"))
    end)
end)

describe("davewiki.core is_path_within_wiki_root", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    after_each(function()
        core.wiki_root = nil
    end)

    it("should return true for path within wiki_root", function()
        assert.is_true(core.is_path_within_wiki_root(test_root .. "/notes/file.md"))
    end)

    it("should return true for wiki_root itself", function()
        assert.is_true(core.is_path_within_wiki_root(test_root))
    end)

    it("should return false for path outside wiki_root", function()
        assert.is_false(core.is_path_within_wiki_root("/etc/passwd"))
    end)

    it("should return false for path traversal attempt", function()
        local escaped_path = vim.fn.resolve(test_root .. "/../../../etc/passwd")
        assert.is_false(core.is_path_within_wiki_root(escaped_path))
    end)

    it("should return false when wiki_root is nil", function()
        core.wiki_root = nil
        assert.is_false(core.is_path_within_wiki_root("/any/path"))
    end)
end)

describe("davewiki.core url_encode", function()
    it("should encode spaces as %20", function()
        local result = core.url_encode("file with spaces.md")
        assert.are.equal("file%20with%20spaces.md", result)
    end)

    it("should encode special characters", function()
        local result = core.url_encode("file#name.md")
        assert.are.equal("file%23name.md", result)
    end)

    it("should not encode safe characters", function()
        local result = core.url_encode("regular-file_name.md")
        assert.are.equal("regular-file_name.md", result)
    end)

    it("should encode multiple special characters", function()
        local result = core.url_encode("file with # special & chars.md")
        assert.are.equal("file%20with%20%23%20special%20%26%20chars.md", result)
    end)

    it("should return empty string for empty input", function()
        local result = core.url_encode("")
        assert.are.equal("", result)
    end)
end)

describe("davewiki.core is_tag_file", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    after_each(function()
        core.wiki_root = nil
    end)

    it("should return true for files in sources/ directory", function()
        assert.is_true(core.is_tag_file(test_root .. "/sources/bengal.md"))
        assert.is_true(core.is_tag_file(test_root .. "/sources/mackerel.md"))
    end)

    it("should return false for files outside sources/", function()
        assert.is_false(core.is_tag_file(test_root .. "/notes/fish-types.md"))
        assert.is_false(core.is_tag_file(test_root .. "/bengal.md"))
    end)

    it("should return false for non-markdown files", function()
        assert.is_false(core.is_tag_file(test_root .. "/sources/bengal.txt"))
        assert.is_false(core.is_tag_file(test_root .. "/sources/bengal"))
    end)

    it("should return false when wiki_root is nil", function()
        core.wiki_root = nil
        assert.is_false(core.is_tag_file(test_root .. "/sources/bengal.md"))
    end)
end)

describe("davewiki.core generate_absolute_path", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    after_each(function()
        core.wiki_root = nil
    end)

    it("should generate absolute path for file within wiki_root", function()
        local result = core.generate_absolute_path(test_root .. "/notes/file.md")
        assert.is_not_nil(result)
        assert.are.equal("/notes/file.md", result)
    end)

    it("should generate absolute path for file at root", function()
        local target_file = test_root .. "/README.md"
        local absolute_path = core.generate_absolute_path(target_file)
        assert.are.equal("/README.md", absolute_path)
    end)

    it("should generate absolute path for nested directory", function()
        local target_file = test_root .. "/notes/deep/nested/file.md"
        local absolute_path = core.generate_absolute_path(target_file)
        assert.are.equal("/notes/deep/nested/file.md", absolute_path)
    end)

    it("should handle files with spaces in names", function()
        local target_file = test_root .. "/notes/my file.md"
        local absolute_path = core.generate_absolute_path(target_file)
        assert.are.equal("/notes/my%20file.md", absolute_path)
    end)

    it("should return nil for file outside wiki_root", function()
        local result = core.generate_absolute_path("/etc/passwd")
        assert.is_nil(result)
    end)

    it("should return nil when wiki_root is nil", function()
        core.wiki_root = nil
        local result = core.generate_absolute_path("/any/path")
        assert.is_nil(result)
    end)
end)

describe("davewiki.core date_string", function()
    it("should format the current date as a string", function()
        local result = core.date_string("%Y-%m-%d")
        assert.are.equal("string", type(result))
        assert.truthy(result:match("^%d%d%d%d%-%d%d%-%d%d$"))
    end)

    it("should format a given time value", function()
        -- 2021-03-15 12:00:00 UTC-ish; use os.time to construct a local time
        local time = os.time({ year = 2021, month = 3, day = 15, hour = 12 })
        local result = core.date_string("%Y-%m-%d", time)
        assert.are.equal("2021-03-15", result)
    end)
end)

describe("davewiki.core date_table", function()
    it("should return a date table for the current time", function()
        local result = core.date_table()
        assert.are.equal("table", type(result))
        assert.are.equal("number", type(result.year))
        assert.are.equal("number", type(result.month))
        assert.are.equal("number", type(result.day))
    end)

    it("should return a date table for a given time value", function()
        local time = os.time({ year = 2021, month = 3, day = 15, hour = 12 })
        local result = core.date_table(time)
        assert.are.equal(2021, result.year)
        assert.are.equal(3, result.month)
        assert.are.equal(15, result.day)
    end)
end)
