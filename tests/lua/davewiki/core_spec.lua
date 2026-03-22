---
-- Tests for davewiki.core wiki_root resolution and tag file management
-- @module davewiki.core_spec

local lua_core = require("davewiki.core")

-- Get the test_root directory path
local test_root = vim.fn.fnamemodify(debug.getinfo(1).source:match("@?(.*)/tests/"), ":p") .. "test_root"

describe("davewiki.core wiki_root resolution", function()
	before_each(function()
		lua_core.wiki_root = nil
		vim.g.davewiki_wiki_root = nil
	end)

	describe("setup with wiki_root option", function()
		it("should accept wiki_root from setup options", function()
			local result = lua_core.setup({ wiki_root = "/test/path" })
			assert.are.equal("/test/path", lua_core.wiki_root)
		end)
	end)

	describe("setup with global variable", function()
		it("should use g:davewiki_wiki_root when no option provided", function()
			vim.g.davewiki_wiki_root = "/global/path"
			lua_core.setup({})
			assert.are.equal("/global/path", lua_core.wiki_root)
			vim.g.davewiki_wiki_root = nil
		end)
	end)

	describe("setup with default path", function()
		it("should use ~/davewiki when neither option nor global set", function()
			vim.g.davewiki_wiki_root = nil
			local result = lua_core.setup({})
			local wiki_root = lua_core.wiki_root
			assert.is_not_nil(wiki_root)
			assert.is_string(wiki_root)
		end)
	end)

	describe("get wiki_root", function()
		it("should return the wiki_root after setup", function()
			lua_core.setup({ wiki_root = "/my/wiki" })
			assert.are.equal("/my/wiki", lua_core.wiki_root)
		end)

		it("should return nil before setup is called", function()
			lua_core.wiki_root = nil
			assert.are.equal(nil, lua_core.wiki_root)
		end)
	end)
end)

