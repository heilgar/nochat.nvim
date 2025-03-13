local M = {}

M.defaults = {
    -- Basic chat functions
    toggle = "<leader>nc",             -- Toggle chat window
    select_provider = "<leader>np",    -- Select AI provider for current session
    select_model = "<leader>nm",       -- Select model for current session
    clear_conversation = "<leader>nC", -- Clear current conversation
    export_selection = "<leader>ne",   -- Export selected text to chat

    -- Window positioning
    position_floating = "<leader>nf", -- Set window to floating layout
    position_right = "<leader>nr",    -- Set window to right split
    position_left = "<leader>nl",     -- Set window to left split
    position_bottom = "<leader>nb",   -- Set window to bottom split
    position_top = "<leader>nt",      -- Set window to top split
    position_tab = "<leader>na",      -- Set window to tab layout

    -- Multi-window management
    new_chat = "<leader>nn",       -- Create a new chat window
    new_chat_float = "<leader>nN", -- Create a new floating chat
    select_session = "<leader>ns", -- Select from existing sessions
    rename_session = "<leader>nR", -- Rename current session
    delete_session = "<leader>nD", -- Delete current session
    close_all = "<leader>nq",      -- Close all chat windows
}

M.setup_keymaps = function(opts)
    if vim.g.nochat_no_default_mappings == 1 or (opts and opts.no_default_keymaps) then
        return
    end

    local keymaps = (opts and opts.keymaps) or M.defaults

    local telescope = require('nochat.telescope')
    local nochat = require('nochat')
    local window = require('nochat.window')

    -- Basic NoChat functions
    vim.keymap.set('n', keymaps.toggle or M.defaults.toggle,
        function() nochat.toggle() end,
        { noremap = true, silent = true, desc = "Toggle NoChat" })

    vim.keymap.set('n', keymaps.select_provider or M.defaults.select_provider,
        function() telescope.select_provider() end,
        { noremap = true, silent = true, desc = "Select NoChat Provider" })

    vim.keymap.set('n', keymaps.select_model or M.defaults.select_model,
        function() telescope.select_model() end,
        { noremap = true, silent = true, desc = "Select NoChat Model" })

    -- Clear conversation
    vim.keymap.set('n', keymaps.clear_conversation or M.defaults.clear_conversation,
        function() nochat.clear_conversation() end,
        { noremap = true, silent = true, desc = "Clear NoChat Conversation" })

    -- Export selection to chat (works in visual mode)
    vim.keymap.set('v', keymaps.export_selection or M.defaults.export_selection,
        function()
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")
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

            local text = table.concat(lines, "\n")
            nochat.export_to_chat(text)
        end,
        { noremap = true, silent = true, desc = "Export Selection to NoChat" })

    -- Window position keymaps
    vim.keymap.set('n', keymaps.position_floating or M.defaults.position_floating,
        function() nochat.set_window_position('floating') end,
        { noremap = true, silent = true, desc = "Set NoChat to floating window" })

    vim.keymap.set('n', keymaps.position_right or M.defaults.position_right,
        function() nochat.set_window_position('right') end,
        { noremap = true, silent = true, desc = "Set NoChat to right split" })

    vim.keymap.set('n', keymaps.position_left or M.defaults.position_left,
        function() nochat.set_window_position('left') end,
        { noremap = true, silent = true, desc = "Set NoChat to left split" })

    vim.keymap.set('n', keymaps.position_bottom or M.defaults.position_bottom,
        function() nochat.set_window_position('bottom') end,
        { noremap = true, silent = true, desc = "Set NoChat to bottom split" })

    vim.keymap.set('n', keymaps.position_top or M.defaults.position_top,
        function() nochat.set_window_position('top') end,
        { noremap = true, silent = true, desc = "Set NoChat to top split" })

    vim.keymap.set('n', keymaps.position_tab or M.defaults.position_tab,
        function() nochat.set_window_position('tab') end,
        { noremap = true, silent = true, desc = "Set NoChat to tab layout" })

    -- Multi-window management keymaps
    vim.keymap.set('n', keymaps.new_chat or M.defaults.new_chat,
        function() nochat.new_chat() end,
        { noremap = true, silent = true, desc = "Create new NoChat session" })

    vim.keymap.set('n', keymaps.new_chat_float or M.defaults.new_chat_float,
        function() nochat.new_chat({ position = "floating" }) end,
        { noremap = true, silent = true, desc = "Create new floating NoChat session" })

    vim.keymap.set('n', keymaps.select_session or M.defaults.select_session,
        function() nochat.select_session() end,
        { noremap = true, silent = true, desc = "Select NoChat Session" })

    vim.keymap.set('n', keymaps.rename_session or M.defaults.rename_session,
        function() window.prompt_rename() end,
        { noremap = true, silent = true, desc = "Rename NoChat Session" })

    vim.keymap.set('n', keymaps.delete_session or M.defaults.delete_session,
        function() nochat.delete_session() end,
        { noremap = true, silent = true, desc = "Delete NoChat Session" })

    vim.keymap.set('n', keymaps.close_all or M.defaults.close_all,
        function() nochat.close_all() end,
        { noremap = true, silent = true, desc = "Close all NoChat Sessions" })
