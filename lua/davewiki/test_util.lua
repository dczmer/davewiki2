---
-- Test utilities for davewiki tests.
-- @module davewiki.test_util

local M = {}

--- MockNotify class for tracking vim.notify calls in tests.
--- Each instance maintains its own isolated call history.
--- @class MockNotify
--- @field calls table[] List of recorded calls: {msg, level, opts}

local MockNotify = {}
MockNotify.__index = MockNotify

--- Records a notify call.
--- @param msg string The message
--- @param level integer|nil Log level (vim.log.levels)
--- @param opts table|nil Optional options
function MockNotify:notify(msg, level, opts)
    table.insert(self.calls, { msg = msg, level = level, opts = opts })
end

--- Clear all recorded calls.
function MockNotify:clear()
    self.calls = {}
end

--- Create a new MockNotify instance.
--- @return MockNotify
function M.MockNotify()
    return setmetatable({ calls = {} }, MockNotify)
end

return M
