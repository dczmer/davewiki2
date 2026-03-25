---
-- Tests for davewiki.telescope telescope.nvim integration
-- @module davewiki.telescope_spec

local telescope = require("davewiki.telescope")
local core = require("davewiki.core")

local test_root = "/home/dave/source/davewiki2/test_root"

describe("davewiki.telescope setup", function()
    before_each(function()
        telescope.config.enabled = true
        core.wiki_root = nil
    end)

    describe("is_enabled", function()
        it("should return true by default", function()
            telescope.config.enabled = true
            assert.is_true(telescope.is_enabled())
        end)

        it("should return false when disabled", function()
            telescope.config.enabled = false
            assert.is_false(telescope.is_enabled())
        end)
    end)

    describe("setup", function()
        it("should update config when passed options", function()
            telescope.setup({ enabled = false })
            assert.is_false(telescope.is_enabled())
        end)

        it("should preserve existing config when no options passed", function()
            telescope.config.enabled = false
            telescope.setup({})
            assert.is_false(telescope.is_enabled())
        end)
    end)
end)

describe("davewiki.telescope tags function", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
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
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = telescope.tags()
            assert.is_false(result)
        end)
    end)
end)

describe("davewiki.telescope tag_references function", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
        telescope.config.enabled = true
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
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = telescope.tag_references("#bengal")
            assert.is_false(result)
        end)

        it("should return false for invalid tag name", function()
            local result = telescope.tag_references("#invalid@tag")
            assert.is_false(result)
        end)
    end)
end)

describe("davewiki.telescope helper functions", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
    end)

    describe("get_tags_list", function()
        it("should return list of unique tags from wiki", function()
            local tags = telescope.get_tags_list()

            assert.is_table(tags)
            assert.is_true(#tags > 0)

            -- Each tag should be a string
            for _, tag in ipairs(tags) do
                assert.is_string(tag)
                assert.is_true(tag:match("^#") ~= nil)
            end

            -- Tags should be alphabetically sorted
            for i = 2, #tags do
                assert.is_true(tags[i - 1] <= tags[i])
            end
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local tags = telescope.get_tags_list()
            assert.is_table(tags)
            assert.are.equal(0, #tags)
        end)
    end)

end)