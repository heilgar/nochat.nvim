# NoChat.nvim

NoChat is a Neovim plugin that enables chat abilities with various AI providers directly in your editor. Seamlessly interact with Claude, ChatGPT, or local Ollama models without leaving your workflow.

## Features

- 🤖 Support for multiple AI providers:
  - Anthropic (Claude)
  - OpenAI (ChatGPT)
  - Ollama (local models)
- 🔍 Easy provider and model selection via Telescope
- 💬 Interactive chat interface within Neovim
- 🤩 Simple API for adding additional providers

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "heilgar/nochat.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("nochat").setup({
            -- Your configuration here (see Configuration section)
        })
    end
}
```

### Using packer.nvim

```lua
use {
    "heilgar/nochat.nvim",
    requires = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("nochat").setup({
            -- Your configuration here (see Configuration section)
        })
    end
}
```

## Configuration

NoChat comes with sensible defaults but can be fully customized:

```lua
require("nochat").setup({
    -- Default provider and model (will be overridden by telescope selections)
    provider = "anthropic", -- or "openai", "ollama"
    model = "claude-3-sonnet-20240229",

    -- Window appearance
    window = {
        width = 0.8,     -- Percentage of screen width
        height = 0.7,    -- Percentage of screen height
        border = "rounded",
        title = " NoChat ",
    },

    -- API keys (can also be set as environment variables)
    api_keys = {
        anthropic = "your-anthropic-api-key", -- or use ANTHROPIC_API_KEY env var
        openai = "your-openai-api-key", -- or use OPENAI_API_KEY env var
    },

    -- Ollama configuration
    ollama = {
        host = "http://localhost:11434", -- Default Ollama server address
    },

    -- Define available models for each provider
    providers = {
        anthropic = {
            models = {
                "claude-3-opus-20240229",
                "claude-3-sonnet-20240229",
                "claude-3-haiku-20240307",
            },
        },
        openai = {
            models = {
                "gpt-4-turbo",
                "gpt-4",
                "gpt-3.5-turbo",
            },
        },
        ollama = {
            models = {
                "llama3",
                "mistral",
                "gemma",
                "codellama",
            },
        },
    },

    -- Keymaps (set to false to disable defaults)
    keymaps = {
        toggle = "<leader>nc",
        select_provider = "<leader>np",
        select_model = "<leader>nm",
    },

    -- Set to true to disable default keymaps
    no_default_keymaps = false,
})
```

## Global Variables

You can also configure NoChat using global variables in your `init.vim`/`init.lua`:

```vim
" Default provider and model
let g:nochat_default_provider = 'anthropic'
let g:nochat_default_model = 'claude-3-sonnet-20240229'

" API keys
let g:nochat_api_key_anthropic = 'your-anthropic-api-key'
let g:nochat_api_key_openai = 'your-openai-api-key'

" Ollama host
let g:nochat_ollama_host = 'http://localhost:11434'

" Disable default keymaps
let g:nochat_no_default_mappings = 1
```

## Usage

### Commands

NoChat provides the following commands:

- `:NoChatToggle` - Open or close the chat window
- `:NoChatOpen` - Open the chat window
- `:NoChatClose` - Close the chat window
- `:NoChatSelectProvider` - Open Telescope to select a provider
- `:NoChatSelectModel` - Open Telescope to select a model for the current provider

### Default Keymaps

NoChat comes with the following default keymaps:

- `<leader>nc` - Toggle chat window
- `<leader>np` - Select provider
- `<leader>nm` - Select model

You can disable default keymaps by setting `no_default_keymaps = true` in your configuration or `let g:nochat_no_default_mappings = 1` in your Vim config.

### Telescope Integration

You can also access NoChat features from Telescope:

```vim
:Telescope nochat provider
:Telescope nochat model
```

## License

MIT

