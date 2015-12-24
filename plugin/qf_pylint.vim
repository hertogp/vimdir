" MyPyLint plugin
" pdh
" v0.3, 2012-01-15

" quickfix notes {{{1
" - requires: `sudo apt-get install pylint`
" - item.type: only 1 char of string is used & mapped to 'error' by vim
" - item.col: 0 means no column info will be shown (col>0)
" - item.nr: 0 means no line information is shown (line>0)
" - call matchadd('SpellBad','E\d\{4}') to highlight errors in item.text
"   -> cclose | copen => highlights are gone again
" - &buftype = quickfix
" - &filetype = qf
" - set verbose = 9 to see autocommands being executed

"
" OPTIONS {{{1

" PYLINT pipeline {{{2
let s:pylintcmd = 'pylint -rn -iy -ftext '
let s:pylintefm = '%t%n:\ %#%l\,\-%#%c:%m'


function! <SID>MPL() "{{{1
    " close qfwindow if any, save src if we can
  cclose
  if &readonly == 0 | update | endif
  set lazyredraw

  " set errorformat for pylint, call system cmd & restore errorformat again
  let [efm_org, &efm] = [&efm, s:pylintefm]
  let [fname, fbufnr] = [expand('%:p'), bufnr('%')]
  cexpr system(s:pylintcmd . shellescape(fname))
  let &efm = efm_org

  " qf-items need fixing: colnrs are off by one and we add the pyfile's bufnr
  let qfl = s:qf_fix(getqflist(),fbufnr)
  call setqflist(filter(qfl, 's:qf_filter(v:val)'))

  set nolazyredraw
  redraw!

  " echo summary msg in Greenbar/Redbar [xE yW ..] = z total
  call s:qf_summary(qfl)
endfunction

function! s:qf_fix(qfl,bufnr) "{{{1
    " set the bufnr of the py-file in each item, and
    " increment the column nr by one (vim is 1-based,  pylint is 0-based)
    for item in a:qfl
        let item.bufnr = a:bufnr
        let item.col = item.col < 0 ? 1 : item.col + 1
    endfor
    return a:qfl
endfunction

function! s:qf_filter(item) "{{{1
    if len(a:item.type) && stridx("EW",a:item.type)>-1 | return 1 | endif
    return 0
endfunction

function! s:qf_summary(qfl) "{{{1
    if empty(a:qfl)
        echohl GreenBar
        echomsg "Well done!"
        echohl None
        cclose
    else
        let h = {}
        for itm in a:qfl
            let h[itm.type] = get(h,itm.type,0) + 1
        endfor
        let msg = join(map(items(h),'join(reverse(v:val),"")'),' ')
        echohl RedBar
        echomsg printf('Pylint [%s] = %d total',msg,len(a:qfl))
        echohl None
        execute 'copen '.string(len(a:qfl)<10 ? len(a:qfl) : 10)
        normal gg
        nohl
        call s:himatch()
    endif
endfunction

function! s:himatch() "{{{1
      call matchadd('ErrorMsg','|\zsE[^|]*\ze|')
      call matchadd('WarningMsg','|\zsW[^|]*\ze|')
      call matchadd('LineNr','|\zsC[^|]*\ze|')
      call matchadd('Special','|\zsR[^|]*\ze|')
      " in err text 'name', or "name" or name: ...
      call matchadd('Identifier',"'[^']*'")
      call matchadd('String','"[^"]*"')
      call matchadd('Function','|\s\+\zs[^|:]*\ze:')
endfunction


" KEY MAPS {{{1
" --------
exe 'nnoremap <silent> <F2> :call <SID>MPL()<cr>'

" Greenbar for success {{{2
if !hlexists('GreenBar')
  hi GreenBar term=reverse ctermfg=white ctermbg=darkgreen
              \ guifg=white guibg=darkgreen
endif

" RedBar for complaints {{{2
if !hlexists('RedBar')
 hi RedBar term=reverse ctermfg=white ctermbg=red 
             \ guifg=white guibg=red
endif

