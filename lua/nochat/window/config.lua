local M = {}

-- Default configuration
M.defaults = {
    position = "floating", -- floating, right, left, bottom, top, tab
    width = 0.4,           -- Width as percentage (for floating/split) or absolute value
    height = 0.4,          -- Height as percentage (for floating/split) or absolute value
    border = "rounded",    -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    title = " NoChat ",    -- Window title
    padding = {            -- Padding inside windows
        top = 1,
        bottom = 1,
        left = 1,
        right = 1
    },
    input_height = 5,        -- Height of input box in lines
    focus_on_open = "input", -- Which window to focus when opening: "input" or "output"
    start_in_insert = true,  -- Whether to start in insert mode when focusing the input
    winhighlight = {         -- Window highlighting
        output = "",         -- e.g. "Normal:NoChatOutput,CursorLine:NoChatCursorLine"
        input = ""           -- e.g. "Normal:NoChatInput"
    }
}

-- Current configuration
M.current = vim.deepcopy(M.defaults)

M.setup = function(opts)
    if opts and opts.window then
        M.current = vim.tbl_deep_extend("force", M.current, opts.window)
    end
end

M.get = function()
    return M.current
end

M.update = function(opts)
    M.current = vim.tbl_deep_extend("force", M.current, opts)
    return M.current
end

return M

