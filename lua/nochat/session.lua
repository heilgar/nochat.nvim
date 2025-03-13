local M = {}

M.sessions = {}

local function generate_session_id()
    return "nochat_" .. tostring(os.time()) .. "_" .. math.random(1, 9999)
end

M.create = function(opts)
    local session_id = generate_session_id()
    local nochat = require("nochat")
    local config = require("nochat.window.config")

    local session_count = 0
    for _ in pairs(M.sessions) do
        session_count = session_count + 1
    end

    local session = {
        id = session_id,
        provider = opts.provider or nochat.config.provider,
        model = opts.model or nochat.config.model,
        conversation = {},
        is_streaming = false,
        window_state = {
            output_window = nil,
            output_buffer = nil,
            input_window = nil,
            input_buffer = nil,
            is_open = false,
            position = opts.position or config.get().position
        },
        title = opts.title or ("Chat " .. (session_count + 1))
    }

    M.sessions[session_id] = session

    return session
end

M.get = function(session_id)
    return M.sessions[session_id]
end

M.get_all = function()
    return M.sessions
end

M.delete = function(session_id)
    if M.sessions[session_id] then
        -- Close windows if open
        local session = M.sessions[session_id]
        if session.window_state.is_open then
            local window = require("nochat.window")
            window.close(session)
        end

        -- Remove session data
        M.sessions[session_id] = nil
        return true
    end
    return false
end

M.set_provider = function(session_id, provider)
    local session = M.sessions[session_id]
    if not session then
        return false
    end

    -- Check if provider is valid
    local nochat = require("nochat")
    if not nochat.config.providers[provider] then
        vim.notify("Invalid provider: " .. provider, vim.log.levels.ERROR)
        return false
    end

    -- Update provider
    session.provider = provider

    -- Update title if window is open
    if session.window_state.is_open then
        local window = require("nochat.window")
        window.update_title(session)
    end

    vim.notify("Provider set to: " .. provider .. " for session " .. session.title, vim.log.levels.INFO)
    return true
end

M.set_model = function(session_id, model)
    local session = M.sessions[session_id]
    if not session then
        return false
    end

    -- Check if model is valid for the session's provider
    local nochat = require("nochat")
    local provider = session.provider
    local models = nochat.config.providers[provider].models

    local is_valid = false
    for _, m in ipairs(models) do
        if m == model then
            is_valid = true
            break
        end
    end

    if not is_valid then
        vim.notify("Invalid model for " .. provider .. ": " .. model, vim.log.levels.ERROR)
        return false
    end

    -- Update model
    session.model = model

    -- Update title if window is open
    if session.window_state.is_open then
        local window = require("nochat.window")
        window.update_title(session)
    end

    vim.notify("Model set to: " .. model .. " for session " .. session.title, vim.log.levels.INFO)
    return true
end

M.set_title = function(session_id, title)
    local session = M.sessions[session_id]
    if not session then
        return false
    end

    session.title = title

    -- Update title if window is open
    if session.window_state.is_open then
        local window = require("nochat.window")
        window.update_title(session)
    end

    return true
end

M.get_by_window = function(win_id)
    for id, session in pairs(M.sessions) do
        if session.window_state.output_window == win_id or
            session.window_state.input_window == win_id then
            return session
        end
    end
    return nil
end

M.list_sessions = function()
    local result = {}
    for id, session in pairs(M.sessions) do
        table.insert(result, {
            id = id,
            title = session.title,
            provider = session.provider,
            model = session.model,
            is_open = session.window_state.is_open,
            message_count = #session.conversation
        })
    end

    -- Sort by title
    table.sort(result, function(a, b) return a.title < b.title end)

    return result
end

M.clear_conversation = function(session_id)
    local session = M.sessions[session_id]
    if not session then
        return false
    end

    session.conversation = {}

    -- Update UI if window is open
    if session.window_state.is_open then
        local window = require("nochat.window")
        local ui = require("nochat.window.ui")
        local content = ui.format_conversation(
            session.conversation,
            session.provider,
            session.model
        )
        window.update_output(session, content)
    end

    return true
end

return M

