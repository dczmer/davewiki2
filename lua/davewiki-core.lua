local M = {}

--- Executes a ripgrep command and returns the matching lines.
--- Uses vim.system() to avoid shell injection vulnerabilities.
--- @param args table Array of string arguments to pass to ripgrep
--- @return table Array of matching lines from ripgrep output, or empty table on failure
M.ripgrep = function(args)
    local result = vim.system({ "rg", unpack(args) }, { text = true }):wait()

    if result.code ~= 0 then
        return {}
    end

    local lines = {}
    for line in result.stdout:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    return lines
end

return M
