if exists('g:loaded_nochat')
    finish
endif
let g:loaded_nochat = 1

" Set up basic commands
command! NoChatOpen lua require('nochat').open()
command! NoChatClose lua require('nochat').close()
command! NoChatToggle lua require('nochat').toggle()
command! NoChatSelectProvider lua require('nochat.telescope').select_provider()
command! NoChatSelectModel lua require('nochat.telescope').select_model()
command! NoChatClearConversation lua require('nochat').clear_conversation()

" Window positioning commands
command! -nargs=1 -complete=customlist,NoChatPositionComplete NoChatPosition lua require('nochat').set_window_position(<f-args>)
function! NoChatPositionComplete(ArgLead, CmdLine, CursorPos)
    return filter(['floating', 'right', 'left', 'bottom', 'top', 'tab'], 'v:val =~ a:ArgLead')
endfunction

" Multi-window commands
command! NoChatNew lua require('nochat').new_chat()
command! NoChatNewTab lua require('nochat').new_chat({position = "tab"})
command! NoChatNewFloat lua require('nochat').new_chat({position = "floating"})
command! NoChatNewRight lua require('nochat').new_chat({position = "right"})
command! NoChatNewLeft lua require('nochat').new_chat({position = "left"})
command! NoChatNewTop lua require('nochat').new_chat({position = "top"})
command! NoChatNewBottom lua require('nochat').new_chat({position = "bottom"})
command! NoChatSelectSession lua require('nochat').select_session()
command! NoChatDeleteSession lua require('nochat').delete_session()
command! NoChatCloseAll lua require('nochat').close_all()
command! NoChatRenameSession lua require('nochat.window').prompt_rename()

" Session provider/model commands
command! -nargs=1 NoChatSessionProvider lua require('nochat').set_provider(<f-args>)
command! -nargs=1 NoChatSessionModel lua require('nochat').set_model(<f-args>)

" Default configurations
let g:nochat_default_provider = get(g:, 'nochat_default_provider', 'anthropic')
let g:nochat_default_model = get(g:, 'nochat_default_model', 'claude-3-sonnet-20240229')
let g:nochat_api_key_anthropic = get(g:, 'nochat_api_key_anthropic', '')
let g:nochat_api_key_openai = get(g:, 'nochat_api_key_openai', '')
let g:nochat_ollama_host = get(g:, 'nochat_ollama_host', 'http://localhost:11434')

" Set up autocommands if needed
augroup nochat
    autocmd!
    " Set up highlighting
    autocmd ColorScheme * lua require('nochat.window.ui').setup_highlights()
augroup END

" Setup keymappings (these will be overridden by lua/nochat/keymap.lua if loaded)
if !exists('g:nochat_no_default_mappings')
    nnoremap <silent> <leader>nc :NoChatToggle<CR>
    nnoremap <silent> <leader>np :NoChatSelectProvider<CR>
    nnoremap <silent> <leader>nm :NoChatSelectModel<CR>
    nnoremap <silent> <leader>nn :NoChatNew<CR>
    nnoremap <silent> <leader>ns :NoChatSelectSession<CR>
    nnoremap <silent> <leader>nD :NoChatDeleteSession<CR>
    nnoremap <silent> <leader>nr :NoChatRenameSession<CR>
endif

