---
-- Tests for davewiki.telescope telescope.nvim integration
-- @module davewiki.telescope_spec

local telescope = require("davewiki.telescope")
local core = require("davewiki.core")
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
    local original_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        vim.notify = original_notify
    end)

    describe("tags", function()
        it("should return false when telescope is not installed", function()
            -- Mock telescope module as not installed
            local original_require = _G.require
            _G.require = function(mod)
                if mod == "telescope" then
                    error("module 'telescope' not found")
                end
                return original_require(mod)
            end

            local result = telescope.tags()

            _G.require = original_require

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
    local original_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        vim.notify = original_notify
    end)

    describe("tag_references", function()
        it("should return false when telescope is not installed", function()
            -- Mock telescope module as not installed
            local original_require = _G.require
            _G.require = function(mod)
                if mod == "telescope" then
                    error("module 'telescope' not found")
                end
                return original_require(mod)
            end

            local result = telescope.tag_references("#bengal")

            _G.require = original_require

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
        end)
    end)
end)

describe("davewiki.telescope insert_link function", function()
    local mock_notify
    local original_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        vim.notify = original_notify
    end)

    describe("insert_link", function()
        it("should return false when telescope is not installed", function()
            -- Mock telescope module as not installed
            local original_require = _G.require
            _G.require = function(mod)
                if mod == "telescope" then
                    error("module 'telescope' not found")
                end
                return original_require(mod)
            end

            local result = telescope.insert_link()

            _G.require = original_require

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
            -- Mock nvim_buf_get_name to return empty string
            local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
            vim.api.nvim_buf_get_name = function()
                return ""
            end

            local result = telescope.insert_link()

            vim.api.nvim_buf_get_name = original_nvim_buf_get_name

            assert.is_false(result)
        end)

        it("should return false when current file is outside wiki_root", function()
            -- Mock nvim_buf_get_name to return a file outside wiki_root
            local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
            vim.api.nvim_buf_get_name = function()
                return "/outside/wiki/file.md"
            end

            local result = telescope.insert_link()

            vim.api.nvim_buf_get_name = original_nvim_buf_get_name

            assert.is_false(result)
        end)

        it("should return false when no markdown files exist", function()
            -- Mock nvim_buf_get_name
            local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
            vim.api.nvim_buf_get_name = function()
                return test_root .. "/notes/baked-fish.md"
            end

            -- Temporarily set wiki_root to empty directory
            local original_root = core.wiki_root
            core.wiki_root = "/tmp/empty-davewiki-test"
            vim.fn.mkdir(core.wiki_root, "p")

            local result = telescope.insert_link()

            core.wiki_root = original_root
            vim.fn.delete("/tmp/empty-davewiki-test", "rf")
            vim.api.nvim_buf_get_name = original_nvim_buf_get_name

            assert.is_false(result)
        end)
    end)

    describe("davewiki.core generate_absolute_path", function()
        before_each(function()
            core.setup({ wiki_root = test_root })
        end)

        it("should generate absolute path for file in same directory", function()
            local current_file = test_root .. "/notes/baked-fish.md"
            local target_file = test_root .. "/notes/grilled-fish.md"

            local absolute_path = core.generate_absolute_path(target_file)

            assert.are.equal("/notes/grilled-fish.md", absolute_path)
        end)

        it("should generate absolute path for file in different directory", function()
            local current_file = test_root .. "/notes/recipes/summer.md"
            local target_file = test_root .. "/notes/grilled-fish.md"

            local absolute_path = core.generate_absolute_path(target_file)

            assert.are.equal("/notes/grilled-fish.md", absolute_path)
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

        it("should return nil when target is outside wiki_root", function()
            local target_file = "/etc/passwd"

            local absolute_path = core.generate_absolute_path(target_file)

            assert.is_nil(absolute_path)
        end)
    end)
end)

describe("davewiki.telescope helper functions", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
    end)

    describe("davewiki.core get_tags_list", function()
        it("should return list of unique tags from wiki", function()
            local tags = core.get_tags_list()

            assert.is_table(tags)
            assert.is_true(#tags > 0)

            for _, tag in ipairs(tags) do
                assert.is_string(tag)
                assert.is_true(tag:match("^#") ~= nil)
            end

            for i = 2, #tags do
                assert.is_true(tags[i - 1] <= tags[i])
            end
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local tags = core.get_tags_list()
            assert.is_table(tags)
            assert.are.equal(0, #tags)
        end)
    end)
end)

describe("davewiki.telescope headings function", function()
    local mock_notify
    local original_notify

    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        vim.notify = original_notify
    end)

    describe("headings", function()
        it("should return false when telescope is not installed", function()
            -- Mock telescope module as not installed
            local original_require = _G.require
            _G.require = function(mod)
                if mod == "telescope" then
                    error("module 'telescope' not found")
                end
                return original_require(mod)
            end

            local result = telescope.headings()

            _G.require = original_require

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

    describe("davewiki.core get_headings_list", function()
        it("should return list of all level-1 headings from wiki", function()
            local headings = core.get_headings_list()

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
            local headings = core.get_headings_list()
            assert.is_table(headings)
            assert.are.equal(0, #headings)
        end)

        it("should only include level-1 headings", function()
            local headings = core.get_headings_list()

            for _, heading in ipairs(headings) do
                local heading_content = heading.text:sub(3)
                assert.is_false(
                    heading_content:match("^#") ~= nil,
                    "Heading '" .. heading.text .. "' appears to be level-2 or higher"
                )
            end
        end)

        it("should include filename in each heading entry", function()
            local headings = core.get_headings_list()
            assert.is_true(#headings > 0)

            for _, heading in ipairs(headings) do
                assert.is_string(heading.file)
                assert.is_true(heading.file:match(test_root) ~= nil)
            end
        end)
    end)
end)
