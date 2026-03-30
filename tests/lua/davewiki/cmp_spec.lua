---
-- Tests for davewiki.cmp nvim-cmp integration
-- @module davewiki.cmp_spec

local cmp = require("davewiki.cmp")
local core = require("davewiki.core")

-- Get the absolute path to test_root directory relative to this script
local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.cmp setup", function()
    before_each(function()
        cmp.config.enabled = true
    end)

    describe("config.enabled", function()
        it("should return true by default", function()
            cmp.config.enabled = true
            assert.is_true(cmp.config.enabled)
        end)

        it("should return false when disabled", function()
            cmp.config.enabled = false
            assert.is_false(cmp.config.enabled)
        end)
    end)

    describe("setup", function()
        it("should update config when passed options", function()
            cmp.setup({ enabled = false })
            assert.is_false(cmp.config.enabled)
        end)

        it("should preserve existing config when no options passed", function()
            cmp.config.enabled = false
            cmp.setup({})
            assert.is_false(cmp.config.enabled)
        end)
    end)
end)

describe("davewiki.cmp wiki_tags source", function()
    local mock_cmp
    local registered_sources

    before_each(function()
        -- Set up wiki_root for tag file operations using setup() to normalize path
        core.setup({ wiki_root = test_root })

        -- Mock cmp module
        registered_sources = {}
        mock_cmp = {
            register_source = function(name, source)
                registered_sources[name] = source
            end,
        }

        -- Inject mock cmp
        _G.mock_cmp = mock_cmp
    end)

    after_each(function()
        _G.mock_cmp = nil
        registered_sources = nil
    end)

    describe("register_tag_names", function()
        it("should register source under name wiki_tags", function()
            cmp.register_tag_names()

            assert.is_not_nil(registered_sources["wiki_tags"])
            assert.is_table(registered_sources["wiki_tags"])
        end)

        it("should register source with required methods", function()
            cmp.register_tag_names()

            local source = registered_sources["wiki_tags"]
            assert.is_function(source.new)
            assert.is_function(source.get_trigger_characters)
            assert.is_function(source.is_available)
            assert.is_function(source.complete)
        end)
    end)

    describe("wiki_tags source behavior", function()
        local source

        before_each(function()
            cmp.register_tag_names()
            source = registered_sources["wiki_tags"]
        end)

        describe("get_trigger_characters", function()
            it("should return # as trigger character", function()
                local triggers = source.get_trigger_characters()
                assert.is_table(triggers)
                assert.is_true(vim.tbl_contains(triggers, "#"))
            end)
        end)

        describe("is_available", function()
            before_each(function()
                core.setup({ wiki_root = test_root })
            end)

            it("should return true for markdown buffers within wiki_root", function()
                local test_file = test_root .. "/cmp-test-file.md"
                vim.fn.writefile({ "# Test" }, test_file)
                local buf = vim.fn.bufadd(test_file)
                vim.fn.bufload(buf)
                vim.api.nvim_set_current_buf(buf)
                vim.bo[buf].filetype = "markdown"

                assert.is_true(source.is_available())

                vim.api.nvim_buf_delete(buf, { force = true })
                vim.fn.delete(test_file)
            end)

            it("should return false for markdown buffers outside wiki_root", function()
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(buf, "/tmp/outside-wiki.md")
                vim.api.nvim_set_current_buf(buf)
                vim.bo[buf].filetype = "markdown"

                assert.is_false(source.is_available())

                vim.api.nvim_buf_delete(buf, { force = true })
            end)

            it("should return false for non-markdown buffers", function()
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_set_current_buf(buf)
                vim.bo[buf].filetype = "lua"

                assert.is_false(source.is_available())

                vim.api.nvim_buf_delete(buf, { force = true })
            end)
        end)

        describe("complete", function()
            local instance

            before_each(function()
                instance = source.new()
            end)

            it("should call callback with all tags", function()
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_set_current_buf(buf)
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "#bengal" })
                vim.bo[buf].filetype = "markdown"

                local params = {
                    context = {
                        cursor_before_line = "#bengal",
                    },
                    offset = 1,
                }

                local result = nil
                local callback = function(response)
                    result = response
                end

                instance:complete(params, callback)

                vim.api.nvim_buf_delete(buf, { force = true })

                assert.is_table(result)
                assert.is_table(result.items)
                assert.is_true(#result.items > 0)
            end)

            it("should include tag with documentation showing usage count", function()
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_set_current_buf(buf)
                vim.bo[buf].filetype = "markdown"

                local params = {
                    context = {
                        cursor_before_line = "#ben",
                    },
                    offset = 1,
                }

                local result = nil
                local callback = function(response)
                    result = response
                end

                instance:complete(params, callback)

                vim.api.nvim_buf_delete(buf, { force = true })

                -- Should have items with documentation
                local found = false
                for _, item in ipairs(result.items) do
                    if item.documentation then
                        found = true
                        assert.is_not_nil(item.documentation:match("Used .* times"))
                        break
                    end
                end
                assert.is_true(found)
            end)

            it("should return all tags regardless of prefix", function()
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_set_current_buf(buf)
                vim.bo[buf].filetype = "markdown"

                local params = {
                    context = {
                        cursor_before_line = "#xyz",
                    },
                    offset = 1,
                }

                local result = nil
                local callback = function(response)
                    result = response
                end

                instance:complete(params, callback)

                vim.api.nvim_buf_delete(buf, { force = true })

                -- Should still return all tags (filtering happens via trigger char)
                assert.is_true(#result.items > 0)
            end)
        end)
    end)
end)
