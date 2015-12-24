" QuickFix buffer commands
" pdh
" v0.1, dec 2011

" q to quit qf window directly
map <buffer> q :q<CR>
" space shows error in buffer (maintain position in qf window)
" - uses register m to mark (mm)  position before leaving qf window
" - z. to put current line in both windows i/t middle of the window
map <buffer> <space> <esc>mm<CR>z.<c-w>p'mz.
" up/down also immediately show error in buffer
map <buffer> <up> k<space>
map <buffer> <down> j<space>
map <buffer> <c-k> k<space>
map <buffer> <c-j> j<space>
