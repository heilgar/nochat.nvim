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

M.select_model = function()
    local current_provider = nochat.config.provider
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

return M

