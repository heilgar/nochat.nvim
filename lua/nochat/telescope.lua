local M = {}
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local nochat = require('nochat')

M.select_provider = function()
    local providers = {}
    for provider, _ in pairs(nochat.config.providers) do
        table.insert(providers, provider)
    end

    table.sort(providers)

    pickers.new({}, {
        prompt_title = 'Select NoChat Provider',
        finder = finders.new_table({
            results = providers,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()

                -- Set the provider
                nochat.set_provider(selection.value)

                -- Automatically open model selection for the chosen provider
                vim.defer_fn(function()
                    M.select_model_by_provider(selection.value)
                end, 100)
            end)
            return true
        end,
    }):find()
end

M.select_model_by_provider = function(provider)
    provider = provider or nochat.config.provider

    local models = nochat.config.providers[provider].models or {}

    if #models == 0 then
        -- If no models configured, try to fetch dynamically (e.g., for Ollama)
        local providers = require('nochat.providers')
        local provider_obj = providers.loaded[provider]

        if provider_obj and provider_obj.get_models_from_api then
            provider_obj:get_models_from_api(function(dynamic_models, err)
                if err then
                    vim.notify("Failed to fetch models: " .. err, vim.log.levels.ERROR)
                    return
                end

                if #dynamic_models > 0 then
                    M._show_model_picker(dynamic_models, provider)
                else
                    vim.notify("No models available for " .. provider, vim.log.levels.WARN)
                end
            end)
            return
        end
    end

    if #models > 0 then
        M._show_model_picker(models, provider)
    else
        vim.notify("No models configured for " .. provider, vim.log.levels.WARN)
    end
end

M._show_model_picker = function(models, provider)
    pickers.new({}, {
        prompt_title = 'Select ' .. provider .. ' Model',
        finder = finders.new_table({
            results = models,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                nochat.set_model(selection.value)
            end)
            return true
        end,
    }):find()
end

M.select_model = function()
    local current_provider = nochat.active_session_id and
        require('nochat.session').get(nochat.active_session_id).provider or
        nochat.config.provider

    M.select_model_by_provider(current_provider)
end

M.select_provider_for_session = function(session_id)
    if not session_id then
        -- Try to get current session
        local win = require('nochat.window')
        local session = win.get_current_session()
        if session then
            session_id = session.id
        else
            session_id = nochat.active_session_id
        end
    end

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    local session = require('nochat.session').get(session_id)
    if not session then
        vim.notify("Invalid session ID", vim.log.levels.ERROR)
        return
    end

    local providers = {}
    for provider, _ in pairs(nochat.config.providers) do
        table.insert(providers, provider)
    end

    table.sort(providers)

    pickers.new({}, {
        prompt_title = 'Select Provider for ' .. session.title,
        finder = finders.new_table({
            results = providers,
            entry_maker = function(entry)
                -- Mark current provider
                local display = entry
                if entry == session.provider then
                    display = entry .. " (current)"
                end

                return {
                    value = entry,
                    display = display,
                    ordinal = entry,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()

                -- Always trigger model selection, regardless of whether provider changed
                require('nochat.session').set_provider(session.id, selection.value)

                vim.defer_fn(function()
                    M.select_model_for_session(session.id)
                end, 100) -- Small delay for better UX
            end)
            return true
        end,
    }):find()
end

M.select_model_for_session = function(session_id)
    if not session_id then
        -- Try to get current session
        local win = require('nochat.window')
        local session = win.get_current_session()
        if session then
            session_id = session.id
        else
            session_id = nochat.active_session_id
        end
    end

    if not session_id then
        vim.notify("No active chat session", vim.log.levels.ERROR)
        return
    end

    local session = require('nochat.session').get(session_id)
    if not session then
        vim.notify("Invalid session ID", vim.log.levels.ERROR)
        return
    end

    local current_provider = session.provider
    local providers = require('nochat.providers')
    local provider = providers.loaded[current_provider]

    if not provider then
        vim.notify("Provider " .. current_provider .. " not loaded", vim.log.levels.ERROR)
        return
    end

    -- Directly use models from config
    local models = nochat.config.providers[current_provider].models or
        (provider.get_models and provider:get_models()) or
        {}

    -- Function to show model selection
    local function show_models(model_list)
        if #model_list > 0 then
            M._show_model_selection(current_provider, model_list, session)
        else
            vim.notify("No models available for " .. current_provider, vim.log.levels.WARN)
        end
    end

    -- If no models found in config, try dynamic fetching
    if #models == 0 and provider.get_models_from_api then
        provider:get_models_from_api(function(dynamic_models, err)
            if err then
                vim.notify("Failed to fetch models: " .. err, vim.log.levels.ERROR)
                return
            end

            show_models(dynamic_models or {})
        end)
    else
        -- Show models from config or provider method
        show_models(models)
    end
end

M._show_model_selection = function(provider_name, models, session)
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    pickers.new({}, {
        prompt_title = 'select ' .. provider_name .. ' model for ' .. session.title,
        finder = finders.new_table({
            results = models,
            entry_maker = function(entry)
                -- mark current model
                local display = entry
                if entry == session.model then
                    display = entry .. " (current)"
                end

                return {
                    value = entry,
                    display = display,
                    ordinal = entry,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                require('nochat.session').set_model(session.id, selection.value)
            end)
            return true
        end,
    }):find()
end

return M

