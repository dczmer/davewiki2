---
-- Tests for davewiki.telescope telescope.nvim integration
-- @module davewiki.telescope_spec

local telescope = require("davewiki.telescope")
local core = require("davewiki.core")
local markdown = require("davewiki.markdown")
local tags = require("davewiki.tags")
local test_util = require("davewiki.test_util")

-- Get the absolute path to test_root directory relative to this script
local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.telescope setup", function()
    before_each(function()
        telescope.config.enabled = true
        core.wiki_root = nil
    end)

    describe("config.enabled", function()
        it("should return true by default", function()
            telescope.config.enabled = true
            assert.is_true(telescope.config.enabled)
        end)

        it("should return false when disabled", function()
            telescope.config.enabled = false
            assert.is_false(telescope.config.enabled)
        end)
    end)

    describe("setup", function()
        it("should update config when passed options", function()
            telescope.setup({ enabled = false })
            assert.is_false(telescope.config.enabled)
        end)

        it("should preserve existing config when no options passed", function()
            telescope.config.enabled = false
            telescope.setup({})
            assert.is_false(telescope.config.enabled)
        end)
    end)
end)

describe("davewiki.telescope tags function", function()
    local mock_notify
    local restore_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify, restore_notify = test_util.mock_notify()
    end)

    after_each(function()
        restore_notify()
    end)

    describe("tags", function()
        it("should return false when telescope is not installed", function()
            local restore = test_util.with_telescope_uninstalled(core)

            local result = telescope.tags()

            restore()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: telescope.nvim not installed", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.WARN, mock_notify.calls[1].level)
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = telescope.tags()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: wiki_root is not configured", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)
    end)
end)

