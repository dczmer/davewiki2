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

    describe("get_tag_sources", function()
        it("should return tag file paths sorted alphabetically", function()
            local sources = telescope.get_tag_sources()

            assert.is_table(sources)
            assert.is_true(#sources > 0)

            -- Each source should be a valid tag file path
            for _, source in ipairs(sources) do
                assert.is_string(source)
                assert.is_true(source:match("/sources/.*%.md$") ~= nil)
            end

            -- Sources should be alphabetically sorted
            for i = 2, #sources do
                assert.is_true(sources[i - 1] <= sources[i])
            end
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local sources = telescope.get_tag_sources()
            assert.is_table(sources)
            assert.are.equal(0, #sources)
        end)
    end)

    describe("get_references", function()
        it("should find references to a valid tag", function()
            -- First ensure there's a tag to search for
            local tags = telescope.get_tags_list()
            assert.is_true(#tags > 0)

            -- Pick a known tag from test data
            local references = telescope.get_references("#bengal")

            assert.is_table(references)
            -- May or may not have references depending on test data
        end)

        it("should return empty table for non-existent tag", function()
            local references = telescope.get_references("#nonexistent-tag-xyz123")

            assert.is_table(references)
            assert.are.equal(0, #references)
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local references = telescope.get_references("#bengal")
            assert.is_table(references)
            assert.are.equal(0, #references)
        end)

        it("should return empty table for invalid tag", function()
            local references = telescope.get_references("#invalid@tag")
            assert.is_table(references)
            assert.are.equal(0, #references)
        end)
    end)
end)