end

M.setup_input_keymaps = function(buffer, session_id)
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return
    end

    pcall(vim.api.nvim_buf_clear_namespace, buffer, 0, 0, -1)

    -- Map <CR> in normal mode to send message
    vim.api.nvim_buf_set_keymap(buffer, "n", "<CR>",
        ":lua require('nochat.window').send_message('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Send message" })

    -- Map <C-CR> in insert mode to send message
    vim.api.nvim_buf_set_keymap(buffer, "i", "<C-CR>",
        "<Esc>:lua require('nochat.window').send_message('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Send message" })

    -- Map <M-CR> (Alt+Enter) in insert mode for newline without sending
    vim.api.nvim_buf_set_keymap(buffer, "i", "<M-CR>",
        "<CR>",
        { noremap = true, silent = true, desc = "Insert newline" })

    -- Add session-specific commands
    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>np",
        ":lua require('nochat.telescope').select_provider_for_session('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Select provider for this session" })

    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>nm",
        ":lua require('nochat.telescope').select_model_for_session('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Select model for this session" })

    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>nC",
        ":lua require('nochat').clear_conversation('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Clear this conversation" })

    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>nR",
        ":lua require('nochat.window').prompt_rename('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Rename this chat" })

    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>nD",
        ":lua require('nochat').delete_session('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Delete this chat" })

    -- Toggle between input and output windows
    vim.api.nvim_buf_set_keymap(buffer, "n", "<Tab>",
        ":lua require('nochat.window').focus_output(require('nochat.window').get_current_session())<CR>",
        { noremap = true, silent = true, desc = "Focus output window" })
end

M.setup_output_keymaps = function(buffer, session_id)
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return
    end

    pcall(vim.api.nvim_buf_clear_namespace, buffer, 0, 0, -1)

    -- Add session-specific commands
    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>np",
        ":lua require('nochat.telescope').select_provider_for_session('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Select provider for this session" })

    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>nm",
        ":lua require('nochat.telescope').select_model_for_session('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Select model for this session" })

    vim.api.nvim_buf_set_keymap(buffer, "n", "<leader>nC",
        ":lua require('nochat').clear_conversation('" .. (session_id or "") .. "')<CR>",
        { noremap = true, silent = true, desc = "Clear this conversation" })

    -- Toggle between input and output windows
    vim.api.nvim_buf_set_keymap(buffer, "n", "<Tab>",
        ":lua require('nochat.window').focus_input(require('nochat.window').get_current_session())<CR>",
        { noremap = true, silent = true, desc = "Focus input window" })

    -- Scroll up/down with standard keys
    vim.api.nvim_buf_set_keymap(buffer, "n", "j", "j", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buffer, "n", "k", "k", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buffer, "n", "<C-d>", "<C-d>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buffer, "n", "<C-u>", "<C-u>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buffer, "n", "G", "G", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buffer, "n", "gg", "gg", { noremap = true, silent = true })
end

return M

