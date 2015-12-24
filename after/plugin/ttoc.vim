" after/plugin/ttoc.vim
" See also:
" * ~/.vim/bundle/tlib_vim/  : the library by Tom Link
" * ~/.vim/bundle/ttoc_vim/  : an table-of-contents application of tlib
" Provides:
" * different highlights in the tlib#input#List [TLIBINPUTLIST] - windows
"
" Globs {{{1

" tlibInputList au-cmds {{{1
" In a tlibInputList buffer:
" * turn off cursorline hl since Vim line 1 always has 'current position'
" * turn off line numbers: tlib already numbers the lines itself
" * turn off highlighting trailing spaces, it's distracting
" * In a tLibInputList, lines may have the following format:
" |<idxnr>[*#:]: [<linenr>: ]<line>
" , where *=current line, # = selected, : normal
"   - <linenr>:\s <- is not there if lines didn't come from a file
"   - <idxnr>* denotes current line
"   - <idxnr># denotes a selected line
"   - <idxnr>: denotes a non-current/non-selected line (ie normal)
" at the time where filetype is set, InputlListIndex is not defined yet.
fun! PdhTlibInfo() "{{{2
   echom 'current bufname is  ' . bufname('%')
   echom 'current buftype is  ' . &buftype
   echom 'current filetype is ' . &ft
   if exists('b:pdh') | let b:pdh = b:pdh + 1 | else | let b:pdh = 1 | endif
   for line in tlib#cmd#OutputAsList('let b:')
       echom 'b:var: ' . line
   endfor
   for line in tlib#cmd#OutputAsList('let w:')
       echom 'w:var: ' . line
   endfor
   for line in tlib#cmd#OutputAsList('syntax')
       echom line
   endfor
endfun


" tlibInputList colors {{{1
" InputlListNormal does not seem to work in an tlibInputList buffer ??
"syntax match InputlListNormal /^\d\+: .*$/ contains=InputlListIndex
"hi def link InputlListNormal Comment
" Redefine tlib's colors for tlibInputList window (see tlib's World.vim)

" TLet g:tlib_viewline_position = "zt"
" remarks:
" 1) Tlet g:tlib_viewline_position = "zt" seem to have no effect.
"    Actually, tlib#agent#PreviewLine calls tlib#buffer#ViewLine with a
"    hardcoded position which makes the latter ignore the setting (it is used
"    as default value in case no position parameter is provided i/t call to
"    tlib#buffer#ViewLine).
"    So I need to jump to win_wnr, exec zt and then return to ttoc window
" 2) Dunno howto add (2) additional key_handlers to gttoc_world.key_handlers
"    So ttoc_world is redefined as a whole (hmmm..)

" InputList keyhandlers {{{1
function! MyTtocZtWin(world) "{{{2
    " scroll selected line in source buffer to zt see |scroll-cursor|
    " tlib#agent#PreviewLine(world,selected) has call to tlib#buffer#ViewLine
    "   with hardcoded position for scrolling the selected line on screen.
    "   i.e. it makes tlib#buffer#ViewLine ignore it's g:tlib_viewline_position
    " so we rewrite it here for our Up/DownAndPreview
    let wnr = winnr()
    exec a:world.win_wnr.'wincmd w'
    exec 'norm! z.'
    " maybe use g:tlib_viewline_position instead of hardcoded zt?
    exec wnr.'wincmd w'
    "is supposed to be local to the window, but somehow it won't turn off?
    "in the TToC __InputList__ window ... arghhh!!!
    setlocal nocursorline
    return a:world
endf

function! MyTtocDownAndPreview(world, selected) "{{{2
    let w = tlib#agent#Down(a:world, a:selected)
    let s = w.GetSelectedItems(w.CurrentItem())
    let w = tlib#agent#PreviewLine(w,s)
    return MyTtocZtWin(w)
endf

function! MyTtocUpAndPreview(world, selected) "{{{2
    let w = tlib#agent#Up(a:world, a:selected)
    let s = w.GetSelectedItems(w.CurrentItem())
    let w = tlib#agent#PreviewLine(w, s)
    return MyTtocZtWin(w)
endf

function! MyTtocPreview(world, selected) "{{{2
    echom 'MyTtocPreview called ' . string(a:selected)
    let w = tlib#agent#PreviewLine(a:world, a:selected)
    echom line('.') . ','. col('.') . ' has ' . synIDattr(synID(line('.'),col('.'),1),'name')
    return MyTtocZtWin(w)
endf

" xxx_Nth funcs {{{1
fun! Add_Nth(lnr, nth) "{{{2
    " highlight Nth word (non-white-sequence) on line lnr & return matched WORD
    " * nth-counter is zero based
    " * lnr is 1-based (line nr 0 does not exist).
    " * use lnr=0 to highlight nth WORD on ALL lines
    let w:NTH_MID = Del_Nth()            " delete previous highlight if any
    " build expr in two parts: matchadd needs to match line nr as well
    let line_expr = '\V\s\*\(\S\+\s\+\)\{'.a:nth.'}\zs\S\+'
    let buff_expr = a:lnr>0 ? '^\%'.a:lnr.'l'.line_expr : '^'.line_expr
    try
        let w:NTH_MID = matchadd('hl_nth_word', buff_expr, 200, w:NTH_MID)
    catch /.*/
        " w:NTH_MID might be 0 (no previous highlight yet)
        let w:NTH_MID = matchadd('hl_nth_word', buff_expr, 200)
    endtry
    if a:lnr > 0
        return matchstr(getline(a:lnr), '^'.line_expr)
    else
        return map(getline(1,'$'), "matchstr(v:val,'^'.line_expr)")
    endif
