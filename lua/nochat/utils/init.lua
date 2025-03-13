local M = {}

M.streaming = require('nochat.utils.streaming')

M.ensure_directory = function(path)
    local exists = vim.fn.isdirectory(path) == 1
    if not exists then
        vim.fn.mkdir(path, "p")
    end
    return exists
end

M.safe_require = function(module_name)
    local ok, module = pcall(require, module_name)
    if not ok then
        vim.notify("Could not load module: " .. module_name, vim.log.levels.WARN)
        return nil
    end
    return module
end

-- JSON encoding/decoding utilities
M.json = {}


M.json.encode = function(val)
    local status, result = pcall(vim.fn.json_encode, val)
    if status then
        return result
    else
        -- Fallback for older Neovim versions or errors
        error("JSON encode failed: " .. tostring(result))
    end
end

M.json.decode = function(str)
    local status, result = pcall(vim.fn.json_decode, str)
    if status then
        return result
    else
        -- Fallback for older Neovim versions or errors
        error("JSON decode failed: " .. tostring(result))
    end
end



M.curl = M.safe_require('plenary.curl')

M.is_http_available = function()
    return M.curl ~= nil
end

M.get_http_error = function()
    return "HTTP functionality requires plenary.nvim. Please install it."
end

M.get = function(url, options)
    if not M.curl then
        if options and options.on_error then
            options.on_error(M.get_http_error())
        elseif options and options.callback then
            options.callback({ status = -1, body = M.get_http_error() })
        end
        return nil, M.get_http_error()
    end

    return M.curl.get(url, options)
end

M.post = function(url, options)
    if not M.curl then
        if options and options.on_error then
            options.on_error(M.get_http_error())
        elseif options and options.callback then
            options.callback({ status = -1, body = M.get_http_error() })
        end
        return nil, M.get_http_error()
    end

    return M.curl.post(url, options)
end

return M

