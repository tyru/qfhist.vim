scriptencoding utf-8

if exists('g:loaded_qfsavehist')
  finish
endif
let g:loaded_qfsavehist = 1

let s:save_cpo = &cpo
set cpo&vim


if get(g:, 'qfsavehist_auto_save', 1)
    augroup qfsavehist-auto
        autocmd!
    augroup END
    autocmd qfsavehist-auto QuickfixCmdPost [^l]*
    \   call qfsavehist#save_qflist()
    autocmd qfsavehist-auto QuickfixCmdPost [l]*
    \   call qfsavehist#save_loclist(0)
endif

let g:qfsavehist_max_history_count =
\   get(g:, 'qfsavehist_max_history_count', 15)


command! -bar -nargs=+
\   -complete=customlist,qfsavehist#__cmd_complete__
\   QFSetLocalHistory
\   call qfsavehist#set_local_history(0, matchstr(<q-args>, '^\s*\zs\d\+'))

command! -bar -nargs=+
\   -complete=customlist,qfsavehist#__cmd_complete__
\   QFSetHistory
\   call qfsavehist#set_history(matchstr(<q-args>, '^\s*\zs\d\+'))

command! -bar -nargs=0
\   QFClearHistories
\   call qfsavehist#clear()


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
