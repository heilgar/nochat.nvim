local M = {}

local config = require("nochat.window.config")
local layouts = require("nochat.window.layouts")
local ui = require("nochat.window.ui")
local input = require("nochat.window.input")

M.setup = function(opts)
    config.setup(opts)
end

M.open = function(session)
    if not session then
        vim.notify("No session provided to window.open", vim.log.levels.ERROR)
        return
    end

    if session.window_state.is_open then
        return
    end

    local position = session.window_state.position or config.get().position
    local cfg = vim.tbl_deep_extend("force", config.get(), { position = position })

    local layout
    if cfg.position == "floating" then
        layout = layouts.create_floating_layout(cfg)
    elseif cfg.position == "tab" then
        layout = layouts.create_tab_layout(cfg)
    else -- right, left, top, bottom
        layout = layouts.create_split_layout(cfg)
    end

    session.window_state.output_window = layout.output_window
    session.window_state.input_window = layout.input_window
    session.window_state.output_buffer = layout.output_buffer
    session.window_state.input_buffer = layout.input_buffer
    session.window_state.is_open = true

    M.update_title(session)

    input.setup(layout.input_buffer, session.id)

    M.setup_autocommands(session)

    local content = ui.format_conversation(
        session.conversation,
        session.provider,
        session.model,
        session.title
    )
    M.update_output(session, content)

    if cfg.focus_on_open == "input" or cfg.focus_on_open == nil then
        vim.api.nvim_set_current_win(session.window_state.input_window)
        if cfg.start_in_insert then
            vim.cmd("startinsert")
        end
    else
        vim.api.nvim_set_current_win(session.window_state.output_window)
    end
end

M.close = function(session)
    if not session or not session.window_state.is_open then
        return
    end

    if session.window_state.output_window and vim.api.nvim_win_is_valid(session.window_state.output_window) then
        vim.api.nvim_win_close(session.window_state.output_window, true)
    end

    if session.window_state.input_window and vim.api.nvim_win_is_valid(session.window_state.input_window) then
        vim.api.nvim_win_close(session.window_state.input_window, true)
    end

    if session.window_state.position == "tab" and vim.fn.tabpagenr("$") > 1 then
        vim.cmd("tabclose")
    end

    session.window_state.is_open = false
end

M.setup_autocommands = function(session)
    local augroup = vim.api.nvim_create_augroup("NoChatWindows_" .. session.id, { clear = true })

    vim.api.nvim_create_autocmd("WinClosed", {
        group = augroup,
        pattern = tostring(session.window_state.output_window) .. "," .. tostring(session.window_state.input_window),
        callback = function()
            -- Mark the session as closed
            session.window_state.is_open = false
        end,
    })

    local output_buf = session.window_state.output_buffer
    if output_buf and vim.api.nvim_buf_is_valid(output_buf) then
        vim.api.nvim_create_autocmd("FileType", {
            group = augroup,
            buffer = output_buf,
            callback = function()
                -- Set up any buffer-specific options for markdown
                vim.api.nvim_buf_set_option(output_buf, "conceallevel", 2)
            end,
        })
    end
end

M.update_title = function(session)
    if not session or not session.window_state.is_open then
        return
    end

    -- For window title, always display provider and model with title
    local title = " NoChat - " .. session.provider .. " / " .. session.model .. " "
    if session.title and session.title ~= "" then
        title = " " .. session.title .. " - " .. session.provider .. " / " .. session.model .. " "
    end

    -- Update floating window title if applicable
    if session.window_state.output_window and vim.api.nvim_win_is_valid(session.window_state.output_window) then
        pcall(vim.api.nvim_win_set_config, session.window_state.output_window, {
            title = title,
        })
    end

    -- Update tab name or buffer name to just show the Chat title for cleaner display
    -- This affects what shows in the tabline
    if session.window_state.output_buffer and vim.api.nvim_buf_is_valid(session.window_state.output_buffer) then
        vim.api.nvim_buf_set_name(session.window_state.output_buffer, session.title)
    end
