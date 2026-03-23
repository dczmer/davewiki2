---
-- Tests for davewiki.init public interface
-- @module davewiki.init_spec

local davewiki = require("davewiki")

-- Get the test_root directory path
local test_root = "../test_root"

describe("davewiki public interface", function()
    before_each(function()
        -- Reset module state
        davewiki.setup({ wiki_root = test_root })
    end)

    describe("setup", function()
        it("should accept wiki_root in config", function()
            local result = davewiki.setup({ wiki_root = "/test/path" })
            assert.is_not_nil(result)
            assert.is_not_nil(result.core)
        end)

        it("should expose core module", function()
            assert.is_not_nil(davewiki.core)
            assert.is_not_nil(davewiki.core.wiki_root)
        end)
    end)

    describe("get_config", function()
        it("should return current configuration", function()
            local config = davewiki.get_config()
            assert.is_not_nil(config)
            assert.is_not_nil(config.wiki_root)
        end)
    end)
end)

describe("davewiki.jump_to_tag", function()
    before_each(function()
        davewiki.setup({ wiki_root = test_root })
    end)

    after_each(function()
        -- Clean up test files
        local test_file = test_root .. "/sources/jump-to-tag-test.md"
        if vim.fn.filereadable(test_file) == 1 then
            vim.fn.delete(test_file)
        end
    end)

    it("should return false when cursor not on tag", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "No tag here" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local success = davewiki.jump_to_tag()
        assert.is_false(success)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return true and jump when cursor on existing tag", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Text #bengal here" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- On #bengal

        local success = davewiki.jump_to_tag()
        assert.is_true(success)

        -- Verify we jumped to the file
        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("bengal%.md$") ~= nil)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should create and jump to non-existing tag", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Text #jump-to-tag-test here" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- On #jump-to-tag-test

        -- Ensure file doesn't exist
        local test_file = test_root .. "/sources/jump-to-tag-test.md"
        if vim.fn.filereadable(test_file) == 1 then
            vim.fn.delete(test_file)
        end

        local success = davewiki.jump_to_tag()
        assert.is_true(success)

        -- Verify file was created
        assert.are.equal(1, vim.fn.filereadable(test_file))

        -- Verify we jumped to it
        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("jump%-to%-tag%-test%.md$") ~= nil)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should handle valid tag at different cursor positions", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "The #siamese cat likes fish" })
        vim.api.nvim_set_current_buf(buf)

        -- Cursor at start of tag
        vim.api.nvim_win_set_cursor(0, { 1, 4 })
        local success = davewiki.jump_to_tag()
        assert.is_true(success)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)
end)
