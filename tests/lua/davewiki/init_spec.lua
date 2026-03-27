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
        end)

        it("should set wiki_root in config", function()
            local config = davewiki.get_config()
            assert.is_not_nil(config.wiki_root)
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

    it("should open buffer for non-existing tag", function()
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

        -- Verify buffer was opened with correct path
        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("jump%-to%-tag%-test%.md$") ~= nil)

        -- Verify buffer has frontmatter content
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local content_str = table.concat(lines, "\n")
        assert.is_true(content_str:match("name: jump%-to%-tag%-test") ~= nil)

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

local core = require("davewiki.core")

describe("highlight pattern", function()
    --- Build the highlight pattern as it's constructed in init.lua
    --- @return string The vim regex pattern for highlighting
    local function get_highlight_pattern()
        return core.TAG_PATTERN:gsub("+", "\\+") .. "\\>"
    end

    describe("highlight pattern construction", function()
        it("should escape + for vim regex", function()
            local pattern = get_highlight_pattern()
            assert.is_true(pattern:find("\\+") ~= nil, "Pattern should have escaped +")
        end)

        it("should include word boundary at end", function()
            local pattern = get_highlight_pattern()
            assert.is_true(pattern:find("\\>$") ~= nil, "Pattern should end with word boundary")
        end)

        it("should match expected format", function()
            local pattern = get_highlight_pattern()
            assert.are.equal("#[A-Za-z0-9-_]\\+\\>", pattern)
        end)
    end)

    describe("core.TAG_PATTERN", function()
        it("should be exported as a module variable", function()
            assert.is_not_nil(core.TAG_PATTERN)
            assert.are.equal("#[A-Za-z0-9-_]+", core.TAG_PATTERN)
        end)

        describe("valid tag patterns (should match)", function()
            local valid_cases = {
                { input = "#tag", description = "simple tag" },
                { input = "#my-tag", description = "tag with hyphen" },
                { input = "#my_tag", description = "tag with underscore" },
                { input = "#tag123", description = "tag with numbers" },
                { input = "#123", description = "numeric tag" },
                { input = "#a-b-c", description = "multiple hyphens" },
                { input = "#a_b_c", description = "multiple underscores" },
                { input = "#TAG", description = "uppercase tag" },
                {
                    input = "#Tag-Name_123",
                    description = "mixed case with hyphen, underscore, and numbers",
                },
            }

            for _, case in ipairs(valid_cases) do
                it(string.format("should match %s: '%s'", case.description, case.input), function()
                    local match = case.input:match("^" .. core.TAG_PATTERN .. "$")
                    assert.is_not_nil(
                        match,
                        string.format("Expected '%s' to match pattern", case.input)
                    )
                end)
            end
        end)

        describe("invalid tag patterns (should NOT match)", function()
            local invalid_cases = {
                { input = "tag", description = "missing hash prefix" },
                { input = "#", description = "hash only" },
                { input = "# tag", description = "space after hash" },
                { input = "#tag name", description = "space in tag" },
                { input = "#tag#tag", description = "double hash (invalid combined)" },
                { input = "#tag$invalid", description = "special character $" },
                { input = "#tag@invalid", description = "special character @" },
                { input = "#tag!invalid", description = "special character !" },
                { input = "#tag%invalid", description = "special character %" },
                { input = "#tag^invalid", description = "special character ^" },
                { input = "#tag&invalid", description = "special character &" },
                { input = "#tag*invalid", description = "special character *" },
                { input = "#tag(invalid", description = "special character (" },
                { input = "#tag)invalid", description = "special character )" },
                { input = "#tag+invalid", description = "special character +" },
                { input = "#tag=invalid", description = "special character =" },
                { input = "#tag[invalid", description = "special character [" },
                { input = "#tag]invalid", description = "special character ]" },
                { input = "#tag{invalid", description = "special character {" },
                { input = "#tag}invalid", description = "special character }" },
                { input = "#tag|invalid", description = "special character |" },
                { input = "#tag:invalid", description = "special character :" },
                { input = "#tag;invalid", description = "special character ;" },
                { input = "#tag'invalid", description = "special character '" },
                { input = '#tag"invalid', description = 'special character "' },
                { input = "#tag<invalid", description = "special character <" },
                { input = "#tag>invalid", description = "special character >" },
                { input = "#tag/invalid", description = "special character /" },
                { input = "#tag?invalid", description = "special character ?" },
                { input = "#tag,invalid", description = "special character ," },
                { input = "#tag.invalid", description = "special character ." },
            }

            for _, case in ipairs(invalid_cases) do
                it(
                    string.format("should NOT match %s: '%s'", case.description, case.input),
                    function()
                        local match = case.input:match("^" .. core.TAG_PATTERN .. "$")
                        assert.is_nil(
                            match,
                            string.format("Expected '%s' to NOT match pattern", case.input)
                        )
                    end
                )
            end
        end)

        describe("partial matches (should match portion only)", function()
            it("should match the first tag in '#tag some text'", function()
                local match = ("#tag some text"):match(core.TAG_PATTERN)
                assert.are.equal("#tag", match)
            end)

            it("should match tag in middle of 'text #tag more'", function()
                local match = ("text #tag more"):match(core.TAG_PATTERN)
                assert.are.equal("#tag", match)
            end)

            it("should match tag at end of 'text #tag'", function()
                local match = ("text #tag"):match(core.TAG_PATTERN)
                assert.are.equal("#tag", match)
            end)
        end)
    end)
end)
