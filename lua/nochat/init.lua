local M = {}

M.config = {
    provider = vim.g.nochat_default_provider or 'anthropic',
    model = vim.g.nochat_default_model or 'claude-3-sonnet-20240229',
    window = {
        position = "floating", -- floating, right, left, bottom, top, tab
        width = 0.4,           -- Width as percentage for splits (40%)
        height = 0.4,          -- Height as percentage for splits (40%)
        float_width = 0.8,     -- Width for floating windows (80%)
        float_height = 0.7,    -- Height for floating windows (70%)
        border = 'rounded',
        title = ' NoChat ',
        input_height = 5,        -- Height of input box in lines
        focus_on_open = "input", -- Which window to focus when opening
        start_in_insert = true,  -- Start in insert mode
        winhighlight = {         -- Window highlighting
            output = "",         -- e.g. "Normal:NoChatOutput"
            input = ""           -- e.g. "Normal:NoChatInput"
        }
    },
    providers = {
        anthropic = {
            models = {
                'claude-3-opus-20240229',
                'claude-3-sonnet-20240229',
                'claude-3-haiku-20240307',
            },

            api_key = vim.g.nochat_api_key_anthropic or os.getenv('ANTHROPIC_API_KEY'),
        },
        openai = {
            models = {
                'gpt-4-turbo',
                'gpt-4',
                'gpt-3.5-turbo',
            },

            api_key = vim.g.nochat_api_key_openai or os.getenv('OPENAI_API_KEY'),
        },
        ollama = {
            models = {
                'llama3',
            },
            host = vim.g.nochat_ollama_host or 'http://localhost:11434',
        },
    },
}

M.active_session_id = nil

local function load_dependencies()
    local ok, _ = pcall(require, 'telescope')
    if not ok then
        vim.notify('Telescope is required for NoChat', vim.log.levels.ERROR)
        return false
    end
    return true
end

M.setup = function(opts)
    if not load_dependencies() then
        return
    end

    if opts then
        -- If providers are explicitly specified, only use those
        if opts.providers and next(opts.providers) ~= nil then
            -- Replace default providers with only the ones specified
            M.config.providers = {}

            -- Process each provider
            for provider_name, provider_config in pairs(opts.providers) do
                M.config.providers[provider_name] = {}

                if provider_config.models and #provider_config.models > 0 then
                    M.config.providers[provider_name].models = provider_config.models
                end

                if provider_config.api_key then
                    M.config.providers[provider_name].api_key = provider_config.api_key
                end

                if provider_config.host then
                    M.config.providers[provider_name].host = provider_config.host
                end
            end

            -- Ensure a valid default provider
            local found_valid_provider = false
            for provider_name, _ in pairs(M.config.providers) do
                if not found_valid_provider then
                    M.config.provider = provider_name
                    found_valid_provider = true
                end
            end
        end

        -- Merge with default config
        M.config = vim.tbl_deep_extend('force', M.config, opts)
    end




    require('nochat.keymap').setup_keymaps(opts or {})
    require("nochat.window").setup(M.config)

    local ui = require("nochat.window.ui")
    ui.setup_highlights()

    local providers = require('nochat.providers')
    providers.setup(M.config)

    require('telescope').load_extension('nochat')

    vim.notify("NoChat initialized successfully", vim.log.levels.INFO)
end

M.new_chat = function(opts)
    opts = opts or {}

    local session = require("nochat.session").create(opts)

    require("nochat.window").open(session)

    M.active_session_id = session.id

    return session
end

-- Open the default chat window
M.open = function()
    -- If we have an active session, open it
    if M.active_session_id then
        local session = require("nochat.session").get(M.active_session_id)
        if session then
            require("nochat.window").open(session)
            return
        end
    end

    M.new_chat()
end

M.close = function()
    if M.active_session_id then
        local session = require("nochat.session").get(M.active_session_id)
        if session then
            require("nochat.window").close(session)
        end
    end
end

M.toggle = function()
    if M.active_session_id then
        local session = require("nochat.session").get(M.active_session_id)
        if session and session.window_state.is_open then
            require("nochat.window").close(session)
        else
            require("nochat.window").open(session)
        end
    else
        -- Create a new session if none exists
        M.new_chat()
    end
