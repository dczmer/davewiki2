---
-- Tests for davewiki.tags tag file management
-- @module davewiki.tags_spec

local tags = require("davewiki.tags")
local core = require("davewiki.core")

local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.tags constants", function()
    it("should have TAG_PATTERN defined", function()
        assert.is_not_nil(tags.TAG_PATTERN)
        assert.are.equal("#[A-Za-z0-9-_]+", tags.TAG_PATTERN)
    end)
end)

describe("davewiki.tags create_frontmatter", function()
    it("should strip # prefix from tag name", function()
        local fm = tags.create_frontmatter("#test-tag")
        assert.are.equal("test-tag", fm.name)
    end)

    it("should work with tag name without # prefix", function()
        local fm = tags.create_frontmatter("test-tag")
        assert.are.equal("test-tag", fm.name)
    end)

    it("should set created date to current date", function()
        local fm = tags.create_frontmatter("#test")
        assert.is_true(fm.created:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil)
    end)

    it("should return table with name and created fields", function()
        local fm = tags.create_frontmatter("#test")
        assert.is_not_nil(fm.name)
        assert.is_not_nil(fm.created)
    end)
end)

describe("davewiki.tags scan_for_tags", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    it("should find all tags in test files", function()
        local tag_list = tags.scan_for_tags()
        assert.is_table(tag_list)
        assert.is_true(#tag_list > 0)
    end)

    it("should return objects with tag, count, and files fields", function()
        local tag_list = tags.scan_for_tags()
        assert.is_table(tag_list)
        assert.is_true(#tag_list > 0)
        assert.is_not_nil(tag_list[1].tag)
        assert.is_not_nil(tag_list[1].count)
        assert.is_not_nil(tag_list[1].files)
        assert.is_number(tag_list[1].count)
        assert.is_table(tag_list[1].files)
    end)

    it("should sort results by count descending", function()
        local tag_list = tags.scan_for_tags()
        for i = 2, #tag_list do
            assert.is_true(tag_list[i -1].count >= tag_list[i].count)
        end
    end)

    it("should track unique files per tag", function()
        local tag_list = tags.scan_for_tags()
        for _, tag_data in ipairs(tag_list) do
            local file_set = {}
            for _, file in ipairs(tag_data.files) do
                assert.is_nil(file_set[file])
                file_set[file] = true
            end
        end
    end)

    it("should not find invalid tags", function()
        local tag_list = tags.scan_for_tags()
        for _, tag_data in ipairs(tag_list) do
            assert.is_false(tag_data.tag:match("@") ~= nil)
            assert.is_false(tag_data.tag:match("#.+#") ~= nil)
        end
    end)
end)

describe("davewiki.tags find_tag_files", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    it("should find existing tag files in sources/", function()
        local tag_files = tags.find_tag_files()
        assert.is_table(tag_files)
        assert.is_true(#tag_files > 0)
    end)

    it("should return empty table when no tag files exist", function()
        local original_root = core.wiki_root
        core.wiki_root = "/tmp/nonexistent-davewiki-test"
        local tag_files = tags.find_tag_files()
        assert.are.equal(0, #tag_files)
        core.wiki_root = original_root
    end)

    it("should return empty table when wiki_root is nil", function()
        local original = core.wiki_root
        core.wiki_root = nil
        local files = tags.find_tag_files()
        assert.are.equal(0, #files)
        core.wiki_root = original
    end)
end)

describe("davewiki.tags create_tag_file", function()
    before_each(function()
        core.wiki_root = test_root
        vim.g.davewiki_wiki_root = nil
    end)

    after_each(function()
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

    it("should open buffer with proper frontmatter content", function()
        local tag_name = "#test-tag-cleanup"
        local success = tags.create_tag_file(tag_name)
        assert.is_true(success)

        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content_str = table.concat(lines, "\n")

        assert.is_true(content_str:match("^---") ~= nil)
        assert.is_true(content_str:match("name: test%-tag%-cleanup") ~= nil)
        assert.is_true(content_str:match("created: %d%d%d%d%-%d%d%-%d%d") ~= nil)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should open existing file", function()
        local tag_name = "#test-tag-cleanup"
        local tag_file_path = test_root .. "/sources/test-tag-cleanup.md"

        vim.fn.writefile(
            { "---", "name: test-tag-cleanup", "created: 2024-01-01", "---", "", "# Test" },
            tag_file_path
        )

        local success = tags.create_tag_file(tag_name)
        assert.is_true(success)

        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content_str = table.concat(lines, "\n")
        assert.is_true(content_str:match("name: test%-tag%-cleanup") ~= nil)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should not create tag file outside wiki_root", function()
        local success = tags.create_tag_file("#../../../etc/passwd")
        assert.is_false(success)
    end)

    it("should reject tags with path separators", function()
        assert.is_false(tags.create_tag_file("#test/../escape"))
        assert.is_false(tags.create_tag_file("#test/./escape"))
        assert.is_false(tags.create_tag_file("#test\\escape"))
    end)

    it("should reject empty tag name", function()
        assert.is_false(tags.create_tag_file("#"))
    end)
end)

describe("davewiki.tags validate_frontmatter", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    after_each(function()
        local test_patterns = {
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

    it("should return violations for files with missing frontmatter", function()
        local test_file = test_root .. "/sources/no-frontmatter-test.md"
        vim.fn.writefile({ "# Test", "Content" }, test_file)

        local violations = tags.validate_frontmatter()
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

        local violations = tags.validate_frontmatter()
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

        local violations = tags.validate_frontmatter()
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
        local test_file = test_root .. "/sources/valid-test-cleanup.md"
        vim.fn.writefile({
            "---",
            "name: valid-test-cleanup",
            "created: 2024-01-01",
            "---",
            "",
            "# Valid Test",
        }, test_file)

        local violations = tags.validate_frontmatter()

        for _, v in ipairs(violations) do
            assert.is_false(v.file == test_file)
        end
    end)

    it("should dynamically check fields from template", function()
        local test_file = test_root .. "/sources/frontmatter-test-tag.md"
        local frontmatter = tags.create_frontmatter("#frontmatter-test-tag")

        local content = {
            "---",
            "name: " .. frontmatter.name,
            "---",
        }
        vim.fn.writefile(content, test_file)

        local violations = tags.validate_frontmatter()
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

describe("davewiki.tags get_tag_under_cursor", function()
    it("should extract valid tag under cursor", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "This is a #test-tag in text" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 10 })

        local tag = tags.get_tag_under_cursor()
        assert.are.equal("#test-tag", tag)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return nil when cursor is not on a tag", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "This is just regular text" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 5 })

        local tag = tags.get_tag_under_cursor()
        assert.is_nil(tag)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should handle tags at start of line", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "#tag at start" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        local tag = tags.get_tag_under_cursor()
        assert.are.equal("#tag", tag)
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should handle multiple tags on same line", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Text #first and #second here" })
        vim.api.nvim_set_current_buf(buf)

        vim.api.nvim_win_set_cursor(0, { 1, 8 })
        local tag = tags.get_tag_under_cursor()
        assert.are.equal("#first", tag)

        vim.api.nvim_win_set_cursor(0, { 1, 18 })
        tag = tags.get_tag_under_cursor()
        assert.are.equal("#second", tag)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)
end)

describe("davewiki.tags jump_to_tag_file", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    it("should jump to existing tag file", function()
        local tag_name = "#bengal"
        local success = tags.jump_to_tag_file(tag_name)
        assert.is_true(success)
        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("bengal%.md$") ~= nil)
    end)

    it("should open buffer for non-existing tag file", function()
        local tag_name = "#test-tag-cleanup"

        local tag_file_path = test_root .. "/sources/test-tag-cleanup.md"
        if vim.fn.filereadable(tag_file_path) == 1 then
            vim.fn.delete(tag_file_path)
        end

        local success = tags.jump_to_tag_file(tag_name)
        assert.is_true(success)

        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("test%-tag%-cleanup%.md$") ~= nil)

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local content_str = table.concat(lines, "\n")
        assert.is_true(content_str:match("name: test%-tag%-cleanup") ~= nil)
    end)

    it("should return false for invalid tags", function()
        local success = tags.jump_to_tag_file("#invalid@tag")
        assert.is_false(success)
    end)
end)

describe("davewiki.tags extract_tag_from_filename", function()
    it("should extract tag name from tag file path", function()
        local tag = tags.extract_tag_from_filename(test_root .. "/sources/bengal.md")
        assert.are.equal("bengal", tag)
    end)

    it("should handle hyphenated tag names", function()
        local tag = tags.extract_tag_from_filename(test_root .. "/sources/test-tag-name.md")
        assert.are.equal("test-tag-name", tag)
    end)

    it("should handle underscore tag names", function()
        local tag = tags.extract_tag_from_filename(test_root .. "/sources/test_tag_name.md")
        assert.are.equal("test_tag_name", tag)
    end)

    it("should return nil for files outside sources/", function()
        local tag = tags.extract_tag_from_filename(test_root .. "/notes/fish-types.md")
        assert.is_nil(tag)
    end)

    it("should return nil for non-markdown files", function()
        local tag = tags.extract_tag_from_filename(test_root .. "/sources/bengal.txt")
        assert.is_nil(tag)
    end)

    it("should return nil for nil path", function()
        local tag = tags.extract_tag_from_filename(nil)
        assert.is_nil(tag)
    end)
end)

describe("davewiki.tags extract_summary", function()
    it("should return full line if under 80 characters", function()
        local line = "Short line with #tag"
        local summary = tags.extract_summary(line, 17, 80)
        assert.are.equal(line, summary)
    end)

    it("should truncate to 80 characters", function()
        local line = string.rep("a", 100) .. " #tag " .. string.rep("b", 100)
        local summary = tags.extract_summary(line, 101, 80)
        assert.are.equal(80, #summary)
    end)

    it("should ensure tag is visible in summary", function()
        local line = string.rep("a", 100) .. " #important-tag " .. string.rep("b", 100)
        local tag_col = 101
        local summary = tags.extract_summary(line, tag_col, 80)
        assert.is_true(summary:match("#important%-tag") ~= nil)
    end)

    it("should handle tag at start of line", function()
        local line = "#tag is at the start of this very long line " .. string.rep("x", 100)
        local summary = tags.extract_summary(line, 0, 80)
        assert.is_true(summary:match("^#tag") ~= nil)
        assert.are.equal(80, #summary)
    end)

    it("should handle tag at end of line", function()
        local line = string.rep("x", 100) .. " this has #tag"
        local summary = tags.extract_summary(line, 106, 80)
        assert.is_true(summary:match("#tag$") ~= nil)
        assert.are.equal(80, #summary)
    end)

    it("should use default max_length of 80", function()
        local line = string.rep("x", 200)
        local summary = tags.extract_summary(line, 100)
        assert.are.equal(80, #summary)
    end)
end)

describe("davewiki.tags format_quickfix_entry", function()
    it("should format entry with all fields", function()
        local entry = tags.format_quickfix_entry(
            "/path/to/file.md",
            42,
            10,
            "This line has #bengal in it",
            "#bengal"
        )
        assert.are.equal("/path/to/file.md", entry.filename)
        assert.are.equal(42, entry.lnum)
        assert.are.equal(10, entry.col)
        assert.are.equal("This line has #bengal in it", entry.text)
    end)

    it("should truncate text to 80 chars", function()
        local long_line = string.rep("x", 100) .. " #tag " .. string.rep("y", 100)
        local entry = tags.format_quickfix_entry("/path/file.md", 1, 101, long_line, "#tag")
        assert.are.equal(80, #entry.text)
        assert.is_true(entry.text:match("#tag") ~= nil)
    end)
end)

describe("davewiki.tags find_backlinks", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    after_each(function()
        local test_patterns = {
            test_root .. "/notes/backlink-test-*.md",
        }
        for _, pattern in ipairs(test_patterns) do
            local files = vim.fn.glob(pattern, false, true)
            for _, file in ipairs(files) do
                vim.fn.delete(file)
            end
        end
    end)

    it("should find references to tag in other files", function()
        local notes_dir = test_root .. "/notes"
        if vim.fn.isdirectory(notes_dir) ~= 1 then
            vim.fn.mkdir(notes_dir, "p")
        end
        local test_file = notes_dir .. "/backlink-test-ref.md"
        vim.fn.writefile({
            "# Test Note",
            "",
            "This mentions #bengal in the content.",
        }, test_file)

        local backlinks = tags.find_backlinks("#bengal")

        vim.fn.delete(test_file)

        assert.is_table(backlinks)
        assert.is_true(#backlinks >= 1)

        local found = false
        for _, backlink in ipairs(backlinks) do
            if backlink.file:match("backlink%-test%-ref%.md$") then
                found = true
                assert.are.equal(3, backlink.lnum)
                assert.is_true(backlink.col > 0)
                assert.is_string(backlink.line)
                break
            end
        end
        assert.is_true(found)
    end)

    it("should return empty table when no references found", function()
        local backlinks = tags.find_backlinks("#nonexistent-tag-xyz123")
        assert.is_table(backlinks)
        assert.are.equal(0, #backlinks)
    end)

    it("should return empty table when wiki_root is nil", function()
        core.wiki_root = nil
        local backlinks = tags.find_backlinks("#bengal")
        assert.is_table(backlinks)
        assert.are.equal(0, #backlinks)
    end)

    it("should find multiple references in same file", function()
        local notes_dir = test_root .. "/notes"
        if vim.fn.isdirectory(notes_dir) ~= 1 then
            vim.fn.mkdir(notes_dir, "p")
        end
        local test_file = notes_dir .. "/backlink-test-multi.md"
        vim.fn.writefile({
            "# Multi Reference Test",
            "",
            "First #bengal here.",
            "Second #bengal there.",
            "Third #bengal everywhere!",
        }, test_file)

        local backlinks = tags.find_backlinks("#bengal")

        vim.fn.delete(test_file)

        local count = 0
        for _, backlink in ipairs(backlinks) do
            if backlink.file:match("backlink%-test%-multi%.md$") then
                count = count + 1
            end
        end
        assert.are.equal(3, count)
    end)
end)