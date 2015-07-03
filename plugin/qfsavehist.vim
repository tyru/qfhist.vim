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
    autocmd qfsavehist-auto QuickfixCmdPost * call qfsavehist#save()
endif

let g:qfsavehist_max_history_count =
\   get(g:, 'qfsavehist_max_history_count', 15)


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
