---
-- Tests for davewiki highlight pattern
-- @module davewiki.highlight_spec

local core = require("davewiki.core")

describe("core.TAG_PATTERN", function()
    it("should be exported as a module variable", function()
        assert.is_not_nil(core.TAG_PATTERN)
        assert.are.equal("#[A-Za-z0-9-_]+", core.TAG_PATTERN)
    end)

    describe("valid tag patterns (should match)", function()
        local valid_cases = {
            { input = "#tag", description = "simple tag" },
            { input = "#my-tag", description = "tag with hyphen" },
            { input = "#my_tag", description = "tag with underscore" },
            { input = "#tag123", description = "tag with numbers" },
            { input = "#123", description = "numeric tag" },
            { input = "#a-b-c", description = "multiple hyphens" },
            { input = "#a_b_c", description = "multiple underscores" },
            { input = "#TAG", description = "uppercase tag" },
            { input = "#Tag-Name_123", description = "mixed case with hyphen, underscore, and numbers" },
        }

        for _, case in ipairs(valid_cases) do
            it(string.format("should match %s: '%s'", case.description, case.input), function()
                local match = case.input:match("^" .. core.TAG_PATTERN .. "$")
                assert.is_not_nil(match, string.format("Expected '%s' to match pattern", case.input))
            end)
        end
    end)

    describe("invalid tag patterns (should NOT match)", function()
        local invalid_cases = {
            { input = "tag", description = "missing hash prefix" },
            { input = "#", description = "hash only" },
            { input = "# tag", description = "space after hash" },
            { input = "#tag name", description = "space in tag" },
            { input = "#tag#tag", description = "double hash (invalid combined)" },
            { input = "#tag$invalid", description = "special character $" },
            { input = "#tag@invalid", description = "special character @" },
            { input = "#tag!invalid", description = "special character !" },
            { input = "#tag%invalid", description = "special character %" },
            { input = "#tag^invalid", description = "special character ^" },
            { input = "#tag&invalid", description = "special character &" },
            { input = "#tag*invalid", description = "special character *" },
            { input = "#tag(invalid", description = "special character (" },
            { input = "#tag)invalid", description = "special character )" },
            { input = "#tag+invalid", description = "special character +" },
            { input = "#tag=invalid", description = "special character =" },
            { input = "#tag[invalid", description = "special character [" },
            { input = "#tag]invalid", description = "special character ]" },
            { input = "#tag{invalid", description = "special character {" },
            { input = "#tag}invalid", description = "special character }" },
            { input = "#tag|invalid", description = "special character |" },
            { input = "#tag:invalid", description = "special character :" },
            { input = "#tag;invalid", description = "special character ;" },
            { input = "#tag'invalid", description = "special character '" },
            { input = "#tag\"invalid", description = "special character \"" },
            { input = "#tag<invalid", description = "special character <" },
            { input = "#tag>invalid", description = "special character >" },
            { input = "#tag/invalid", description = "special character /" },
            { input = "#tag?invalid", description = "special character ?" },
            { input = "#tag,invalid", description = "special character ," },
            { input = "#tag.invalid", description = "special character ." },
        }

        for _, case in ipairs(invalid_cases) do
            it(string.format("should NOT match %s: '%s'", case.description, case.input), function()
                local match = case.input:match("^" .. core.TAG_PATTERN .. "$")
                assert.is_nil(match, string.format("Expected '%s' to NOT match pattern", case.input))
            end)
        end
    end)

    describe("partial matches (should match portion only)", function()
        it("should match the first tag in '#tag some text'", function()
            local match = ("#tag some text"):match(core.TAG_PATTERN)
            assert.are.equal("#tag", match)
        end)

        it("should match tag in middle of 'text #tag more'", function()
            local match = ("text #tag more"):match(core.TAG_PATTERN)
            assert.are.equal("#tag", match)
        end)

        it("should match tag at end of 'text #tag'", function()
            local match = ("text #tag"):match(core.TAG_PATTERN)
            assert.are.equal("#tag", match)
        end)
    end)
end)
