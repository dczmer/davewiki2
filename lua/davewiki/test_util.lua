---
-- Test utilities for davewiki tests.
-- @module davewiki.test_util

local M = {}

--- MockNotify class for tracking vim.notify calls in tests.
--- Each instance maintains its own isolated call history.
--- @class MockNotify
--- @field calls table[] List of recorded calls: {msg, level, opts}
--- @field notify fun(self: MockNotify, msg: string, level: integer|nil, opts: table|nil)
--- @field clear fun(self: MockNotify)

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

--- Mock vim.notify for tests and return a MockNotify instance plus a restore function.
--- @return MockNotify
--- @return function
function M.mock_notify()
    local original = vim.notify
    local mock = M.MockNotify()
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(...)
        return mock:notify(...)
    end
    return mock,
        function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.notify = original
        end
end

--- Temporarily make core.is_telescope_installed return false.
--- Returns a function that restores the original implementation.
--- @param core table
--- @return function
function M.with_telescope_uninstalled(core)
    local original = core.is_telescope_installed
    ---@diagnostic disable-next-line: duplicate-set-field
    core.is_telescope_installed = function()
        return false
    end
    return function()
        ---@diagnostic disable-next-line: duplicate-set-field
        core.is_telescope_installed = original
    end
end

--- Mock vim.ui.open and return a tracker plus a restore function.
--- The tracker has an `opened_url` field.
--- @return { opened_url: string|nil }
--- @return function
function M.mock_ui_open()
    local mock = { opened_url = nil }
    local original = vim.ui.open
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.open = function(url)
        mock.opened_url = url
    end
    return mock,
        function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.open = original
        end
end

return M