describe("davewiki.telescope tag_references function", function()
    local mock_notify
    local restore_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify, restore_notify = test_util.mock_notify()
    end)

    after_each(function()
        restore_notify()
    end)

    describe("tag_references", function()
        it("should return false when telescope is not installed", function()
            local restore = test_util.with_telescope_uninstalled(core)

            local result = telescope.tag_references("#bengal")

            restore()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: telescope.nvim not installed", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.WARN, mock_notify.calls[1].level)
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = telescope.tag_references("#bengal")

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: wiki_root is not configured", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)

        it("should return false for invalid tag name", function()
            local result = telescope.tag_references("#invalid@tag")
            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: Invalid tag name: #invalid@tag", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)
    end)
end)

-- The :DavewikiTagReferences user command must normalize an empty <args>
-- string to nil so that a no-argument invocation lists all tag references
-- instead of failing tag validation. Regression test for the broken
-- `opts.args == "" and nil or opts.args` idiom (always evaluated to opts.args).
describe("davewiki.telescope DavewikiTagReferences command", function()
    local original_tag_references
    local captured_args

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        telescope.setup_commands()

        -- Stub tag_references to capture the argument without opening a picker
        captured_args = {}
        original_tag_references = telescope.tag_references
        telescope.tag_references = function(...)
            table.insert(captured_args, { n = select("#", ...), value = (...) })
            return true
        end
    end)

    after_each(function()
        telescope.tag_references = original_tag_references
    end)

    it("should pass nil to tag_references when no argument is given", function()
        vim.cmd("DavewikiTagReferences")

        assert.are.equal(1, #captured_args)
        assert.are.equal(1, captured_args[1].n)
        assert.is_nil(captured_args[1].value)
    end)

    it("should pass the tag name to tag_references when an argument is given", function()
        vim.cmd("DavewikiTagReferences #bengal")

        assert.are.equal(1, #captured_args)
        assert.are.equal("#bengal", captured_args[1].value)
    end)
end)

describe("davewiki.telescope insert_link function", function()
    local mock_notify
    local restore_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify, restore_notify = test_util.mock_notify()
    end)

    after_each(function()
        restore_notify()
    end)

    describe("insert_link", function()
        it("should return false when telescope is not installed", function()
            local restore = test_util.with_telescope_uninstalled(core)

            local result = telescope.insert_link()

            restore()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: telescope.nvim not installed", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.WARN, mock_notify.calls[1].level)
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = telescope.insert_link()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: wiki_root is not configured", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)

        it("should return false when no file is open", function()
            vim.cmd("enew!")

            local result = telescope.insert_link()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: No file open in current buffer", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)

        it("should return false when current file is outside wiki_root", function()
            vim.cmd("enew!")
            vim.api.nvim_buf_set_name(0, "/outside/wiki/file.md")

            local result = telescope.insert_link()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal(
                "davewiki: Current file is not within wiki_root",
                mock_notify.calls[1].msg
            )
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)

        it("should return false when no markdown files exist", function()
            -- Temporarily set wiki_root to empty directory
            local original_root = core.wiki_root
            core.wiki_root = "/tmp/empty-davewiki-test"
            vim.fn.mkdir(core.wiki_root, "p")

            vim.cmd("enew!")
            vim.api.nvim_buf_set_name(0, core.wiki_root .. "/file.md")

            local result = telescope.insert_link()

            core.wiki_root = original_root
            vim.fn.delete("/tmp/empty-davewiki-test", "rf")

            assert.is_false(result)
        end)
    end)
end)

describe("davewiki.telescope helper functions", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
    end)

    describe("davewiki.tags get_tags_list", function()
        it("should return list of unique tags from wiki", function()
            local tag_list = tags.get_tags_list()

            assert.is_table(tag_list)
            assert.is_true(#tag_list > 0)

            for _, tag in ipairs(tag_list) do
                assert.is_string(tag)
                assert.is_true(tag:match("^#") ~= nil)
            end

            for i = 2, #tag_list do
                assert.is_true(tag_list[i - 1] <= tag_list[i])
            end
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local tag_list = tags.get_tags_list()
            assert.is_table(tag_list)
            assert.are.equal(0, #tag_list)
        end)
    end)
end)

describe("davewiki.telescope headings function", function()
    local mock_notify
    local restore_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify, restore_notify = test_util.mock_notify()
    end)

    after_each(function()
        restore_notify()
    end)

    describe("headings", function()
        it("should return false when telescope is not installed", function()
            local restore = test_util.with_telescope_uninstalled(core)

            local result = telescope.headings()

            restore()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: telescope.nvim not installed", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.WARN, mock_notify.calls[1].level)
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = telescope.headings()

            assert.is_false(result)
            assert.are.equal(1, #mock_notify.calls)
            assert.are.equal("davewiki: wiki_root is not configured", mock_notify.calls[1].msg)
            assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
        end)
    end)

    describe("davewiki.markdown get_headings_list", function()
        it("should return list of all level-1 headings from wiki", function()
            local headings = markdown.get_headings_list()

            assert.is_table(headings)
            assert.is_true(#headings > 0)

            for _, heading in ipairs(headings) do
                assert.is_table(heading)
                assert.is_string(heading.text)
                assert.is_string(heading.file)
                assert.is_number(heading.lnum)
                assert.is_true(heading.text:match("^# .+") ~= nil)
            end

            for i = 2, #headings do
                assert.is_true(headings[i - 1].text <= headings[i].text)
            end
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local headings = markdown.get_headings_list()
            assert.is_table(headings)
            assert.are.equal(0, #headings)
        end)

        it("should only include level-1 headings", function()
            local headings = markdown.get_headings_list()

            for _, heading in ipairs(headings) do
                local heading_content = heading.text:sub(3)
                assert.is_false(
                    heading_content:match("^#") ~= nil,
                    "Heading '" .. heading.text .. "' appears to be level-2 or higher"
                )
            end
        end)

        it("should include filename in each heading entry", function()
            local headings = markdown.get_headings_list()
            assert.is_true(#headings > 0)

            for _, heading in ipairs(headings) do
                assert.is_string(heading.file)
                assert.is_true(heading.file:match(test_root) ~= nil)
            end
        end)
    end)
end)
