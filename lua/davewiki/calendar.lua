---
-- @module davewiki.calendar
-- @brief Daily calendar system implementation
-- @version 1.0

local calendar = {}

---@class DavewikiCalendarConfig
---@field enabled boolean Enable calendar module

calendar.config = {
    enabled = true,
}

--- Setup calendar module
---@param config DavewikiCalendarConfig?
function calendar.setup(config)
    if config then
        calendar.config = vim.tbl_deep_extend("force", calendar.config, config)
    end
end

--- Check if calendar module is enabled
---@return boolean
function calendar.is_enabled()
    return calendar.config.enabled
end

return calendar
