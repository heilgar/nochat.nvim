if exists('g:loaded_nochat')
    finish
endif
let g:loaded_nochat = 1

" Set up commands
command! NoChatOpen lua require('nochat').open()
command! NoChatClose lua require('nochat').close()
command! NoChatToggle lua require('nochat').toggle()
command! NoChatSelectProvider lua require('nochat.telescope').select_provider()
command! NoChatSelectModel lua require('nochat.telescope').select_model()

" Default configurations
let g:nochat_default_provider = get(g:, 'nochat_default_provider', 'anthropic')
let g:nochat_default_model = get(g:, 'nochat_default_model', 'claude-3-sonnet-20240229')
let g:nochat_api_key_anthropic = get(g:, 'nochat_api_key_anthropic', '')
let g:nochat_api_key_openai = get(g:, 'nochat_api_key_openai', '')
let g:nochat_ollama_host = get(g:, 'nochat_ollama_host', 'http://localhost:11434')

" Set up autocommands if needed
augroup nochat
    autocmd!
    " Example: highlight nochat windows differently
    " autocmd FileType nochat setlocal winhighlight=Normal:NoChatNormal
augroup END

" Setup keymappings (these can be customized by the user)
if !exists('g:nochat_no_default_mappings')
    nnoremap <silent> <leader>nc :NoChatToggle<CR>
    nnoremap <silent> <leader>np :NoChatSelectProvider<CR>
    nnoremap <silent> <leader>nm :NoChatSelectModel<CR>
endif

