local M = {}
local utils = require('nochat.utils')

M.loaded = {}

M.setup = function(config)
    if config and config.providers then
        for provider_name, cfg in pairs(config.providers) do
            local provider = utils.safe_require('nochat.providers.' .. provider_name)
            if provider then
                M.loaded[provider_name] = provider

                if provider.setup then
                    provider:setup(cfg)

                    if provider.get_models and #provider:get_models() > 0 then
                        vim.notify("Initialized " .. provider_name .. " provider with " ..
                            #provider:get_models() .. " models", vim.log.levels.DEBUG)
                    else
                        vim.notify("Initialized " .. provider_name .. " provider (no models configured)",
                            vim.log.levels.WARN)
                    end
                end
            else
                vim.notify("Failed to load provider: " .. provider_name, vim.log.levels.WARN)
            end
        end
    end

    local loaded_names = {}

    for name, _ in pairs(M.loaded) do
        table.insert(loaded_names, name)
    end

    for name, _ in pairs(M.loaded) do
        table.insert(loaded_names, name)
    end
end


return M

