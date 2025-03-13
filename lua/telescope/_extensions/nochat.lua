local telescope = require('telescope')
local nochat_telescope = require('nochat.telescope')

return telescope.register_extension({
    exports = {
        select_provider = nochat_telescope.select_provider,
        select_model = nochat_telescope.select_model,
    },
})

