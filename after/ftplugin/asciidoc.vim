" Asciidoc simple outline folding
" enable folding:
" - all folds closed gives outline of document
" - toggle a fold with spacebar or going to insert mode
" - fold is moved to middle of the screen (z.)
" - zi toggles close all folds
"setlocal foldexpr=getline(v:lnum)=~'^\=\=\='?'>2':getline(v:lnum)=~'^\=\='?'>1':'2'
setlocal foldexpr=getline(v:lnum)=~'^\='?'>1':'>2'
setlocal foldmethod=expr
setlocal foldopen=insert " insert mode opens fold
" setlocal foldclose=all
set foldclose=""
set nofoldenable
nnoremap <space> za0z. " toggle fold, move to middle of screen (z.)

