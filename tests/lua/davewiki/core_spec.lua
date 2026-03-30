---
-- Tests for davewiki.core utility functions
-- @module davewiki.core_spec

local core = require("davewiki.core")

local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.core wiki_root resolution", function()
    before_each(function()
        core.wiki_root = nil
        vim.g.davewiki_wiki_root = nil
    end)

    describe("setup with wiki_root option", function()
        it("should accept wiki_root from setup options", function()
            local result = core.setup({ wiki_root = "/test/path" })
            assert.are.equal("/test/path", core.wiki_root)
        end)
    end)

    describe("setup with global variable", function()
        it("should use g:davewiki_wiki_root when no option provided", function()
            vim.g.davewiki_wiki_root = "/global/path"
            core.setup({})
            assert.are.equal("/global/path", core.wiki_root)
            vim.g.davewiki_wiki_root = nil
        end)
    end)

    describe("setup with default path", function()
        it("should use ~/davewiki when neither option nor global set", function()
            vim.g.davewiki_wiki_root = nil
            local result = core.setup({})
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

    it("should return false for nil input", function()
        assert.is_false(core.is_valid_tag(nil))
    end)

    it("should return false for non-string input", function()
        assert.is_false(core.is_valid_tag(123))
        assert.is_false(core.is_valid_tag({}))
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

    it("should return false for nil path", function()
        assert.is_false(core.is_tag_file(nil))
    end)
end)