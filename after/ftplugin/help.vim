" See http://vim.wikia.com/wiki/Learn_to_use_help
" <cr> to select/goto topic under cursor
nnoremap <buffer> <CR> <C-]>
" <bs> to return to previous topic
nnoremap <buffer> <BS> <C-T>
" q immediately quits the help window
nnoremap <buffer> q :q<CR>
" o goto next option
nnoremap <buffer> o /'\l\{2,\}'<CR>
" O goto previous option
nnoremap <buffer> O ?'\l\{2,\}'<CR>
" s goto next section
nnoremap <buffer> s /\|\zs\S\+\ze\|<CR>
" S goto previous section
nnoremap <buffer> S ?\|\zs\S\+\ze\|<CR>

