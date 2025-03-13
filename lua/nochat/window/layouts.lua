local M = {}

local ui = require("nochat.window.ui")

M.create_floating_layout = function(config)
    -- For floating windows, use the float_width/float_height if available,
    -- otherwise fall back to width/height
    local width_percent = config.float_width or config.width
    local height_percent = config.float_height or config.height

    local width = math.floor(vim.o.columns * width_percent)
    local height = math.floor(vim.o.lines * height_percent)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Calculate output window height (total height - input height - border)
    local output_height = height - config.input_height - 1

    -- Create output window
    local output_opts = {
        relative = 'editor',
        width = width,
        height = output_height,
        col = col,
        row = row,
        style = 'minimal',
        border = config.border,
        title = config.title,
    }

    if config.winhighlight and config.winhighlight.output and config.winhighlight.output ~= "" then
        output_opts.winhighlight = config.winhighlight.output
    end

    local output_buffer = ui.get_output_buffer()
    local output_window = vim.api.nvim_open_win(output_buffer, true, output_opts)

    -- Apply window options to output window
    ui.apply_window_options(output_window)

    -- Create input window directly below the output window
    local input_opts = {
        relative = 'editor',
        width = width,
        height = config.input_height,
        col = col,
        row = row + output_height + 1, -- Position directly below output window
        style = 'minimal',
        border = config.border,
        title = " Input ",
    }

    if config.winhighlight and config.winhighlight.input and config.winhighlight.input ~= "" then
        input_opts.winhighlight = config.winhighlight.input
    end

    local input_buffer = ui.get_input_buffer()
    local input_window = vim.api.nvim_open_win(input_buffer, false, input_opts)

    -- Apply window options to input window
    ui.apply_window_options(input_window, true)

    return {
        output_window = output_window,
        output_buffer = output_buffer,
        input_window = input_window,
        input_buffer = input_buffer
    }
end

M.create_split_layout = function(config)
    local position = config.position
    local size

    -- Default size of 40% for all split positions if not specified otherwise
    if position == "right" or position == "left" then
        -- For width, use 40% of screen width as default
        if type(config.width) == "number" and config.width <= 1 then
            size = math.floor(vim.o.columns * config.width)
        else
            -- If not a percentage, use 40% of screen width as default
            size = math.floor(vim.o.columns * 0.4)
        end
    else -- top or bottom
        -- For height, use 40% of screen height as default
        if type(config.height) == "number" and config.height <= 1 then
            size = math.floor(vim.o.lines * config.height)
        else
            -- If not a percentage, use 40% of screen height as default
            size = math.floor(vim.o.lines * 0.4)
        end
    end

    -- Save current window for later
    local original_win = vim.api.nvim_get_current_win()

    -- Set the split command based on position
    local split_cmd
    if position == "right" then
        split_cmd = "vertical botright " .. size .. "split"
    elseif position == "left" then
        split_cmd = "vertical topleft " .. size .. "split"
    elseif position == "bottom" then
        split_cmd = "botright " .. size .. "split"
    elseif position == "top" then
        split_cmd = "topleft " .. size .. "split"
    end

    -- Create output split
    vim.cmd(split_cmd)
    local output_window = vim.api.nvim_get_current_win()
    local output_buffer = ui.get_output_buffer()
    vim.api.nvim_win_set_buf(output_window, output_buffer)

    -- Apply window options and highlighting
    ui.apply_window_options(output_window)
    if config.winhighlight and config.winhighlight.output and config.winhighlight.output ~= "" then
        vim.wo[output_window].winhighlight = config.winhighlight.output
    end

    -- Create input split (within the same split area)
    local input_height = config.input_height
    vim.cmd("botright " .. input_height .. "split")
    local input_window = vim.api.nvim_get_current_win()
    local input_buffer = ui.get_input_buffer()
    vim.api.nvim_win_set_buf(input_window, input_buffer)

    -- Apply window options and highlighting to input window
    ui.apply_window_options(input_window, true)
    if config.winhighlight and config.winhighlight.input and config.winhighlight.input ~= "" then
        vim.wo[input_window].winhighlight = config.winhighlight.input
    end

    -- Return focus to output window
    vim.api.nvim_set_current_win(output_window)

    return {
        output_window = output_window,
        output_buffer = output_buffer,
        input_window = input_window,
        input_buffer = input_buffer,
        original_window = original_win
    }
end

M.create_tab_layout = function(config)
    -- Create a new tab
    vim.cmd("tabnew")

    local output_buffer = ui.get_output_buffer()
    local output_window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(output_window, output_buffer)

    -- Apply window options and highlighting
    ui.apply_window_options(output_window)
    if config.winhighlight.output and config.winhighlight.output ~= "" then
        vim.api.nvim_win_set_option(output_window, 'winhighlight', config.winhighlight.output)
    end

    -- Create input split at the bottom of the tab
    local input_height = config.input_height
    vim.cmd("botright " .. input_height .. "split")
    local input_window = vim.api.nvim_get_current_win()
    local input_buffer = ui.get_input_buffer()
    vim.api.nvim_win_set_buf(input_window, input_buffer)

    -- Apply window options and highlighting to input window
    ui.apply_window_options(input_window, true)
    if config.winhighlight.input and config.winhighlight.input ~= "" then
        vim.api.nvim_win_set_option(input_window, 'winhighlight', config.winhighlight.input)
    end

    -- Return focus to output window
    vim.api.nvim_set_current_win(output_window)

    return {
        output_window = output_window,
        output_buffer = output_buffer,
        input_window = input_window,
        input_buffer = input_buffer
    }
end

return M

