scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim




augroup qfsavehist-set
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
        call qfsavehist#save_qflist(w:quickfix_title)
    endif
endfunction

function! qfsavehist#save_qflist(qftitle) abort
    call s:save_history(s:histories,
    \   getqflist(), g:qfsavehist_max_history_count, a:qftitle)
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

function! qfsavehist#get_local_histories(winnr) abort
    return copy(getwinvar(a:winnr, 'qfsavehist_histories', []))
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
    call s:set_qftitle_event(history)
    return ret
endfunction

" Set w:quickfix_title if current window is quickfix/location-list.
" Otherwise, register autocommand to set w:quickfix_title
" when entering the window.
" This function is called twice, previous autocommand is unregistered.
function! s:set_qftitle_event(history) abort
    if &filetype ==# 'qf'
        let w:quickfix_title = a:history.qftitle
        autocmd! qfsavehist-set
    else
        autocmd! qfsavehist-set
        execute 'autocmd qfsavehist-set WinEnter *'
        \       'call s:set_qftitle_event(' . string(a:history.qftitle) . ')'
    endif
endfunction

function! qfsavehist#get_local_history(winnr, histnr) abort
    let NO_ITEM = []
    let histories = getwinvar(a:winnr, 'qfsavehist_histories', NO_ITEM)
    if histories is NO_ITEM
        throw 'qfsavehist: no histories.'
    endif
    let histidx = a:histnr - 1
    if histidx < 0 || histidx >= len(histories)
        throw 'qfsavehist: out of range.'
    endif
    return histories[histidx]
endfunction

function! qfsavehist#set_local_history(winnr, histnr, ...) abort
    let NO_ITEM = []
    let histories = getwinvar(a:winnr, 'qfsavehist_histories', NO_ITEM)
    if histories is NO_ITEM
        throw 'qfsavehist: no histories.'
    endif
    let histidx = a:histnr - 1
    if histidx < 0 || histidx >= len(histories)
        throw 'qfsavehist: out of range.'
    endif
    let history = histories[histidx]
    let args = [a:winnr, history.qflist] + a:000
    let ret = call('setloclist', args)
    call s:set_qftitle_event(history)
    return ret
endfunction


" TODO: Support location-list
" Current window is locaation-list window or not?
function! s:is_location_list() abort
    return 0
endfunction


function! qfsavehist#__cmd_complete__(arglead, cmdline, cursorpos) abort
    let [cmd, cmdline] = matchlist(a:cmdline, '^\s*\(\w\+\)\s\+\(.*\)')[1:2]
    let is_local = cmd ==# 'QFSetLocalHistory'
    let complete_all = (cmdline ==# '')
    let complete_filter = (cmdline !~# '^\d\+ - ')
    if !complete_all && !complete_filter
        return []
    endif
    let histories = is_local ? qfsavehist#get_local_histories(0) :
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