end

M.select_session = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local finders = require("telescope.finders")
    local pickers = require("telescope.pickers")
    local conf = require("telescope.config").values
    local previewers = require("telescope.previewers")

    local sessions = require("nochat.session").list_sessions()

    -- Create a custom previewer that shows the conversation content
    local session_previewer = previewers.new_buffer_previewer({
        title = "Conversation Preview",
        define_preview = function(self, entry, status)
            local session_id = entry.value
            local session = require("nochat.session").get(session_id)

            if not session then
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "No conversation content available" })
                return
            end

            local ui = require("nochat.window.ui")
            local content = ui.format_conversation(
                session.conversation,
                session.provider,
                session.model,
                session.title
            )

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
            vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end
    })

    pickers.new({}, {
        prompt_title = "Select NoChat Session",
        finder = finders.new_table({
            results = sessions,
            entry_maker = function(entry)
                local status = entry.is_open and "[Open] " or "[Closed] "
                local count = tostring(entry.message_count) .. " messages"
                return {
                    value = entry.id,
                    display = status ..
                        entry.title .. " (" .. entry.provider .. "/" .. entry.model .. ", " .. count .. ")",
                    ordinal = entry.title
                }
            end
        }),
        sorter = conf.generic_sorter({}),
        previewer = session_previewer,
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                local session_id = selection.value

                local session = require("nochat.session").get(session_id)
                if session then
                    M.active_session_id = session_id
                    require("nochat.window").open(session)
                end
            end)
            return true
        end
    }):find()
end

