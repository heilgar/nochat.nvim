# NoChat.nvim

NoChat is a Neovim plugin that enables chat abilities with various AI providers directly in your editor. Seamlessly interact with Claude, ChatGPT, or local Ollama models without leaving your workflow.

## Features

- 🤖 Support for multiple AI providers:
  - Anthropic (Claude)
  - OpenAI (ChatGPT)
  - Ollama (local models)
- 🔍 Easy provider and model selection via Telescope
- 💬 Interactive chat interface within Neovim
- 📋 Export selected text to chat
- 📢 Configurable window positioning (floating, split, tab)
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
        position = "floating", -- "floating", "right", "left", "bottom", "top", "tab"
        width = 0.8,     -- Percentage of screen width
        height = 0.7,    -- Percentage of screen height
        border = "rounded",
        title = " NoChat ",
        input_height = 5, -- Height of input box in lines
        winhighlight = {
            output = "", -- e.g. "Normal:NoChatOutput"
            input = ""   -- e.g. "Normal:NoChatInput"
        }
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
        clear_conversation = "<leader>nc",
        export_selection = "<leader>ne",
        position_floating = "<leader>nf",
        position_right = "<leader>nr",
        position_left = "<leader>nl",
        position_bottom = "<leader>nb",
        position_top = "<leader>nt",
        position_tab = "<leader>nn",
    },

    -- Set to true to disable default keymaps
    no_default_keymaps = false,
})
```

## Window Configuration

NoChat provides a highly customizable chat interface that can be positioned in various ways within Neovim:

### Window Position Options

You can configure NoChat's window position in your setup with the `window.position` option. Each position mode offers different advantages:

- **floating**: A centered popup window that floats above your content (default)
- **right/left**: Vertical split on the right or left side
- **top/bottom**: Horizontal split at the top or bottom
- **tab**: Opens in a new tab

### Changing Position Dynamically

You can also change the window position at runtime:

```lua
-- Change to a left split
:lua require('nochat').set_window_position('left')

-- Change to floating mode
:lua require('nochat').set_window_position('floating')
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
- `:NoChatClearConversation` - Clear the current conversation history
- `:NoChatPosition <position>` - Change the window position (with tab completion)

### Default Keymaps

NoChat comes with the following default keymaps:

#### Global Keymaps

- `<leader>nc` - Toggle chat window
- `<leader>nd` - Celar current conversation
- `<leader>np` - Select provider
- `<leader>nm` - Select model
- `<leader>ne` - Export selected text to chat (in visual mode)

#### Window Position Keymaps

- `<leader>nf` - Set window to floating layout
- `<leader>nr` - Set window to right split
- `<leader>nl` - Set window to left split
- `<leader>nb` - Set window to bottom split
- `<leader>nt` - Set window to top split
- `<leader>nn` - Set window to tab layout

#### Chat Input Window Keymaps

- `<CR>` (normal mode) - Send message
- `<C-CR>` (insert mode) - Send message
- `<M-CR>` (Alt+Enter, insert mode) - Insert newline without sending

You can disable default keymaps by setting `no_default_keymaps = true` in your configuration or `let g:nochat_no_default_mappings = 1` in your Vim config.

### Telescope Integration

You can also access NoChat features from Telescope:

```vim
:Telescope nochat provider
:Telescope nochat model
```

## License

MIT

