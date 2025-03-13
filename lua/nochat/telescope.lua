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
                nochat.set_provider(selection.value)
            end)
            return true
        end,
    }):find()
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
                require('nochat.session').set_provider(session_id, selection.value)
            end)
            return true
        end,
    }):find()
end

M.select_model = function()
    local current_provider = nochat.active_session_id and
        require('nochat.session').get(nochat.active_session_id).provider or
        nochat.config.provider

    local models = nochat.config.providers[current_provider].models

    pickers.new({}, {
        prompt_title = 'Select ' .. current_provider .. ' Model',
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
    local models = nochat.config.providers[current_provider].models

    pickers.new({}, {
        prompt_title = 'Select ' .. current_provider .. ' Model for ' .. session.title,
        finder = finders.new_table({
            results = models,
            entry_maker = function(entry)
                -- Mark current model
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
                require('nochat.session').set_model(session_id, selection.value)
            end)
            return true
        end,
    }):find()
end

M.register_extension = function()
    return {
        exports = {
            provider = M.select_provider,
            model = M.select_model,
            sessions = nochat.select_session,
            new_chat = function() nochat.new_chat() end,
        }
    }
end

return M

