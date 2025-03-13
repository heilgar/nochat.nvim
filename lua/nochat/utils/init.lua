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

return M

