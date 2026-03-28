---
-- Tests for davewiki.journal telescope integration
-- @module davewiki.journal_telescope_spec

local journal = require("davewiki.journal")
local core = require("davewiki.core")

-- Get the absolute path to test_root directory relative to this script
local test_root = vim.fn.fnamemodify(vim.fn.expand("<sfile>:h:h:h:h"), ":p") .. "test_root"

describe("davewiki.journal jump_to_journal function", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
        journal.config.enabled = true
    end)

    describe("jump_to_journal", function()
        it("should return false when telescope is not installed", function()
            -- Mock telescope module as not installed
            local original_require = _G.require
            _G.require = function(mod)
                if mod == "telescope" or mod:match("^telescope%.") then
                    error("module '" .. mod .. "' not found")
                end
                return original_require(mod)
            end

            local result = journal.jump_to_journal()

            _G.require = original_require

            assert.is_false(result)
        end)

        it("should return false when wiki_root is not set", function()
            core.wiki_root = nil
            local result = journal.jump_to_journal()
            assert.is_false(result)
        end)

        it("should return false when journal module is disabled", function()
            journal.config.enabled = false
            local result = journal.jump_to_journal()
            assert.is_false(result)
        end)
    end)

    describe("get_journals_list", function()
        it("should return list of journal files from wiki_root/journals/", function()
            local journals = journal.get_journals_list()

            assert.is_table(journals)
            -- test_root has some journal files
            assert.is_true(#journals >= 0)

            -- Each entry should be a table with required fields
            for _, entry in ipairs(journals) do
                assert.is_table(entry)
                assert.is_string(entry.file)
                assert.is_string(entry.display)
                -- File should be within journals directory
                assert.is_true(entry.file:match("/journals/") ~= nil)
                -- Should be a markdown file
                assert.is_true(entry.file:match("%.md$") ~= nil)
            end
        end)

        it("should return empty table when wiki_root is nil", function()
            core.wiki_root = nil
            local journals = journal.get_journals_list()
            assert.is_table(journals)
            assert.are.equal(0, #journals)
        end)

        it("should return empty table when journals directory does not exist", function()
            -- Temporarily set wiki_root to a directory without journals
            local original_root = core.wiki_root
            core.wiki_root = "/tmp/empty-davewiki-test-" .. os.time()
            vim.fn.mkdir(core.wiki_root, "p")

            local journals = journal.get_journals_list()

            core.wiki_root = original_root
            vim.fn.delete("/tmp/empty-davewiki-test-" .. os.time(), "rf")

            assert.is_table(journals)
            assert.are.equal(0, #journals)
        end)

        it("should use absolute paths in display", function()
            local journals = journal.get_journals_list()

            for _, entry in ipairs(journals) do
                -- Display should be the same as file (absolute path)
                assert.are.equal(entry.file, entry.display)
                -- Should be an absolute path
                assert.is_true(entry.display:match("^/") ~= nil,
                    "Display should be absolute path: " .. entry.display)
            end
        end)
    end)
end)

describe("davewiki.journal get_journals_list sorting", function()
    before_each(function()
        core.setup({ wiki_root = test_root })
    end)

    it("should return journal files sorted alphabetically", function()
        local journals = journal.get_journals_list()

        if #journals > 1 then
            for i = 2, #journals do
                assert.is_true(journals[i - 1].display <= journals[i].display,
                    "Journals should be sorted alphabetically: " ..
                    journals[i - 1].display .. " > " .. journals[i].display)
            end
        end
    end)
end)
