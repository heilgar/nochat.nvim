local M = {}

M.config = {
    provider = vim.g.nochat_default_provider or 'anthropic',
    model = vim.g.nochat_default_model or 'claude-3-sonnet-20240229',
    window = {
        width = 0.8,  -- Percentage of screen width
        height = 0.7, -- Percentage of screen height
        border = 'rounded',
        title = ' NoChat ',
    },
    api_keys = {
        anthropic = vim.g.nochat_api_key_anthropic or os.getenv('ANTHROPIC_API_KEY'),
        openai = vim.g.nochat_api_key_openai or os.getenv('OPENAI_API_KEY'),
    },
    ollama = {
        host = vim.g.nochat_ollama_host or 'http://localhost:11434',
    },
    providers = {
        anthropic = {
            models = {
                'claude-3-opus-20240229',
                'claude-3-sonnet-20240229',
                'claude-3-haiku-20240307',
            },
        },
        openai = {
            models = {
                'gpt-4-turbo',
                'gpt-4',
                'gpt-3.5-turbo',
            },
        },
        ollama = {
            models = {
                'llama3',
                'mistral',
                'gemma',
                'codellama',
            },
        },
    },
}

-- Internal state
M.state = {
    chat_window = nil,
    chat_buffer = nil,
    is_open = false,
    conversation = {},
}

local function load_dependencies()
    local ok, _ = pcall(require, 'telescope')
    if not ok then
        vim.notify('Telescope is required for NoChat', vim.log.levels.ERROR)
        return false
    end
    return true
end

M.setup = function(opts)
    if opts then
        M.config = vim.tbl_deep_extend('force', M.config, opts)
    end

    if not load_dependencies() then
        return
    end

    require('nochat.providers')
    require('nochat.keymap').setup_keymaps(opts or {})

    require('telescope').load_extension('nochat')
end

M.create_window = function()
    -- Calculate window dimensions
    local width = math.floor(vim.o.columns * M.config.window.width)
    local height = math.floor(vim.o.lines * M.config.window.height)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Create buffer if it doesn't exist
    if not M.state.chat_buffer or not vim.api.nvim_buf_is_valid(M.state.chat_buffer) then
        M.state.chat_buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(M.state.chat_buffer, 'filetype', 'markdown')
        vim.api.nvim_buf_set_option(M.state.chat_buffer, 'modifiable', false)
    end

    -- Window options
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = M.config.window.border,
        title = M.config.window.title,
    }

    -- Create the window
    M.state.chat_window = vim.api.nvim_open_win(M.state.chat_buffer, true, opts)

    -- Set window options
    vim.api.nvim_win_set_option(M.state.chat_window, 'wrap', true)
    vim.api.nvim_win_set_option(M.state.chat_window, 'cursorline', true)

    return M.state.chat_window
end

M.open = function()
    if M.state.is_open then
        return
    end

    M.create_window()
    M.state.is_open = true

    M.render_conversation()
end

M.close = function()
    if M.state.is_open and M.state.chat_window and vim.api.nvim_win_is_valid(M.state.chat_window) then
        vim.api.nvim_win_close(M.state.chat_window, true)
        M.state.is_open = false
    end
end

M.toggle = function()
    if M.state.is_open then
        M.close()
    else
        M.open()
    end
end

M.render_conversation = function()
    if not M.state.chat_buffer or not vim.api.nvim_buf_is_valid(M.state.chat_buffer) then
        return
    end

    -- Make buffer modifiable
    vim.api.nvim_buf_set_option(M.state.chat_buffer, 'modifiable', true)

    -- Clear the buffer
    vim.api.nvim_buf_set_lines(M.state.chat_buffer, 0, -1, false, {})

    -- Add content
    local lines = {}
    table.insert(lines, "# NoChat - " .. M.config.provider .. " / " .. M.config.model)
    table.insert(lines, "")

    -- Add conversation history
    for _, message in ipairs(M.state.conversation) do
        if message.role == "user" then
            table.insert(lines, "## User")
        else
            table.insert(lines, "## Assistant")
        end
        table.insert(lines, "")

        -- Split message content into lines
        for _, line in ipairs(vim.split(message.content, "\n")) do
            table.insert(lines, line)
        end

        table.insert(lines, "")
        table.insert(lines, "---")
        table.insert(lines, "")
    end

    -- Set buffer content
    vim.api.nvim_buf_set_lines(M.state.chat_buffer, 0, -1, false, lines)

    -- Make buffer non-modifiable again
    vim.api.nvim_buf_set_option(M.state.chat_buffer, 'modifiable', false)
end

M.set_provider = function(provider)
    if M.config.providers[provider] then
        M.config.provider = provider
        vim.notify("NoChat provider set to: " .. provider, vim.log.levels.INFO)
    else
        vim.notify("Invalid provider: " .. provider, vim.log.levels.ERROR)
    end
end

M.set_model = function(model)
    local provider = M.config.provider
    local models = M.config.providers[provider].models

    -- Check if model is valid for the current provider
    local is_valid = false
    for _, m in ipairs(models) do
        if m == model then
            is_valid = true
            break
        end
    end

    if is_valid then
        M.config.model = model
        vim.notify("NoChat model set to: " .. model, vim.log.levels.INFO)
    else
        vim.notify("Invalid model for " .. provider .. ": " .. model, vim.log.levels.ERROR)
    end
end

return M

