"BufEnter is not called when switching between buffers in a window
"- only when moving cursor to a window showing a buffer
"Notes:
"- use echo b:<CR> to see all buffer local variables
"au BufHidden   * call noom#DeleteOutline('')
au BufWinLeave  * call voom#DeleteOutline('')
au BufWinEnter * call My_Voom_Restore()
"au BufHidden * echomsg "BufHidden " . bufname('%')
"au BufWinLeave * echomsg "BufWinLeave " . bufname('%')

"we set mapping in .vimrc
"nmap <silent> <leader>v :call My_Voom_Toggle()<CR>

let s:FT2MARKUP={'rst' : 'wiki',
            \'rest'    : 'wiki',
            \'python'  : 'python',
            \'pandoc'  : 'pandoc',
            \'asciidoc': 'asciidoc',
            \'txt'     : 'wiki',
            \'css'     : 'css',
            \'confg'   : 'confg'}

fun! My_Voom_Toggle()

    if exists("b:voomified")
        "we're in a body buffer that has an outline, delete & forget it
        unlet b:voomified
        call voom#DeleteOutline('')
        return
    endif

   if bufnr(bufname('%')."_VOOM".bufnr('%'))>-1
        "we're in a body buffer with a voomtree
        call voom#DeleteOutline('')
        return
    endif

    if &filetype ==? "voomtree"
        "we're in a Voom Tree buffer, it should be safe to call Voom nav funcs
        call voom#ToTreeOrBodyWin()
        call voom#DeleteOutline('')
        if exists("b:voomified")
            unlet b:voomified
        endif
        return
    endif

    "create outline, leave voomified marker
    call My_Voom_Outline()
endfunction

fun! My_Voom_Restore()
    "called on BufWinEnter, if buffer local variable b:voomified
    "exists an Outline should be (re)created
    if exists("b:voomified")
        call My_Voom_Outline()
    endif
endfunction

fun! My_Voom_Outline()
    "create filetype specific voom treebuf, mark body buf as voomified
    if &filetype ==? 'voomtree'
        return
    endif
    let b:voomified=1
    let VOOMCMD = ":Voom "
    " use special voom_mode for filetype (if any)
    if has_key(s:FT2MARKUP, tolower(&filetype))
        let VOOMCMD .= s:FT2MARKUP[&filetype]
    else
        let VOOMCMD .= '' " don't append &filetype by default ..
    endif
    " create the tree outline window
    :exe VOOMCMD
    " open all folds recursively
    normal! zR
    " back to body window
    call voom#ToTreeOrBodyWin()
    return
endfunction

