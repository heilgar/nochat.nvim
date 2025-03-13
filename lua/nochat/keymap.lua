local M = {}

M.defaults = {
    toggle = "<leader>nc",          -- Toggle chat window
    select_provider = "<leader>np", -- Select AI provider
    select_model = "<leader>nm",    -- Select model for current provider
}

M.setup_keymaps = function(opts)
    if vim.g.nochat_no_default_mappings == 1 or (opts and opts.no_default_keymaps) then
        return
    end

    local keymaps = (opts and opts.keymaps) or M.defaults

    local telescope = require('nochat.telescope')

    vim.keymap.set('n', keymaps.toggle or M.defaults.toggle,
        function() require('nochat').toggle() end,
        { noremap = true, silent = true, desc = "Toggle NoChat" })

    vim.keymap.set('n', keymaps.select_provider or M.defaults.select_provider,
        function() telescope.select_provider() end,
        { noremap = true, silent = true, desc = "Select NoChat Provider" })

    vim.keymap.set('n', keymaps.select_model or M.defaults.select_model,
        function() telescope.select_model() end,
        { noremap = true, silent = true, desc = "Select NoChat Model" })
end

return M

