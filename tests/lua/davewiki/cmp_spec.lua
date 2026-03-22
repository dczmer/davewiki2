---
-- Tests for davewiki.cmp nvim-cmp integration
-- @module davewiki.cmp_spec

local cmp = require("davewiki.cmp")
local core = require("davewiki.core")

local test_root = "/home/dave/source/davewiki2/test_root"

describe("davewiki.cmp setup", function()
	before_each(function()
		cmp.config.enabled = true
	end)

	describe("is_enabled", function()
		it("should return true by default", function()
			cmp.config.enabled = true
			assert.is_true(cmp.is_enabled())
		end)

		it("should return false when disabled", function()
			cmp.config.enabled = false
			assert.is_false(cmp.is_enabled())
		end)
	end)

	describe("setup", function()
		it("should update config when passed options", function()
			cmp.setup({ enabled = false })
			assert.is_false(cmp.is_enabled())
		end)

		it("should preserve existing config when no options passed", function()
			cmp.config.enabled = false
			cmp.setup({})
			assert.is_false(cmp.is_enabled())
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
			it("should return true for markdown buffers", function()
				local buf = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_set_current_buf(buf)
				vim.bo[buf].filetype = "markdown"

				assert.is_true(source.is_available())

				vim.api.nvim_buf_delete(buf, { force = true })
			end)

			it("should return true for markdown buffers with different names", function()
				local buf = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_set_current_buf(buf)
				vim.bo[buf].filetype = "markdown"

				assert.is_true(source.is_available())

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

			it("should return empty results when context has no # prefix", function()
				local context = {
					col = 1,
					cursor = { 1, 0 },
					line = "just text",
				}

				local items = instance:complete(context)

				assert.is_table(items)
				assert.are.equal(0, #items)
			end)

			it("should return all tags for bare # character", function()
				local context = {
					col = 2,
					cursor = { 1, 1 },
					line = "#",
				}

				local items = instance:complete(context)

				-- Bare # should return all tags (standard autocomplete behavior)
				assert.is_true(#items > 0)
			end)

			it("should return matching tags for valid prefix", function()
				local context = {
					col = 5,
					cursor = { 1, 4 },
					line = "#ben",
				}

				local items = instance:complete(context)

				-- Should find #bengal
				assert.is_true(#items > 0)
				local found = false
				for _, item in ipairs(items) do
					if item.label == "#bengal" then
						found = true
						break
					end
				end
				assert.is_true(found)
			end)

			it("should do case-insensitive matching", function()
				local context = {
					col = 5,
					cursor = { 1, 4 },
					line = "#BEN",
				}

				local items = instance:complete(context)

				-- Should find #bengal (case insensitive)
				assert.is_true(#items > 0)
			end)

			it("should return all tags when prefix matches nothing specific", function()
				local context = {
					col = 2,
					cursor = { 1, 1 },
					line = "#",
				}

				local items = instance:complete(context)

				-- Should return all available tags from test_root
				-- (at least bengal, mackerel should exist)
				assert.is_true(#items > 0)
			end)

			it("should return completion items with label containing # prefix", function()
				local context = {
					col = 5,
					cursor = { 1, 4 },
					line = "#ben",
				}

				local items = instance:complete(context)

				for _, item in ipairs(items) do
					assert.is_string(item.label)
					assert.is_true(item.label:sub(1, 1) == "#")
				end
			end)

			it("should handle partial matches at end of line", function()
				local context = {
					col = 10,
					cursor = { 1, 9 },
					line = "tag is #mac",
				}

				local items = instance:complete(context)

				-- Should find #mackerel
				local found = false
				for _, item in ipairs(items) do
					if item.label == "#mackerel" then
						found = true
						break
					end
				end
				assert.is_true(found)
			end)
		end)
	end)
end)
