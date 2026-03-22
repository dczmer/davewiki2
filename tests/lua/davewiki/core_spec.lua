---
-- Tests for davewiki.core wiki_root resolution
-- @module davewiki.core_spec

local lua_core = require("davewiki.core")

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
