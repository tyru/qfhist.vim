scriptencoding utf-8

if exists('g:loaded_qfhist')
  finish
endif
let g:loaded_qfhist = 1

let s:save_cpo = &cpo
set cpo&vim


if get(g:, 'qfhist_auto_save', 1)
    augroup qfhist-auto
        autocmd!
    augroup END
    autocmd qfhist-auto QuickfixCmdPost [^l]*
    \   call qfhist#save_qflist()
    autocmd qfhist-auto QuickfixCmdPost [l]*
    \   call qfhist#save_loclist(0)
endif

let g:qfhist_max_history_count =
\   get(g:, 'qfhist_max_history_count', 15)


command! -bar -nargs=+
\   -complete=customlist,qfhist#__cmd_complete__
\   QFHistSetLocal
\   call qfhist#set_local_history(0, matchstr(<q-args>, '^\s*\zs\d\+'))

command! -bar -nargs=+
\   -complete=customlist,qfhist#__cmd_complete__
\   QFHistOpenLocal
\   call qfhist#open_local_history(0, matchstr(<q-args>, '^\s*\zs\d\+'))

command! -bar -nargs=+
\   -complete=customlist,qfhist#__cmd_complete__
\   QFHistSet
\   call qfhist#set_history(matchstr(<q-args>, '^\s*\zs\d\+'))

command! -bar -nargs=+
\   -complete=customlist,qfhist#__cmd_complete__
\   QFHistOpen
\   call qfhist#open_history(matchstr(<q-args>, '^\s*\zs\d\+'))

command! -bar -nargs=0
\   QFHistClear
\   call qfhist#clear()


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
