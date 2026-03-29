---
-- @module davewiki.view
-- @brief Synthetic tag view generation
-- @version 1.0
--
-- This module provides functionality to generate synthetic "view" files that
-- aggregate all references to a specific tag across the wiki into a single buffer.
-- The view contains:
--   - Tag file content (if exists) or "NO TAG FILE" placeholder
--   - Journal blocks containing the tag
--   - Wiki paragraphs containing the tag
-- Each section includes markdown links to source documents.

local M = {}

local core = require("davewiki.core")

--- @class TagMention
--- @field file string The file path containing the tag mention
--- @field is_journal boolean Whether this file is in the journals directory

--- @class ContentBlock
--- @field link string Markdown link to the source file
--- @field content string The extracted content (block or paragraph)

--- Gets the content of a tag file
--- @param tag_name string The tag name (with # prefix)
--- @return string|nil The content of the tag file, or "NO TAG FILE" placeholder, or nil for invalid tag
function M.get_tag_file_content(tag_name)
    if not core.is_valid_tag(tag_name) then
        return nil
    end

    local tag_file_path = core.get_tag_file_path(tag_name)
    if not tag_file_path then
        return nil
    end

    if vim.fn.filereadable(tag_file_path) == 1 then
        local lines = vim.fn.readfile(tag_file_path)
        return table.concat(lines, "\n")
    end

    return "NO TAG FILE"
end

--- Finds all unique files mentioning a tag
--- @param tag_name string The tag name (with # prefix)
--- @return table|nil Array of TagMention objects (deduplicated by file path), or nil for invalid tag
function M.find_tag_mentions(tag_name)
    if not core.is_valid_tag(tag_name) then
        return nil
    end

    if not core.wiki_root then
        return {}
    end

    -- Use ripgrep to find all occurrences
    local args = {
        "--files",
        "--type",
        "md",
        core.wiki_root,
    }

    local all_files = core.ripgrep(args)
    local mentions = {}
    local seen_files = {}

    for _, file_path in ipairs(all_files) do
        local resolved_path = vim.fn.resolve(file_path)

        -- Only process non-tag files
        if not core.is_tag_file(resolved_path) then
            -- Skip if we've already seen this file
            if not seen_files[resolved_path] then
                -- Check if this file contains the tag
                local grep_args = {
                    "--fixed-strings",
                    tag_name,
                    resolved_path,
                }
                local matches = core.ripgrep(grep_args)

                if #matches > 0 then
                    seen_files[resolved_path] = true
                    local is_journal = resolved_path:match("/journals/") ~= nil
                    table.insert(mentions, {
                        file = resolved_path,
                        is_journal = is_journal,
                    })
                end
            end
        end
    end

    return mentions
end

--- Creates a markdown link for a file path
--- @param file_path string The absolute file path
--- @param title string|nil Optional title for the link (defaults to filename)
--- @return string Markdown link
local function make_markdown_link(file_path, title)
    local relative_path = file_path:sub(#core.wiki_root + 1)
    if relative_path:sub(1, 1) ~= "/" then
        relative_path = "/" .. relative_path
    end

    local link_title = title or vim.fn.fnamemodify(file_path, ":t:r")
    local encoded_path = core.url_encode(relative_path)

    return "[" .. link_title .. "](" .. encoded_path .. ")"
end

--- Splits content into blocks separated by ---
--- @param content string The file content
--- @return table Array of blocks (strings)
local function split_into_blocks(content)
    local blocks = {}
    local current_block = {}
    for line in content:gmatch("[^\n]*") do
        if line:match("^%-%-%-$") then
            if #current_block > 0 then
                table.insert(blocks, table.concat(current_block, "\n"))
                current_block = {}
            end
        else
            table.insert(current_block, line)
        end
    end

    -- Don't forget the last block
    if #current_block > 0 then
        table.insert(blocks, table.concat(current_block, "\n"))
    end

    return blocks
end

--- Extracts a paragraph containing the tag from content
--- @param content string The file content
--- @param tag_name string The tag to find
--- @return table Array of paragraphs containing the tag
local function extract_paragraphs_with_tag(content, tag_name)
    local paragraphs = {}
    local current_para = {}

    for line in content:gmatch("[^\n]*") do
        if line:match("^%s*$") then
            if #current_para > 0 then
                local para_text = table.concat(current_para, "\n")
                if para_text:find(tag_name, 1, true) then
                    table.insert(paragraphs, para_text)
                end
                current_para = {}
            end
        else
            table.insert(current_para, line)
        end
    end

    -- Don't forget the last paragraph
    if #current_para > 0 then
        local para_text = table.concat(current_para, "\n")
        if para_text:find(tag_name, 1, true) then
            table.insert(paragraphs, para_text)
        end
    end

    return paragraphs
end

--- Extracts blocks from a single journal file mention
---@param tag_name string The tag name (with # prefix)
---@param mention table A single mention object with file path
---@return table Array of ContentBlock objects
function M.extract_journal_blocks_from_mention(tag_name, mention)
    local blocks = {}
    local content = vim.fn.readfile(mention.file)
    local file_content = table.concat(content, "\n")

    local file_blocks = split_into_blocks(file_content)

    for _, block_content in ipairs(file_blocks) do
        if block_content:find(tag_name, 1, true) then
            local filename = vim.fn.fnamemodify(mention.file, ":t:r")
            local link = make_markdown_link(mention.file, filename)
            table.insert(blocks, {
                link = link,
                content = block_content,
            })
        end
    end

    return blocks
end

--- Extracts paragraphs from a single wiki file mention
---@param tag_name string The tag name (with # prefix)
---@param mention table A single mention object with file path
---@return table Array of ContentBlock objects
function M.extract_wiki_paragraphs_from_mention(tag_name, mention)
    local paragraphs = {}
    local content = vim.fn.readfile(mention.file)
    local file_content = table.concat(content, "\n")

    local found_paras = extract_paragraphs_with_tag(file_content, tag_name)

    for _, para in ipairs(found_paras) do
        local filename = vim.fn.fnamemodify(mention.file, ":t:r")
        local link = make_markdown_link(mention.file, filename)
        table.insert(paragraphs, {
            link = link,
            content = para,
        })
    end

    return paragraphs
end

--- Extracts blocks from journal files containing the tag
---@param tag_name string The tag name (with # prefix)
---@param mentions table|nil Optional pre-computed mentions (from find_tag_mentions)
---@return table Array of ContentBlock objects
function M.extract_journal_blocks(tag_name, mentions)
    if not mentions then
        mentions = M.find_tag_mentions(tag_name)
    end

    if not mentions or #mentions == 0 then
        return {}
    end

    local blocks = {}

    for _, mention in ipairs(mentions) do
        if mention.is_journal then
            local content = vim.fn.readfile(mention.file)
            local file_content = table.concat(content, "\n")

            local file_blocks = split_into_blocks(file_content)

            for _, block_content in ipairs(file_blocks) do
                if block_content:find(tag_name, 1, true) then
                    local filename = vim.fn.fnamemodify(mention.file, ":t:r")
                    local link = make_markdown_link(mention.file, filename)
                    table.insert(blocks, {
                        link = link,
                        content = block_content,
                    })
                end
            end
        end
    end

    return blocks
end

--- Extracts paragraphs from wiki files containing the tag
---@param tag_name string The tag name (with # prefix)
---@param mentions table|nil Optional pre-computed mentions (from find_tag_mentions)
---@return table Array of ContentBlock objects
function M.extract_wiki_paragraphs(tag_name, mentions)
    if not mentions then
        mentions = M.find_tag_mentions(tag_name)
    end

    if not mentions or #mentions == 0 then
        return {}
    end

    local paragraphs = {}

    for _, mention in ipairs(mentions) do
        if not mention.is_journal then
            local content = vim.fn.readfile(mention.file)
            local file_content = table.concat(content, "\n")

            local found_paras = extract_paragraphs_with_tag(file_content, tag_name)

            for _, para in ipairs(found_paras) do
                local filename = vim.fn.fnamemodify(mention.file, ":t:r")
                local link = make_markdown_link(mention.file, filename)
                table.insert(paragraphs, {
                    link = link,
                    content = para,
                })
            end
        end
    end

    return paragraphs
end

--- Formats the view content from components
--- @param tag_name string The tag name (without # prefix)
--- @param tag_file_content string The tag file content
--- @param journal_blocks table Array of ContentBlock
--- @param wiki_paragraphs table Array of ContentBlock
--- @return table Array of lines for the buffer
local function format_view_content(tag_name, tag_file_content, journal_blocks, wiki_paragraphs)
    local lines = {}

    -- Header
    table.insert(lines, "# " .. tag_name .. " - Tag View")
    table.insert(lines, "")
    table.insert(lines, "*Synthesized view aggregating all references to #" .. tag_name .. "*")
    table.insert(lines, "")

    -- Tag file section
    table.insert(lines, "---")
    table.insert(lines, "")
    table.insert(lines, "## Tag File")
    table.insert(lines, "")
    for _, line in ipairs(vim.split(tag_file_content, "\n")) do
        table.insert(lines, line)
    end
    table.insert(lines, "")

    -- Journal blocks section
    table.insert(lines, "---")
    table.insert(lines, "")
    table.insert(lines, "## Journal Blocks")
    table.insert(lines, "")

    if #journal_blocks == 0 then
        table.insert(lines, "*No mentions in journals*")
        table.insert(lines, "")
    else
        for _, block in ipairs(journal_blocks) do
            table.insert(lines, "**" .. block.link .. "**")
            table.insert(lines, "")
            for _, line in ipairs(vim.split(block.content, "\n")) do
                table.insert(lines, line)
            end
            table.insert(lines, "")
        end
    end

    -- Wiki paragraphs section
    table.insert(lines, "---")
    table.insert(lines, "")
    table.insert(lines, "## Wiki References")
    table.insert(lines, "")

    if #wiki_paragraphs == 0 then
        table.insert(lines, "*No mentions in wiki notes*")
        table.insert(lines, "")
    else
        for _, para in ipairs(wiki_paragraphs) do
            table.insert(lines, "**" .. para.link .. "**")
            table.insert(lines, "")
            for _, line in ipairs(vim.split(para.content, "\n")) do
                table.insert(lines, line)
            end
            table.insert(lines, "")
        end
    end

    return lines
end

--- Generates a synthetic view buffer for a tag
--- @param tag_name string The tag name (with # prefix)
--- @return integer|nil The buffer number of the view buffer, or nil on failure
function M.generate_view(tag_name)
    -- Validate tag
    if not tag_name or not core.is_valid_tag(tag_name) then
        return nil
    end

    -- Validate wiki_root
    if not core.wiki_root then
        return nil
    end

    local tag_name_clean = tag_name:gsub("^#", "")
    local view_name = tag_name_clean .. "-view.md"

    -- Check if buffer already exists - reuse it
    local existing_bufnr = nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name:match(tag_name_clean .. "%-view%.md$") then
                existing_bufnr = buf
                break
            end
        end
    end

    -- Gather content
    local tag_file_content = M.get_tag_file_content(tag_name)
    if not tag_file_content then
        return nil
    end

    -- Find mentions once and extract content in a single loop
    local mentions = M.find_tag_mentions(tag_name)
    local journal_blocks = {}
    local wiki_paragraphs = {}

    for _, mention in ipairs(mentions) do
        if mention.is_journal then
            local blocks = M.extract_journal_blocks_from_mention(tag_name, mention)
            for _, block in ipairs(blocks) do
                table.insert(journal_blocks, block)
            end
        else
            local paragraphs = M.extract_wiki_paragraphs_from_mention(tag_name, mention)
            for _, para in ipairs(paragraphs) do
                table.insert(wiki_paragraphs, para)
            end
        end
    end

    -- Format view content
    local lines =
        format_view_content(tag_name_clean, tag_file_content, journal_blocks, wiki_paragraphs)

    local bufnr
    if existing_bufnr then
        -- Reuse existing buffer
        bufnr = existing_bufnr
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    else
        -- Create new buffer
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(bufnr, view_name)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
        vim.api.nvim_buf_set_option(bufnr, "buftype", "acwrite")
    end

    -- Open the buffer
    vim.api.nvim_win_set_buf(0, bufnr)

    return bufnr
end

--- Set up user commands for tag view feature
function M.setup_commands()
    -- Command to generate view from tag under cursor
    vim.api.nvim_create_user_command("DavewikiGenerateViewFromCursor", function()
        local tag = core.get_tag_under_cursor()
        if tag then
            M.generate_view(tag)
        end
    end, { desc = "Generate tag view from tag under cursor" })

    -- Command to generate view from current tag file
    vim.api.nvim_create_user_command("DavewikiGenerateViewFromTagFile", function()
        local file_path = vim.api.nvim_buf_get_name(0)
        local tag_name = core.extract_tag_from_filename(file_path)
        if tag_name then
            M.generate_view("#" .. tag_name)
        end
    end, { desc = "Generate tag view from current tag file" })
end

return M