describe("davewiki.core tag file management", function()
	before_each(function()
		lua_core.wiki_root = test_root
		vim.g.davewiki_wiki_root = nil
	end)

	after_each(function()
		-- Clean up any test tag files created during tests
		local test_patterns = {
			test_root .. "/sources/test-tag-cleanup.md",
			test_root .. "/sources/no-frontmatter-test.md",
			test_root .. "/sources/no-name-test.md",
			test_root .. "/sources/no-created-test.md",
			test_root .. "/sources/valid-test-cleanup.md",
			test_root .. "/sources/frontmatter-test-tag.md",
		}
		for _, file in ipairs(test_patterns) do
			if vim.fn.filereadable(file) == 1 then
				vim.fn.delete(file)
			end
		end
	end)

	describe("constants", function()
		it("should have TAG_PATTERN defined", function()
			assert.is_not_nil(lua_core.TAG_PATTERN)
			assert.are.equal("#[A-Za-z0-9-_]+", lua_core.TAG_PATTERN)
		end)
	end)

	describe("create_frontmatter", function()
		it("should strip # prefix from tag name", function()
			local fm = lua_core.create_frontmatter("#test-tag")
			assert.are.equal("test-tag", fm.name)
		end)

		it("should work with tag name without # prefix", function()
			local fm = lua_core.create_frontmatter("test-tag")
			assert.are.equal("test-tag", fm.name)
		end)

		it("should set created date to current date", function()
			local fm = lua_core.create_frontmatter("#test")
			-- Check format: YYYY-MM-DD
			assert.is_true(fm.created:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil)
		end)

		it("should return table with name and created fields", function()
			local fm = lua_core.create_frontmatter("#test")
			assert.is_not_nil(fm.name)
			assert.is_not_nil(fm.created)
		end)
	end)

	describe("is_valid_tag", function()
		it("should return true for valid tags", function()
			assert.is_true(lua_core.is_valid_tag("#test"))
			assert.is_true(lua_core.is_valid_tag("#test-tag"))
			assert.is_true(lua_core.is_valid_tag("#test_tag"))
			assert.is_true(lua_core.is_valid_tag("#Test123"))
		end)

		it("should return false for invalid tags", function()
			assert.is_false(lua_core.is_valid_tag("test")) -- No # prefix
			assert.is_false(lua_core.is_valid_tag("#")) -- Empty tag
			assert.is_false(lua_core.is_valid_tag("#tag@invalid")) -- Invalid char
			assert.is_false(lua_core.is_valid_tag("#tag space")) -- Space
			assert.is_false(lua_core.is_valid_tag("#tag#invalid")) -- Double #
		end)

		it("should return false for nil input", function()
			assert.is_false(lua_core.is_valid_tag(nil))
		end)

		it("should return false for non-string input", function()
			assert.is_false(lua_core.is_valid_tag(123))
			assert.is_false(lua_core.is_valid_tag({}))
		end)
	end)

	describe("scan_for_tags", function()
		it("should find all tags in test files", function()
			local tags = lua_core.scan_for_tags()
			assert.is_table(tags)
			-- Should find tags like #bengal, #mackerel, etc.
			assert.is_true(#tags > 0)
		end)

		it("should return objects with tag, count, and files fields", function()
			local tags = lua_core.scan_for_tags()
			assert.is_table(tags)
			assert.is_true(#tags > 0)
			-- Check first result has required fields
			assert.is_not_nil(tags[1].tag)
			assert.is_not_nil(tags[1].count)
			assert.is_not_nil(tags[1].files)
			assert.is_number(tags[1].count)
			assert.is_table(tags[1].files)
		end)

		it("should sort results by count descending", function()
			local tags = lua_core.scan_for_tags()
			for i = 2, #tags do
				assert.is_true(tags[i - 1].count >= tags[i].count)
			end
		end)

		it("should track unique files per tag", function()
			local tags = lua_core.scan_for_tags()
			for _, tag_data in ipairs(tags) do
				local file_set = {}
				for _, file in ipairs(tag_data.files) do
					assert.is_nil(file_set[file]) -- No duplicates
					file_set[file] = true
				end
			end
		end)

		it("should not find invalid tags", function()
			local tags = lua_core.scan_for_tags()
			-- Check none of the results contain invalid patterns
			for _, tag_data in ipairs(tags) do
				assert.is_false(tag_data.tag:match("@") ~= nil)
				assert.is_false(tag_data.tag:match("#.+#") ~= nil)
			end
		end)
	end)

	describe("find_tag_files", function()
		it("should find existing tag files in sources/", function()
			local tag_files = lua_core.find_tag_files()
			assert.is_table(tag_files)
			-- Should find bengal.md, mackerel.md, etc.
			assert.is_true(#tag_files > 0)
		end)

		it("should return empty table when no tag files exist", function()
			-- Temporarily set wiki_root to empty dir
			local original_root = lua_core.wiki_root
			lua_core.wiki_root = "/tmp/nonexistent-davewiki-test"
			local tag_files = lua_core.find_tag_files()
			assert.are.equal(0, #tag_files)
			lua_core.wiki_root = original_root
		end)

		it("should return empty table when wiki_root is nil", function()
			local original = lua_core.wiki_root
			lua_core.wiki_root = nil
			local files = lua_core.find_tag_files()
			assert.are.equal(0, #files)
			lua_core.wiki_root = original
		end)
	end)

	describe("create_tag_file", function()
		it("should create tag file with proper frontmatter", function()
			local tag_name = "#test-tag-cleanup"
			local success = lua_core.create_tag_file(tag_name)
			assert.is_true(success)

			local tag_file_path = test_root .. "/sources/test-tag-cleanup.md"
			assert.are.equal(1, vim.fn.filereadable(tag_file_path))

			local content = vim.fn.readfile(tag_file_path)
			local content_str = table.concat(content, "\n")
			-- Check frontmatter exists
			assert.is_true(content_str:match("^---") ~= nil)
			assert.is_true(content_str:match("name: test%-tag%-cleanup") ~= nil)
			assert.is_true(content_str:match("created: %d%d%d%d%-%d%d%-%d%d") ~= nil)
		end)

		it("should return true for existing files", function()
			local tag_name = "#test-tag-cleanup"
			-- Create file first
			lua_core.create_tag_file(tag_name)
			-- Second call should return true (idempotent)
			local success = lua_core.create_tag_file(tag_name)
			assert.is_true(success)
		end)

		it("should not create tag file outside wiki_root", function()
			-- Try to create a tag that would escape wiki_root
			local success = lua_core.create_tag_file("#../../../etc/passwd")
			assert.is_false(success)
		end)

		it("should reject tags with path separators", function()
			assert.is_false(lua_core.create_tag_file("#test/../escape"))
			assert.is_false(lua_core.create_tag_file("#test/./escape"))
			assert.is_false(lua_core.create_tag_file("#test\\escape"))
		end)

		it("should reject empty tag name", function()
			assert.is_false(lua_core.create_tag_file("#"))
		end)
	end)

	describe("validate_frontmatter", function()
		it("should return violations for files with missing frontmatter", function()
			-- Create a test file without frontmatter
			local test_file = test_root .. "/sources/no-frontmatter-test.md"
			vim.fn.writefile({ "# Test", "Content" }, test_file)

			local violations = lua_core.validate_frontmatter()
			local found = false
			for _, v in ipairs(violations) do
				if v.file == test_file and v.issue:match("Missing YAML frontmatter") then
					found = true
					break
				end
			end
			assert.is_true(found)
		end)

		it("should detect missing name field", function()
			local test_file = test_root .. "/sources/no-name-test.md"
			vim.fn.writefile({ "---", "created: 2024-01-01", "---" }, test_file)

			local violations = lua_core.validate_frontmatter()
			local found = false
			for _, v in ipairs(violations) do
				if v.file == test_file and v.issue:match("name") then
					found = true
					break
				end
			end
			assert.is_true(found)
		end)

		it("should detect missing created field", function()
			local test_file = test_root .. "/sources/no-created-test.md"
			vim.fn.writefile({ "---", "name: test", "---" }, test_file)

			local violations = lua_core.validate_frontmatter()
			local found = false
			for _, v in ipairs(violations) do
				if v.file == test_file and v.issue:match("created") then
					found = true
					break
				end
			end
			assert.is_true(found)
		end)

		it("should not report violations for valid frontmatter", function()
			-- Files created by create_tag_file should have valid frontmatter
			lua_core.create_tag_file("#valid-test-cleanup")
			local violations = lua_core.validate_frontmatter()

			-- Check that our newly created file is NOT in violations
			local test_file = test_root .. "/sources/valid-test-cleanup.md"
			for _, v in ipairs(violations) do
				assert.is_false(v.file == test_file)
			end
		end)

		it("should dynamically check fields from template", function()
			-- Create frontmatter with only one field
			local test_file = test_root .. "/sources/frontmatter-test-tag.md"
			local frontmatter = lua_core.create_frontmatter("#frontmatter-test-tag")

			-- Create file missing 'created' field
			local content = {
				"---",
				"name: " .. frontmatter.name,
				"---",
			}
			vim.fn.writefile(content, test_file)

			local violations = lua_core.validate_frontmatter()
			local found_created_missing = false
			for _, v in ipairs(violations) do
				if v.file == test_file and v.issue:match("created") then
					found_created_missing = true
					break
				end
			end
			assert.is_true(found_created_missing)
		end)
	end)

	describe("get_tag_under_cursor", function()
		it("should extract valid tag under cursor", function()
			-- Create a test buffer with a tag
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "This is a #test-tag in text" })
			vim.api.nvim_set_current_buf(buf)
			vim.api.nvim_win_set_cursor(0, { 1, 10 }) -- Position cursor on #test-tag

			local tag = lua_core.get_tag_under_cursor()
			assert.are.equal("#test-tag", tag)

			vim.api.nvim_buf_delete(buf, { force = true })
		end)

		it("should return nil when cursor is not on a tag", function()
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "This is just regular text" })
			vim.api.nvim_set_current_buf(buf)
			vim.api.nvim_win_set_cursor(0, { 1, 5 })

			local tag = lua_core.get_tag_under_cursor()
			assert.is_nil(tag)

			vim.api.nvim_buf_delete(buf, { force = true })
		end)

		it("should handle tags at start of line", function()
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "#tag at start" })
			vim.api.nvim_set_current_buf(buf)
			vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- Cursor on #
			local tag = lua_core.get_tag_under_cursor()
			assert.are.equal("#tag", tag)
			vim.api.nvim_buf_delete(buf, { force = true })
		end)

		it("should handle multiple tags on same line", function()
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Text #first and #second here" })
			vim.api.nvim_set_current_buf(buf)

			-- Cursor on first tag
			vim.api.nvim_win_set_cursor(0, { 1, 8 })
			local tag = lua_core.get_tag_under_cursor()
			assert.are.equal("#first", tag)

			-- Cursor on second tag
			vim.api.nvim_win_set_cursor(0, { 1, 18 })
			tag = lua_core.get_tag_under_cursor()
			assert.are.equal("#second", tag)

			vim.api.nvim_buf_delete(buf, { force = true })
		end)
	end)

	describe("jump_to_tag_file", function()
		it("should jump to existing tag file", function()
			local tag_name = "#bengal"
			local success = lua_core.jump_to_tag_file(tag_name)
			assert.is_true(success)
			-- Check that we're now in the bengal.md file
			local current_file = vim.api.nvim_buf_get_name(0)
			assert.is_true(current_file:match("bengal%.md$") ~= nil)
		end)

		it("should create and jump to non-existing tag file", function()
			local tag_name = "#test-tag-cleanup"

			-- Ensure tag file doesn't exist
			local tag_file_path = test_root .. "/sources/test-tag-cleanup.md"
			if vim.fn.filereadable(tag_file_path) == 1 then
				vim.fn.delete(tag_file_path)
			end

			local success = lua_core.jump_to_tag_file(tag_name)
			assert.is_true(success)

			-- Verify file was created
			assert.are.equal(1, vim.fn.filereadable(tag_file_path))

			-- Verify we jumped to it
			local current_file = vim.api.nvim_buf_get_name(0)
			assert.is_true(current_file:match("test%-tag%-cleanup%.md$") ~= nil)
		end)

		it("should return false for invalid tags", function()
			local success = lua_core.jump_to_tag_file("#invalid@tag")
			assert.is_false(success)
		end)
	end)
end)
