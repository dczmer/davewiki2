---
-- Tests for davewiki.markdown markdown link and file operations
-- @module davewiki.markdown_spec

local markdown = require("davewiki.markdown")
local core = require("davewiki.core")
local test_util = require("davewiki.test_util")

local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.markdown constants", function()
    it("should have LINK_PATTERN defined", function()
        assert.is_not_nil(markdown.LINK_PATTERN)
    end)
end)

describe("davewiki.markdown get_markdown_files", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    it("should return list of markdown files excluding sources/", function()
        local files = markdown.get_markdown_files()
        assert.is_table(files)
        assert.is_true(#files > 0)

        for _, file in ipairs(files) do
            assert.is_false(
                file:match("/sources/") ~= nil,
                "Should not include sources files: " .. file
            )
        end

        local found_notes = false
        for _, file in ipairs(files) do
            if file:match("/notes/") then
                found_notes = true
                break
            end
        end
        assert.is_true(found_notes, "Should include notes/ directory files")
    end)

    it("should return empty table when wiki_root is nil", function()
        core.wiki_root = nil
        local files = markdown.get_markdown_files()
        assert.is_table(files)
        assert.are.equal(0, #files)
    end)
end)

describe("davewiki.markdown extract_h1_or_filename", function()
    it("should extract H1 heading from file", function()
        local file_path = test_root .. "/notes/baked-fish.md"
        local result = markdown.extract_h1_or_filename(file_path)
        assert.is_string(result)
        assert.is_true(#result > 0)
        assert.is_false(result:match("^#") ~= nil)
    end)

    it("should return filename if no H1 exists", function()
        local test_file = test_root .. "/test-no-h1.md"
        vim.fn.writefile({ "Some content without heading", "More text" }, test_file)

        local result = markdown.extract_h1_or_filename(test_file)

        vim.fn.delete(test_file)

        assert.are.equal("test-no-h1", result)
    end)

    it("should return nil for non-existent file", function()
        local result = markdown.extract_h1_or_filename("/nonexistent/path/file.md")
        assert.is_nil(result)
    end)

    it("should extract title from first H1 only", function()
        local test_file = test_root .. "/test-multi-h1.md"
        vim.fn.writefile({
            "# First Heading",
            "Content here",
            "# Second Heading",
            "More content",
        }, test_file)

        local result = markdown.extract_h1_or_filename(test_file)

        vim.fn.delete(test_file)

        assert.are.equal("First Heading", result)
    end)
end)

describe("davewiki.markdown get_link_under_cursor", function()
    it("should extract valid link under cursor", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "This is a [link](./file.md) in text" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 12 })

        local link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)
        assert.are.equal("./file.md", link.path)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return nil when cursor is not on a link", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "This is just regular text" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 5 })

        local link = markdown.get_link_under_cursor()
        assert.is_nil(link)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should handle links at start of line", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "[link](./file.md) at start" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)
        assert.are.equal("./file.md", link.path)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should handle multiple links on same line", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(
            buf,
            0,
            -1,
            false,
            { "Text [first](a.md) and [second](b.md) here" }
        )
        vim.api.nvim_set_current_buf(buf)

        vim.api.nvim_win_set_cursor(0, { 1, 8 })
        local link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)
        assert.are.equal("a.md", link.path)

        vim.api.nvim_win_set_cursor(0, { 1, 25 })
        link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)
        assert.are.equal("b.md", link.path)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should detect external URLs", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [website](https://example.com)" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)
        assert.are.equal("https://example.com", link.path)
        assert.is_true(link.is_url)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return link text in result", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Click [My Link](./file.md)" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 10 })

        local link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)
        assert.are.equal("./file.md", link.path)
        assert.are.equal("My Link", link.text)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should handle cursor on URL part of link", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [link](./file.md)" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 14 })

        local link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should handle absolute paths within wiki_root", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [notes](/sources/note.md)" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local link = markdown.get_link_under_cursor()
        assert.is_not_nil(link)
        assert.are.equal("/sources/note.md", link.path)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)
end)