M.handle_user_message = function(message, session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    local session = require("nochat.session").get(session_id)
    if not session then
        vim.notify("Invalid session ID", vim.log.levels.ERROR)
        return
    end

    table.insert(session.conversation, {
        role = "user",
        content = message
    })

    M.update_conversation_display(session_id)
    M.get_ai_response(session_id)
end

-- Get AI response for a session
M.get_ai_response = function(session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    local session = require("nochat.session").get(session_id)
    if not session then
        vim.notify("Invalid session ID", vim.log.levels.ERROR)
        return
    end

    local provider_name = session.provider
    local model = session.model

    local providers = require('nochat.providers')
    local provider = providers.loaded[provider_name]

    if not provider then
        vim.notify("Provider " .. provider_name .. " is not available", vim.log.levels.ERROR)
        return
    end

    -- Check if provider is available
    if not provider:is_available() then
        local error_message = provider:get_error_message()

        table.insert(session.conversation, {
            role = "system",
            content = "Error: " .. error_message
        })

        M.update_conversation_display(session_id)
        return
    end

    if not provider:is_valid_model(model) then
        local default_model = provider:get_default_model()
        if default_model then
            vim.notify("Model '" .. (model or "nil") .. "' is not valid for " .. provider_name ..
                ". Using default: " .. default_model, vim.log.levels.WARN)
            session.model = default_model
            model = default_model
        else
            table.insert(session.conversation, {
                role = "system",
                content = "Error: No valid model available for " .. provider_name
            })
            M.update_conversation_display(session_id)
            return
        end
    end

    session.is_streaming = true

    local ui = require("nochat.window.ui")
    local typing_content = ui.format_conversation(
        session.conversation,
        session.provider,
        session.model,
        session.title,
        true -- Add typing indicator
    )
    require("nochat.window").update_output(session, typing_content)

    provider:get_response(session.conversation, model, function(response, is_done)
        if is_done then
            table.insert(session.conversation, {
                role = "assistant",
                content = response
            })
            session.is_streaming = false
        else
            local last_msg = session.conversation[#session.conversation]
            if last_msg and last_msg.role == "assistant" and last_msg.streaming then
                last_msg.content = response
            else
                table.insert(session.conversation, {
                    role = "assistant",
                    content = response,
                    streaming = true
                })
            end
        end

        M.update_conversation_display(session_id)
    end)
end

M.update_conversation_display = function(session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        return
    end

    local session = require("nochat.session").get(session_id)
    if not session then
        return
    end

    local ui = require("nochat.window.ui")
    local content = ui.format_conversation(
        session.conversation,
        session.provider,
        session.model,
        session.title
    )

    require("nochat.window").update_output(session, content)
end

M.abort_stream = function(session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        return
    end

    local session = require("nochat.session").get(session_id)
    if not session or not session.is_streaming then
        return
    end

    local provider_name = session.provider
    local providers = require('nochat.providers')
    local provider = providers.loaded[provider_name]

    if provider then
        provider:abort_stream()
    end

    session.is_streaming = false

    -- Remove any streaming messages
    for i = #session.conversation, 1, -1 do
        if session.conversation[i].streaming then
            table.remove(session.conversation, i)
            break
        end
    end

    M.update_conversation_display(session_id)
end


M.clear_conversation = function(session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    require("nochat.session").clear_conversation(session_id)
    vim.notify("Conversation cleared", vim.log.levels.INFO)
end

M.set_provider = function(provider, session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    require("nochat.session").set_provider(session_id, provider)
end

M.set_model = function(model, session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    require("nochat.session").set_model(session_id, model)
end

M.export_to_chat = function(selection, session_id)
    session_id = session_id or M.active_session_id

    local text
    if selection then
        text = selection
    else
        -- Get visual selection
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        if start_pos[2] == 0 and end_pos[2] == 0 then
            -- No visual selection, export whole buffer
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            text = table.concat(lines, "\n")
        else
            -- Get visual selection content
            local lines = vim.fn.getline(start_pos[2], end_pos[2])
            if #lines == 0 then
                vim.notify("No text selected", vim.log.levels.WARN)
                return
            end

            -- Adjust for column selection in the first and last line
            if #lines == 1 then
                lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
            else
                lines[1] = string.sub(lines[1], start_pos[3])
                lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
            end

            text = table.concat(lines, "\n")
        end
    end

    -- Create a new session if needed
    if not session_id then
        local session = M.new_chat()
        session_id = session.id
    else
        -- Open existing session if not already open
        local session = require("nochat.session").get(session_id)
        if session and not session.window_state.is_open then
            require("nochat.window").open(session)
        end
    end

    -- Put text in input buffer
    local session = require("nochat.session").get(session_id)
    if session and session.window_state.input_buffer and
        vim.api.nvim_buf_is_valid(session.window_state.input_buffer) then
        vim.api.nvim_buf_set_option(session.window_state.input_buffer, "modifiable", true)
        vim.api.nvim_buf_set_lines(session.window_state.input_buffer, 0, -1, false, vim.split(text, "\n"))
    end
end

M.set_window_position = function(position, session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        -- Update default config if no session
        M.config.window.position = position
        vim.notify("Default window position set to: " .. position, vim.log.levels.INFO)
        return
    end

    local session = require("nochat.session").get(session_id)
    if not session then
        return
    end

    local valid_positions = { "floating", "right", "left", "top", "bottom", "tab" }

    -- Check if position is valid
    local is_valid = false
    for _, pos in ipairs(valid_positions) do
        if pos == position then
            is_valid = true
            break
        end
    end

    if not is_valid then
        vim.notify("Invalid window position: " .. position, vim.log.levels.ERROR)
        return
    end

    -- Update session position
    session.window_state.position = position

    -- Reopen window if it's currently open
    if session.window_state.is_open then
        require("nochat.window").close(session)
        require("nochat.window").open(session)
    end

    vim.notify("Window position set to: " .. position .. " for session " .. session.title, vim.log.levels.INFO)
end

M.close_all = function()
    local sessions = require("nochat.session").get_all()
    for id, _ in pairs(sessions) do
        require("nochat.session").delete(id)
    end

    M.active_session_id = nil
end

M.delete_session = function(session_id)
    session_id = session_id or M.active_session_id

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    local sessions = require("nochat.session")
    local success = sessions.delete(session_id)

    if success then
        -- If we deleted the active session, clear the active session ID
        if session_id == M.active_session_id then
            M.active_session_id = nil

            -- Try to set the active session to another open session
            local all_sessions = sessions.list_sessions()
            for _, s in ipairs(all_sessions) do
                if s.is_open then
                    M.active_session_id = s.id
                    break
                end
            end
        end

        vim.notify("Chat session deleted", vim.log.levels.INFO)
    end
end

return M

