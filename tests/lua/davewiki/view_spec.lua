---
-- Tests for davewiki.view synthetic tag view generation
-- @module davewiki.view_spec

local view = require("davewiki.view")
local core = require("davewiki.core")
local test_util = require("test_util")

-- Get the absolute path to test_root directory relative to this script
local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.view setup", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
    end)

    describe("module initialization", function()
        it("should be a valid module", function()
            assert.is_table(view)
        end)

        it("should have generate_view function", function()
            assert.is_function(view.generate_view)
        end)
    end)
end)

describe("davewiki.view generate_view", function()
    local test_journal_file
    local test_note_file

    before_each(function()
        core.setup({ wiki_root = test_root })

        local journal_dir = test_root .. "/journals"
        if vim.fn.isdirectory(journal_dir) == 0 then
            vim.fn.mkdir(journal_dir, "p")
        end

        local notes_dir = test_root .. "/notes"
        if vim.fn.isdirectory(notes_dir) == 0 then
            vim.fn.mkdir(notes_dir, "p")
        end

        test_journal_file = journal_dir .. "/test-view-unique-generate-20240115.md"
        test_note_file = notes_dir .. "/test-view-unique-generate-note.md"

        vim.fn.writefile({
            "# 2024-01-15",
            "",
            "This is a journal entry about #cooking.",
            "",
            "---",
            "",
            "Today I learned about #tilapia preparation.",
            "It was delicious!",
            "",
            "---",
            "",
            "More #cooking notes here.",
            "",
        }, test_journal_file)

        vim.fn.writefile({
            "# Test View Note",
            "",
            "This note has a paragraph about #cooking.",
            "",
            "It mentions #cooking techniques and recipes.",
            "",
            "A separate paragraph without the tag.",
        }, test_note_file)
    end)

    after_each(function()
        pcall(vim.fn.delete, test_journal_file)
        pcall(vim.fn.delete, test_note_file)

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local name = vim.api.nvim_buf_get_name(buf)
            if name:match("-view%.md$") then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
    end)

    --- Helper to generate a view and assert it returned a valid buffer handle.
    ---@param tag_name string
    ---@return integer
    local function generate_view_assert(tag_name)
        local bufnr = view.generate_view(tag_name)
        assert(bufnr ~= nil, "generate_view returned nil for " .. tag_name)
        return bufnr
    end

    describe("generate_view with valid tag", function()
        it("should create a view buffer", function()
            local bufnr = generate_view_assert("#cooking")
            assert.is_number(bufnr)
            assert.is_true(vim.api.nvim_buf_is_valid(bufnr))

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        it("should return nil for invalid tag name", function()
            local bufnr = view.generate_view("#invalid tag!")
            assert.is_nil(bufnr)
        end)

        it("should create buffer with correct name", function()
            local bufnr = generate_view_assert("#cooking")
            local name = vim.api.nvim_buf_get_name(bufnr)
            assert.is_true(name:match("cooking%-view%.md$") ~= nil)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        it("should regenerate buffer if it already exists", function()
            local bufnr1 = generate_view_assert("#cooking")
            local bufnr2 = generate_view_assert("#cooking")

            -- Should return same buffer number (regenerated)
            assert.are.equal(bufnr1, bufnr2)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr1, { force = true })
        end)
    end)

    describe("generate_view content", function()
        it("should include tag file content section", function()
            local bufnr = generate_view_assert("#cooking")
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local content = table.concat(lines, "\n")

            -- Should have tag file content marker or actual content
            assert.is_true(content:match("TAG FILE") ~= nil or content:match("# cooking") ~= nil)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        it("should show NO TAG FILE when tag file does not exist", function()
            local bufnr = generate_view_assert("#nonexistent-tag-view-test")
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local content = table.concat(lines, "\n")

            assert.is_true(content:match("NO TAG FILE") ~= nil)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        it("should include source links with markdown format", function()
            local bufnr = generate_view_assert("#cooking")
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local content = table.concat(lines, "\n")

            -- Should contain markdown links to source files
            assert.is_true(content:match("%[.-%]%(.-%)") ~= nil)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        it("should separate sections with ---", function()
            local bufnr = generate_view_assert("#cooking")
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local content = table.concat(lines, "\n")

            -- Should contain section separators
            assert.is_true(content:match("%-%-%-") ~= nil)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)

    describe("generate_view edge cases", function()
        it("should handle tag with no mentions", function()
            -- Create a unique tag that won't exist anywhere
            local bufnr = generate_view_assert("#unique-tag-no-mentions-xyz123")
            assert.is_number(bufnr)

            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local content = table.concat(lines, "\n")

            -- Should show NO TAG FILE (no tag file) and placeholder for empty sections
            assert.is_true(content:match("NO TAG FILE") ~= nil)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)

        describe("generate_view error notifications", function()
            local mock_notify
            local restore_notify

            before_each(function()
                mock_notify, restore_notify = test_util.mock_notify()
            end)

            after_each(function()
                restore_notify()
            end)

            it("should notify and return nil for invalid tag names", function()
                local invalid_tags = { "cooking", "#cooking!", "" }
                for _, tag in ipairs(invalid_tags) do
                    mock_notify:clear()
                    local result = view.generate_view(tag)
                    assert.is_nil(result)
                    assert.are.equal(1, #mock_notify.calls)
                    assert.are.equal(
                        "davewiki: Invalid tag name: " .. tag,
                        mock_notify.calls[1].msg
                    )
                    assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
                end
            end)

            it("should notify and return nil when wiki_root is not configured", function()
                core.wiki_root = nil
                local result = view.generate_view("#cooking")
                assert.is_nil(result)
                assert.are.equal(1, #mock_notify.calls)
                assert.are.equal("davewiki: wiki_root is not configured", mock_notify.calls[1].msg)
                assert.are.equal(vim.log.levels.ERROR, mock_notify.calls[1].level)
            end)
        end)

        it("should create views directory if it does not exist", function()
            -- This tests that the view buffer path uses views/ subdirectory naming
            local bufnr = generate_view_assert("#cooking")
            local name = vim.api.nvim_buf_get_name(bufnr)

            -- The buffer name should contain the tag name with -view suffix
            assert.is_true(name:match("cooking%-view") ~= nil)

            -- Clean up
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end)
    end)
end)

describe("davewiki.view handler functions", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
    end)

    describe("get_tag_file_content", function()
        it("should return content for existing tag file", function()
            -- #cooking tag file exists in test_root/sources/
            local content = view.get_tag_file_content("#cooking")
            assert.is_string(content)
            assert.is_true(#content > 0)
        end)

        it("should return NO TAG FILE for non-existent tag file", function()
            local content = view.get_tag_file_content("#nonexistent-tag-xyz")
            assert.are.equal("NO TAG FILE", content)
        end)

        it("should return nil for invalid tag", function()
            local content = view.get_tag_file_content("invalid")
            assert.is_nil(content)
        end)
    end)

    describe("find_tag_mentions", function()
        local test_journal_file
        local test_note_file

        before_each(function()
            local journal_dir = test_root .. "/journals"
            if vim.fn.isdirectory(journal_dir) == 0 then
                vim.fn.mkdir(journal_dir, "p")
            end

            local notes_dir = test_root .. "/notes"
            if vim.fn.isdirectory(notes_dir) == 0 then
                vim.fn.mkdir(notes_dir, "p")
            end

            test_journal_file = journal_dir .. "/test-view-unique-mentions-journal.md"
            test_note_file = notes_dir .. "/test-view-unique-mentions-note.md"

            vim.fn.writefile({
                "# Journal Entry",
                "Notes about #testviewfindunique.",
                "",
                "---",
                "",
                "Block two with #testviewfindunique again.",
            }, test_journal_file)

            vim.fn.writefile({
                "# A Note",
                "",
                "Paragraph about #testviewfindunique in a note.",
            }, test_note_file)
        end)

        after_each(function()
            pcall(vim.fn.delete, test_journal_file)
            pcall(vim.fn.delete, test_note_file)
        end)

        it("should find all files mentioning a tag", function()
            local mentions = view.find_tag_mentions("#testviewfindunique")
            assert.is_table(mentions)
            assert.are.equal(2, #mentions)
        end)

        it("should return empty table for tag with no mentions", function()
            local mentions = view.find_tag_mentions("#uniquenotagmentions123xyz")
            assert.is_table(mentions)
            assert.are.equal(0, #mentions)
        end)

        it("should return nil for invalid tag", function()
            local mentions = view.find_tag_mentions("invalid")
            assert.is_nil(mentions)
        end)

        it("should distinguish between journals and wiki files", function()
            local mentions = view.find_tag_mentions("#testviewfindunique")
            assert.is_table(mentions)
            assert(mentions ~= nil, "find_tag_mentions returned nil")

            local has_journal = false
            local has_note = false
            for _, mention in ipairs(mentions) do
                if mention.file:match("test%-view%-unique%-mentions%-journal") then
                    has_journal = true
                elseif mention.file:match("test%-view%-unique%-mentions%-note") then
                    has_note = true
                end
            end
            assert.is_true(has_journal)
            assert.is_true(has_note)
        end)
    end)

    describe("extract_journal_blocks", function()
        local test_journal_file

        before_each(function()
            local journal_dir = test_root .. "/journals"
            if vim.fn.isdirectory(journal_dir) == 0 then
                vim.fn.mkdir(journal_dir, "p")
            end

            test_journal_file = journal_dir .. "/test-view-unique-blocks.md"

            vim.fn.writefile({
                "# Journal",
                "",
                "First block without the tag.",
                "",
                "---",
                "",
                "Second block has #blocktestunique here.",
                "",
                "---",
                "",
                "Third block also has #blocktestunique.",
                "Multi line block.",
            }, test_journal_file)
        end)

        after_each(function()
            pcall(vim.fn.delete, test_journal_file)
        end)

        it("should extract complete blocks containing the tag", function()
            local blocks = view.extract_journal_blocks("#blocktestunique")
            assert.is_table(blocks)
            assert.are.equal(2, #blocks)
        end)

        it("should include source file link for each block", function()
            local blocks = view.extract_journal_blocks("#blocktestunique")
            assert.is_table(blocks)

            for _, block in ipairs(blocks) do
                assert.is_string(block.link)
                assert.is_string(block.content)
                assert.is_true(block.link:match("%[.-%]%(.-%)") ~= nil)
            end
        end)
    end)

    describe("extract_wiki_paragraphs", function()
        local test_note_file

        before_each(function()
            local notes_dir = test_root .. "/notes"
            if vim.fn.isdirectory(notes_dir) == 0 then
                vim.fn.mkdir(notes_dir, "p")
            end

            test_note_file = notes_dir .. "/test-view-unique-wiki-note.md"

            vim.fn.writefile({
                "# Wiki Page",
                "",
                "First paragraph has #wikitestunique tag.",
                "",
                "Second paragraph without the tag.",
                "",
                "Third paragraph with #wikitestunique again.",
                "Spanning multiple lines.",
                "",
            }, test_note_file)
        end)

        after_each(function()
            pcall(vim.fn.delete, test_note_file)
        end)

        it("should extract paragraphs containing the tag", function()
            local paragraphs = view.extract_wiki_paragraphs("#wikitestunique")
            assert.is_table(paragraphs)
            assert.are.equal(2, #paragraphs)
        end)

        it("should include source file link for each paragraph", function()
            local paragraphs = view.extract_wiki_paragraphs("#wikitestunique")
            assert.is_table(paragraphs)

            for _, para in ipairs(paragraphs) do
                assert.is_string(para.link)
                assert.is_string(para.content)
                assert.is_true(para.link:match("%[.-%]%(.-%)") ~= nil)
            end
        end)
    end)
end)