describe("davewiki.markdown jump_to_link", function()
    local original_wiki_root
    local mock_notify
    local original_notify

    before_each(function()
        original_wiki_root = core.wiki_root
        core.setup({ wiki_root = test_root })
        mock_notify = test_util.MockNotify()
        original_notify = vim.notify
        vim.notify = function(...)
            return mock_notify:notify(...)
        end
    end)

    after_each(function()
        core.wiki_root = original_wiki_root
        vim.notify = original_notify
    end)

    it("should open relative file link that exists", function()
        local test_file = test_root .. "/test-link-target.md"
        vim.fn.writefile({ "# Test Target", "" }, test_file)

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [target](test-link-target.md)" })
        vim.api.nvim_buf_set_name(buf, test_root .. "/test-link-source.md")
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local result = markdown.jump_to_link()
        assert.is_true(result)

        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("test%-link%-target%.md$") ~= nil)

        vim.api.nvim_buf_delete(buf, { force = true })
        vim.fn.delete(test_file)
    end)

    it("should open relative link from subdirectory without ./ prefix", function()
        local notes_dir = test_root .. "/notes"
        local source_file = notes_dir .. "/raw-fish.md"
        local target_file = notes_dir .. "/relative-link-no-prefix.md"

        if vim.fn.isdirectory(notes_dir) ~= 1 then
            vim.fn.mkdir(notes_dir, "p")
        end

        if vim.fn.filereadable(target_file) == 1 then
            vim.fn.delete(target_file)
        end

        vim.fn.writefile({ "# Relative Link Test", "" }, target_file)

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(
            buf,
            0,
            -1,
            false,
            { "See [Relative Link](relative-link-no-prefix.md)" }
        )
        vim.api.nvim_buf_set_name(buf, source_file)
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local result = markdown.jump_to_link()
        assert.is_true(result)

        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("notes/relative%-link%-no%-prefix%.md$") ~= nil)

        vim.api.nvim_buf_delete(buf, { force = true })
        vim.fn.delete(target_file)
    end)

    it("should open absolute file link within wiki_root", function()
        local test_file = test_root .. "/sources/bengal.md"

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [bengal](/sources/bengal.md)" })
        vim.api.nvim_buf_set_name(buf, test_root .. "/some-file.md")
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local result = markdown.jump_to_link()
        assert.is_true(result)

        local current_file = vim.api.nvim_buf_get_name(0)
        assert.is_true(current_file:match("bengal%.md$") ~= nil)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return false for non-existent file", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [missing](./nonexistent.md)" })
        vim.api.nvim_buf_set_name(buf, test_root .. "/test-file.md")
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local result = markdown.jump_to_link()
        assert.is_false(result)
        assert.are.equal(1, #mock_notify.calls)
        assert.are.equal(
            "davewiki: file not found: " .. test_root .. "/nonexistent.md",
            mock_notify.calls[1].msg
        )
        assert.are.equal(vim.log.levels.WARN, mock_notify.calls[1].level)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should block path traversal attempts", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [escape](../../../etc/passwd)" })
        vim.api.nvim_buf_set_name(buf, test_root .. "/test-file.md")
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local result = markdown.jump_to_link()
        assert.is_false(result)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return false when not on a link", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Just regular text" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 5 })

        local result = markdown.jump_to_link()
        assert.is_false(result)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return false when wiki_root is nil", function()
        core.wiki_root = nil

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [link](./file.md)" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local result = markdown.jump_to_link()
        assert.is_false(result)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return true for external URLs", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [website](https://example.com)" })
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local original_ui_open = vim.ui.open
        local opened_url = nil
        vim.ui.open = function(url)
            opened_url = url
        end

        local result = markdown.jump_to_link()

        vim.ui.open = original_ui_open

        assert.is_true(result)
        assert.are.equal("https://example.com", opened_url)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("should return false for non-.md file extensions", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "See [image](./image.png)" })
        vim.api.nvim_buf_set_name(buf, test_root .. "/test-file2.md")
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, { 1, 8 })

        local result = markdown.jump_to_link()
        assert.is_false(result)
        assert.are.equal(1, #mock_notify.calls)
        assert.are.equal(
            "davewiki: Only .md files are supported for internal links",
            mock_notify.calls[1].msg
        )
        assert.are.equal(vim.log.levels.WARN, mock_notify.calls[1].level)

        vim.api.nvim_buf_delete(buf, { force = true })
    end)
end)

describe("davewiki.markdown get_headings_list", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    it("should return table with text, file, and lnum fields", function()
        local headings = markdown.get_headings_list()
        assert.is_table(headings)

        if #headings > 0 then
            assert.is_not_nil(headings[1].text)
            assert.is_not_nil(headings[1].file)
            assert.is_not_nil(headings[1].lnum)
        end
    end)

    it("should sort headings alphabetically", function()
        local headings = markdown.get_headings_list()
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
end)

describe("davewiki.markdown make_markdown_link", function()
    before_each(function()
        core.wiki_root = test_root
    end)

    after_each(function()
        core.wiki_root = nil
    end)

    it("should create markdown link for file within wiki_root", function()
        local result = markdown.make_markdown_link(test_root .. "/notes/file.md")
        assert.are.equal("[file](/notes/file.md)", result)
    end)

    it("should use custom title when provided", function()
        local result = markdown.make_markdown_link(test_root .. "/notes/file.md", "My Title")
        assert.are.equal("[My Title](/notes/file.md)", result)
    end)

    it("should handle files with spaces in names", function()
        local result = markdown.make_markdown_link(test_root .. "/notes/my file.md")
        assert.are.equal("[my file](/notes/my%20file.md)", result)
    end)

    it("should return nil for file outside wiki_root", function()
        local result = markdown.make_markdown_link("/etc/passwd")
        assert.is_nil(result)
    end)

    it("should return nil when wiki_root is nil", function()
        core.wiki_root = nil
        local result = markdown.make_markdown_link("/any/path")
        assert.is_nil(result)
    end)
end)
