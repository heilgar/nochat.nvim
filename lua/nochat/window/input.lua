local M = {}

M.setup = function(buffer, session_id)
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return
    end

    -- Clear previous keymaps
    pcall(vim.api.nvim_buf_clear_namespace, buffer, 0, 0, -1)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buffer, "modifiable", true)
    vim.api.nvim_buf_set_option(buffer, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buffer, "swapfile", false)

    -- Add session-specific argument to send_message function
    local send_cmd = session_id and
        "require('nochat.window').send_message('" .. session_id .. "')" or
        "require('nochat.window').send_message()"

    -- Map <CR> in normal mode to send message
    vim.api.nvim_buf_set_keymap(buffer, "n", "<CR>",
        ":lua " .. send_cmd .. "<CR>",
        { noremap = true, silent = true, desc = "Send message" })

    -- Map <CR> in insert mode to send message (this was missing)
    vim.api.nvim_buf_set_keymap(buffer, "i", "<CR>",
        "<Esc>:lua " .. send_cmd .. "<CR>",
        { noremap = true, silent = true, desc = "Send message in insert mode" })

    -- Map <C-CR> in insert mode to send message
    vim.api.nvim_buf_set_keymap(buffer, "i", "<C-CR>",
        "<Esc>:lua " .. send_cmd .. "<CR>",
        { noremap = true, silent = true, desc = "Send message" })

    -- Map <M-CR> (Alt+Enter) in insert mode for newline without sending
    vim.api.nvim_buf_set_keymap(buffer, "i", "<M-CR>",
        "<CR>",
        { noremap = true, silent = true, desc = "Insert newline" })

    -- Add keymaps for this specific session
    require("nochat.keymap").setup_input_keymaps(buffer, session_id)

    -- Clear the buffer
    M.clear(buffer)
end

M.get_message = function(buffer)
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return ""
    end

    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    return table.concat(lines, "\n")
end

M.clear = function(buffer)
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return
    end

    vim.api.nvim_buf_set_option(buffer, "modifiable", true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "" })

    -- Move cursor to the start
    local window = require("nochat.window.ui").find_window_with_buffer(buffer)
    if window and vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_win_set_cursor(window, { 1, 0 })
    end
end


return M

