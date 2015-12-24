" Mappings for man page view.
" - Some 'help/man' buffers (eg pydoc) donot have filetype 'man'
"   The augroup QuitNoFile in dotvimrc aims to tackle the others.

" make q quit the man page immediately
map <buffer> q <esc>:q<CR>
