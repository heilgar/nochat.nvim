local M = {}

local output_buffer = nil
local input_buffer = nil

M.get_output_buffer = function()
    if not output_buffer or not vim.api.nvim_buf_is_valid(output_buffer) then
        output_buffer = M.create_output_buffer()
    end
    return output_buffer
end

M.get_input_buffer = function()
    if not input_buffer or not vim.api.nvim_buf_is_valid(input_buffer) then
        input_buffer = M.create_input_buffer()
    end
    return input_buffer
end

M.create_output_buffer = function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buffer, 'filetype', 'markdown')
    vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
    return buffer
end

M.create_input_buffer = function()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buffer, 'filetype', 'markdown')
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "" })
    return buffer
end

M.ensure_buffers = function()
    return {
        output_buffer = M.get_output_buffer(),
        input_buffer = M.get_input_buffer()
    }
end

M.apply_window_options = function(win_id, is_input)
    vim.wo[win_id].wrap = true
    vim.wo[win_id].linebreak = true
    vim.wo[win_id].breakindent = true

    if not is_input then
        vim.wo[win_id].cursorline = true
        vim.wo[win_id].conceallevel = 2 -- Hide markdown syntax for better reading
        vim.wo[win_id].foldenable = false
        vim.wo[win_id].signcolumn = "no"
    end
end

M.update_output = function(buffer, content)
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return
    end

    vim.api.nvim_buf_set_option(buffer, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, content)
    vim.api.nvim_buf_set_option(buffer, 'modifiable', false)

    local window = M.find_window_with_buffer(buffer)
    if window then
        local line_count = vim.api.nvim_buf_line_count(buffer)
        vim.api.nvim_win_set_cursor(window, { line_count, 0 })
    end
end

M.find_window_with_buffer = function(buffer)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buffer then
            return win
        end
    end
    return nil
end

M.format_conversation = function(conversation, provider, model, title, show_typing)
    local lines = {}

    -- Add header
    table.insert(lines, "# " .. (title or "NoChat") .. " - " .. provider .. " / " .. model)
    table.insert(lines, "")

    -- Track if we've already added an assistant message
    local has_assistant = false

    -- Process messages
    for i, message in ipairs(conversation) do
        -- Check if this is a streaming message with a final version next
        local is_temp_streaming = message.role == "assistant" and message.streaming and
            i < #conversation and
            conversation[i + 1].role == "assistant" and
            not conversation[i + 1].streaming

        -- Skip temporary streaming messages that have a final version next
        if not is_temp_streaming then
            table.insert(lines, "## " .. message.role:gsub("^%l", string.upper))

            if message.streaming then
                table.insert(lines, "*(typing...)*")
            end

            table.insert(lines, "")

            for _, line in ipairs(vim.split(message.content, "\n")) do
                table.insert(lines, line)
            end

            table.insert(lines, "")
            table.insert(lines, "---")
            table.insert(lines, "")

            if message.role == "assistant" then
                has_assistant = true
            end
        end
    end

    -- Add typing indicator if requested and no assistant message is already typing
    if show_typing and not has_assistant then
        table.insert(lines, "## Assistant")
        table.insert(lines, "*(typing...)*")
        table.insert(lines, "")
    end

    return lines
end


M.setup_syntax = function(buffer)
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return
    end

    local syntax_cmds = {
        -- Headers
        "syntax match NoChatTitle /^#.*/",
        "syntax match NoChatUserHeader /^## User$/",
        "syntax match NoChatAssistantHeader /^## Assistant$/",
        "syntax match NoChatSystemHeader /^## System$/",

        -- Code blocks
        "syntax region NoChatCodeBlock start=/```/ end=/```/ keepend",

        -- Separators
        "syntax match NoChatSeparator /^---$/",

        -- Streaming indicator and emphasis
        "syntax match NoChatStreaming /\\*(typing\\.\\.\\.)\\*/",
        "syntax match NoChatEmphasis /\\*[^*]\\+\\*/",
    }

    -- Apply syntax commands
    for _, cmd in ipairs(syntax_cmds) do
        vim.api.nvim_buf_call(buffer, function()
            vim.cmd(cmd)
        end)
    end
end

M.setup_highlights = function()
    vim.api.nvim_set_hl(0, "NoChatTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "NoChatUserHeader", { link = "Keyword" })
    vim.api.nvim_set_hl(0, "NoChatAssistantHeader", { link = "String" })
    vim.api.nvim_set_hl(0, "NoChatSystemHeader", { link = "WarningMsg" })
    vim.api.nvim_set_hl(0, "NoChatSeparator", { link = "Comment" })

    vim.api.nvim_set_hl(0, "NoChatInputBorder", { link = "FloatBorder" })
    vim.api.nvim_set_hl(0, "NoChatInputText", { link = "Normal" })

    vim.api.nvim_set_hl(0, "NoChatStreaming", { link = "Comment", italic = true })
    vim.api.nvim_set_hl(0, "NoChatEmphasis", { link = "Special", italic = true })

    vim.api.nvim_set_hl(0, "NoChatCodeBlock", { link = "Comment" })
end

M.create_placeholder = function(provider, model, title)
    local lines = {}

    -- Add header
    if title then
        table.insert(lines, "# " .. title .. " - " .. provider .. " / " .. model)
    else
        table.insert(lines, "# NoChat - " .. provider .. " / " .. model)
    end
    table.insert(lines, "")

    table.insert(lines, "*Chat started with " .. provider .. " using the " .. model .. " model.*")
    table.insert(lines, "")
    table.insert(lines, "*Type your message in the input box below and press Enter to send.*")

    return lines
end

M.add_separator = function()
    return "---"
end


return M