end

M.update_output = function(session, content)
    if not session or not session.window_state.is_open then
        return
    end

    ui.update_output(session.window_state.output_buffer, content)
end

M.send_message = function(session_id)
    if not session_id then
        -- Try to detect current session from current window
        local win_id = vim.api.nvim_get_current_win()
        local session = require("nochat.session").get_by_window(win_id)

        if session then
            session_id = session.id
        else
            -- Use active session as fallback
            session_id = require("nochat").active_session_id
        end
    end

    if not session_id then
        vim.notify("Cannot determine which chat session to use", vim.log.levels.ERROR)
        return
    end

    local session = require("nochat.session").get(session_id)
    if not session then
        return
    end

    local message = input.get_message(session.window_state.input_buffer)
    if message and message ~= "" then
        input.clear(session.window_state.input_buffer)

        require("nochat").handle_user_message(message, session_id)
    end
end

M.get_current_session = function()
    local win_id = vim.api.nvim_get_current_win()
    return require("nochat.session").get_by_window(win_id)
end

M.focus_input = function(session)
    if not session or not session.window_state.is_open then
        return
    end

    if session.window_state.input_window and vim.api.nvim_win_is_valid(session.window_state.input_window) then
        vim.api.nvim_set_current_win(session.window_state.input_window)
        vim.cmd("startinsert")
    end
end

M.focus_output = function(session)
    if not session or not session.window_state.is_open then
        return
    end

    if session.window_state.output_window and vim.api.nvim_win_is_valid(session.window_state.output_window) then
        vim.api.nvim_set_current_win(session.window_state.output_window)
    end
end

M.resize = function(session, dimensions)
    if not session or not session.window_state.is_open then
        return false
    end

    -- Only floating windows can be resized this way
    if session.window_state.position ~= "floating" then
        vim.notify("Only floating windows can be resized with this method", vim.log.levels.WARN)
        return false
    end

    if not (session.window_state.output_window and vim.api.nvim_win_is_valid(session.window_state.output_window) and
            session.window_state.input_window and vim.api.nvim_win_is_valid(session.window_state.input_window)) then
        return false
    end

    -- Get configuration
    local cfg = config.get()

    -- Calculate new dimensions
    local width = dimensions.width or cfg.float_width or cfg.width
    local height = dimensions.height or cfg.float_height or cfg.height
    local input_height = dimensions.input_height or cfg.input_height

    -- Convert percentages to absolute sizes
    if type(width) == "number" and width <= 1 then
        width = math.floor(vim.o.columns * width)
    end

    if type(height) == "number" and height <= 1 then
        height = math.floor(vim.o.lines * height)
    end

    -- Ensure minimum sizes
    width = math.max(width, 20)
    height = math.max(height, input_height + 5)

    -- Calculate positions
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)
    local output_height = height - input_height - 1

    -- Resize output window
    vim.api.nvim_win_set_config(session.window_state.output_window, {
        relative = 'editor',
        width = width,
        height = output_height,
        col = col,
        row = row,
    })

    -- Resize input window
    vim.api.nvim_win_set_config(session.window_state.input_window, {
        relative = 'editor',
        width = width,
        height = input_height,
        col = col,
        row = row + output_height + 1,
    })

    return true
end

M.rename_session = function(session, new_title)
    if not session then
        return
    end

    require("nochat.session").set_title(session.id, new_title)

    if session.window_state.is_open then
        M.update_title(session)
    end
end

M.prompt_rename = function(session_id)
    if not session_id then
        local session = M.get_current_session()
        if session then
            session_id = session.id
        else
            session_id = require("nochat").active_session_id
        end
    end

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    local session = require("nochat.session").get(session_id)
    if not session then
        return
    end

    vim.ui.input({
        prompt = "Rename chat: ",
        default = session.title,
    }, function(new_title)
        if new_title and new_title ~= "" then
            M.rename_session(session, new_title)
            vim.notify("Renamed chat to: " .. new_title, vim.log.levels.INFO)
        end
    end)
end

return M

