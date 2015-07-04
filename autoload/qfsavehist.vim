scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim




augroup qfsavehist-temp
    autocmd!
augroup END


let s:histories = []

function! qfsavehist#clear() abort
    if &filetype !=# 'qf'
        call s:error('qfsavehist#clear() must be called in quickfix window!!')
        return
    endif
    if s:is_location_list()
        call qfsavehist#clear_loclist(0)
    else
        call qfsavehist#clear_qflist()
    endif
endfunction

function! qfsavehist#clear_qflist() abort
    let s:histories = []
endfunction

function! qfsavehist#clear_loclist(winnr) abort
    let NO_ITEM = []
    if getwinvar(a:winnr, 'qfsavehist_histories', NO_ITEM) is NO_ITEM
        return
    endif
    call setwinvar(a:winnr, 'qfsavehist_histories', [])
endfunction

function! qfsavehist#save() abort
    if &filetype !=# 'qf'
        call s:error('qfsavehist#save() must be called in quickfix window!!')
        return
    endif
    if s:is_location_list()
        call qfsavehist#save_loclist(0, w:quickfix_title)
    else
        call qfsavehist#save_qflist()
    endif
endfunction

function! qfsavehist#save_qflist() abort
    call s:save_history(s:histories,
    \   getqflist(), g:qfsavehist_max_history_count, w:quickfix_title)
endfunction

" TODO: Is there a way to get location-list's
" quickfix_title ({qftitle}) which belongs to {winnr} ?
function! qfsavehist#save_loclist(winnr, qftitle) abort
    let NO_ITEM = []
    if getwinvar(a:winnr, 'qfsavehist_histories', NO_ITEM) is NO_ITEM
        call setwinvar(a:winnr, 'qfsavehist_histories', [])
    endif
    call s:save_history(getwinvar(a:winnr, 'qfsavehist_histories'),
    \   getloclist(a:winnr), g:qfsavehist_max_history_count, a:qftitle)
endfunction

function! s:save_history(histories, qflist, hist_count, qftitle) abort
    call insert(a:histories, {
    \   'qflist' : a:qflist,
    \   'qftitle' : a:qftitle,
    \})
    if len(a:histories) > a:hist_count
        call remove(a:histories, a:hist_count-1, -1)
    endif
endfunction


function! qfsavehist#get_histories() abort
    return copy(s:histories)
endfunction

function! qfsavehist#get_local_histories() abort
    return copy(get(w:, 'qfsavehist_histories', []))
endfunction

function! qfsavehist#get_history(histnr) abort
    let histidx = a:histnr - 1
    if histidx < 0 || histidx >= len(s:histories)
        throw 'qfsavehist: out of range.'
    endif
    return s:histories[histidx]
endfunction

function! qfsavehist#set_history(histnr, ...) abort
    let histidx = a:histnr - 1
    if histidx < 0 || histidx >= len(s:histories)
        throw 'qfsavehist: out of range.'
    endif
    let history = s:histories[histidx]
    let args = [history.qflist] + a:000
    let ret = call('setqflist', args)
    if &filetype ==# 'qf'
        call s:set_quickfix_title(history.qftitle)
    else
        execute 'autocmd qfsavehist-temp WinEnter *'
        \       'call s:set_quickfix_title(' . string(history.qftitle) . ')'
    endif
    return ret
endfunction

function! qfsavehist#get_local_history(histnr) abort
    if !exists('w:qfsavehist_histories')
        throw 'qfsavehist: no histories.'
    endif
    let histidx = a:histnr - 1
    if histidx < 0 || histidx >= len(w:qfsavehist_histories)
        throw 'qfsavehist: out of range.'
    endif
    return w:qfsavehist_histories[histidx]
endfunction

function! qfsavehist#set_local_history(winnr, histnr, ...) abort
    if !exists('w:qfsavehist_histories')
        throw 'qfsavehist: no histories.'
    endif
    let histidx = a:histnr - 1
    if histidx < 0 || histidx >= len(w:qfsavehist_histories)
        throw 'qfsavehist: out of range.'
    endif
    let history = w:qfsavehist_histories[histidx]
    let args = [a:winnr, history.qflist] + a:000
    let ret = call('setloclist', args)
    if &filetype ==# 'qf'
        call s:set_quickfix_title(history.qftitle)
    else
        execute 'autocmd qfsavehist-temp WinEnter *'
        \       'call s:set_quickfix_title(' . string(history.qftitle) . ')'
    endif
    return ret
endfunction


" TODO: Support location-list
" Current window is locaation-list window or not?
function! s:is_location_list() abort
    return 0
endfunction

function! s:set_quickfix_title(qftitle) abort
    if &filetype ==# 'qf'
        let w:quickfix_title = a:qftitle
        autocmd! qfsavehist-temp
    endif
endfunction


function! qfsavehist#__cmd_complete__(arglead, cmdline, cursorpos) abort
    let [cmd, cmdline] = matchlist(a:cmdline, '^\s*\(\w\+\)\s\+\(.*\)')[1:2]
    let is_local = cmd ==# 'QFSetLocalHistory'
    let complete_all = (cmdline ==# '')
    let complete_filter = (cmdline !~# '^\d\+ - ')
    if !complete_all && !complete_filter
        return []
    endif
    let histories = is_local ? qfsavehist#get_local_histories() :
    \                          qfsavehist#get_histories()
    call map(histories, 'extend(v:val, {"_histnr" : v:key+1})')
    if complete_filter
        call filter(histories, 'v:val.qftitle =~? a:arglead')
    endif
    return map(histories, '
    \   printf("%d - %s", v:val._histnr, v:val.qftitle)
    \')
endfunction


function! s:error(msg) abort
    call s:echomsg(a:msg, 'ErrorMsg')
endfunction

function! s:echomsg(msg, hl) abort
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