endfun

fun! Del_Nth() "{{{2
    " remove match that was added for group 'hl_nth_word', returns id.
    " note: id's in getmatches() are > 0
    for g in getmatches()
        if g.group ==? 'hl_nth_word'  " match case insensitive
            call matchdelete(g.id)
            return g.id
        endif
    endfor
    return 0
endfun

let s:NTH_MINCOL = 1
fun! Nxt_Nth() "{{{2
    " round robin highlight WORD on current line.
    let w:NTH_COL = exists('w:NTH_COL') ? w:NTH_COL + 1 : s:NTH_MINCOL
    let nth_word = Add_Nth(line('.'), w:NTH_COL)
    if len(nth_word) < 1
        let w:NTH_COL = s:NTH_MINCOL
        let nth_word = Add_Nth(line('.'), w:NTH_COL)
    endif
    return nth_word
endfun

fun! Sel_Nth_R(world, selected) "{{{2
    " select next WORD on current line in inputlist buffer
    let w:NTH_COL = exists('w:NTH_COL') ? w:NTH_COL + 1 : s:NTH_MINCOL
    let b:nth_word = Add_Nth(a:world.prefidx, w:NTH_COL)
    if len(b:nth_word) < 1
        let w:NTH_COL = s:NTH_MINCOL
        let b:nth_word = Add_Nth(a:world.prefidx, w:NTH_COL)
    endif
    let a:world.state = 'redisplay'
    return a:world
endfun

fun! Sel_Nth_L(world, selected) "{{{2
    " select next WORD on current line in inputlist buffer
    let w:NTH_COL = exists('w:NTH_COL') ? w:NTH_COL - 1 : s:NTH_MINCOL
    if w:NTH_COL < s:NTH_MINCOL
        " this should be a split on current selected line, not current line
        " the two are different (current line is always line 1)
        let w:NTH_COL = len(split(a:selected[0]))
    endif
    let b:nth_word = Add_Nth(a:world.prefidx, w:NTH_COL)
    if len(b:nth_word) < 1
        let w:NTH_COL = s:NTH_MINCOL
        let b:nth_word = Add_Nth(a:world.prefidx, w:NTH_COL)
    endif
    let a:world.state = 'redisplay'
    return a:world
endfun

" Ret_Nth {{{2
" Use this as 'return_agent' in a tlib#World#New(dict) object
" d = {'return_agent': 'Ret_Nth', .... }
" w = tlib#World#New(d)
" c = tlib#input#ListW(w) -> gets you a field or line
fun! Ret_Nth(w,s)
    "Return Nth word if present, a:selected otherwise
    try
        let nth = getbufvar(a:w.scratch,'nth_word')
        if len(nth)>0 | return nth | endif
    catch /.*/
        " don't error out here, simpy fall through
    endtry
    return a:s
endfun

" Custom Keyhandlers {{{1
" custom keyhandlers for tlib's inputlist handler.  See 
" ~/.vim/bundle/tlib/autoload/tlib/input.vim:123 for info
" Actual keycodes are not easy to find ...:
" echo char2nr("	")     -> 9, where  "	"= C-v, Tab
" echo char2nr("\<tab>")   -> 9
" echo char2nr("[Z")     -> 27, where [Z = C-v, Shift-Tab
" echo char2nr("\<S-Tab>") -> 128
"   \ 10: 'MyTtocDownAndPreview',
"   \ 11: 'MyTtocUpAndPreview',
" Note: char2nr("\<S-Tab>") doesn't seem to work here
let g:tlib_extend_keyagents_InputList_s = {
    \ char2nr("\<c-j>"): 'tlib#agent#Down',
    \ char2nr("\<c-k>"): 'tlib#agent#Up',
    \ char2nr("\<tab>"): 'Sel_Nth_R',
    \ char2nr("\<c-l>"): 'Sel_Nth_R',
    \ char2nr("\<c-h>"): 'Sel_Nth_L',
    \ char2nr("\<c-v>"): 'MyTtocPreview',
    \ char2nr("\<c-p>"): 'MyTtocPreview',
    \ "\<S-Tab>": 'Sel_Nth_L',
    \ }

"\ "\<up>": 'MyTtocUpAndPreview',
"\ "\<down>": 'MyTtocDownAndPreview'
" When in a file with actions ([/# ]*[oOxXcC]\sAction description; PHE
" hit ,a to list open actions and scroll+preview with <c-j>, <down>,<c-k>,<up>
"
"o open action
"o a third action
"o open another action
