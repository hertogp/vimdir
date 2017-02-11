" file: ~/.vim/after/compiler/pandoc.vim
" Set makeprg to proper call to pandoc with extra options:
" - use -f markdown+extension1+extension2+..
" - use latex
" - use template notes found in ~/.pandoc/templates/notes.latex
" - output pdf to <filename sans extenstion>.pdf (ie the %:r.pdf)
" - compile the current buffer using the full absolute path to it's file (%)
"
"CompilerSet makeprg=pandoc\ -f\ markdown+hard_line_breaks+compact_definition_lists+lists_without_preceding_blankline+pipe_tables\ -t\ latex\ --template\ notes\ -o\ %:r.pdf\ %
CompilerSet makeprg=pandoc\ -f\ markdown+line_blocks+compact_definition_lists+lists_without_preceding_blankline+pipe_tables\ -t\ latex\ --template\ notes\ -o\ %:r.pdf\ %
