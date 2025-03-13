local M = {}

-- Load all provider modules
local function load_providers()
    -- Using pcall to gracefully handle missing modules
    local ok_anthropic, anthropic = pcall(require, 'nochat.providers.anthropic')
    local ok_openai, openai = pcall(require, 'nochat.providers.openai')
    local ok_ollama, ollama = pcall(require, 'nochat.providers.ollama')

    -- Store loaded providers
    M.loaded = {
        anthropic = ok_anthropic and anthropic or nil,
        openai = ok_openai and openai or nil,
        ollama = ok_ollama and ollama or nil
    }

    -- Log loaded providers
    local loaded_names = {}
    for name, provider in pairs(M.loaded) do
        if provider then
            table.insert(loaded_names, name)
        end
    end

    if #loaded_names > 0 then
        vim.notify("NoChat loaded providers: " .. table.concat(loaded_names, ", "), vim.log.levels.INFO)
    else
        vim.notify("NoChat: No providers loaded!", vim.log.levels.WARN)
    end
end

-- Initialize providers
load_providers()

return M

