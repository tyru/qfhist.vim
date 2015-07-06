scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim




" [History, ...]
let s:histories = []
" Number
let s:max_histid = 0

function! qfhist#clear() abort
    let s:histories = []
endfunction

function! qfhist#save_loclist(winnr) abort
    let qftitle = s:get_quickfix_title(a:winnr)
    call s:save_history(s:histories,
    \   getloclist(a:winnr), g:qfhist_max_history_count, qftitle, 1)
endfunction

function! qfhist#save_qflist() abort
    let qftitle = s:get_quickfix_title(-1)
    call s:save_history(s:histories,
    \   getqflist(), g:qfhist_max_history_count, qftitle, 0)
endfunction

function! qfhist#get_histories() abort
    return copy(s:histories)
endfunction

function! qfhist#get_history(histnr) abort
    let histidx = a:histnr - 1
    if histidx < 0 || histidx >= len(s:histories)
        throw 'qfhist: out of range.'
    endif
    return s:histories[histidx]
endfunction

function! qfhist#set_history(histnr) abort
    let history = qfhist#get_history(a:histnr)
    let ret = setqflist(history.qflist)
    call s:set_quickfix_title(history.qftitle, -1)
    return ret
endfunction

function! qfhist#open_history(histnr) abort
    call qfhist#set_history(a:histnr)
    copen
endfunction

function! qfhist#set_local_history(winnr, histnr) abort
    let history = qfhist#get_history(a:histnr)
    let ret = setloclist(a:winnr, history.qflist)
    call s:set_quickfix_title(history.qftitle, a:winnr)
    return ret
endfunction

function! qfhist#open_local_history(winnr, histnr) abort
    call qfhist#set_local_history(a:winnr, a:histnr)
    lopen
endfunction

function! qfhist#__cmd_complete__(arglead, cmdline, cursorpos) abort
    let [cmd, cmdline] = matchlist(a:cmdline, '^\s*\(\w\+\)\s\+\(.*\)')[1:2]
    let complete_all = (cmdline ==# '')
    let complete_filter = (cmdline !~# '^\d\+ - ')
    if !complete_all && !complete_filter
        return []
    endif
    let histories = qfhist#get_histories()
    call map(histories, 'extend(v:val, {"_histnr" : v:key+1})')
    if complete_filter
        call filter(histories, 'v:val.qftitle =~? a:arglead')
    endif
    return map(histories, '
    \   printf("%d - %s", v:val._histnr,
    \           (v:val.qftitle !=# "" ? v:val.qftitle : "[unknown]" ))
    \')
endfunction


function! s:save_history(histories, qflist, hist_count, qftitle, is_local) abort
    call insert(a:histories, {
    \   'histid' : s:generate_histid(),
    \   'qflist' : a:qflist,
    \   'qftitle' : a:qftitle,
    \   'is_local' : a:is_local,
    \})
    if len(a:histories) > a:hist_count
        call remove(a:histories, a:hist_count-1, -1)
    endif
endfunction

function! s:generate_histid() abort
    let time = has('reltime') ? join(reltime(), '') : localtime()
    let s:max_histid += 1
    return time . '-' . s:max_histid
endfunction

function! s:find_history_by_histid(histid, default) abort
    return get(filter(copy(s:histories),
    \               'v:val.histid ==# a:histid'), 0, a:default)
endfunction

function! s:get_quickfix_title(winnr) abort
    return s:call_in_quickfix_window(
    \       a:winnr, 's:fn_get_quickfix_title', [])
endfunction

function! s:fn_get_quickfix_title() abort
    return w:quickfix_title
endfunction

function! s:set_quickfix_title(qftitle, winnr) abort
    return s:call_in_quickfix_window(
    \       a:winnr, 's:fn_set_quickfix_title', [a:qftitle])
endfunction

function! s:fn_set_quickfix_title(qftitle) abort
    let w:quickfix_title = a:qftitle
endfunction

function! s:call_in_quickfix_window(winnr, func, args) abort
    " Current window is quickfix/location-list window.
    if &filetype ==# 'qf' && exists('w:quickfix_title')
        return call(a:func, a:args)
    endif
    " Try to open quickfix/location-list window.
    let oldwinnr  = winnr()
    let oldwinnum = winnr('$')
    let eventignore = &eventignore
    set eventignore=all
    try
        windo let w:qfhist_checkwin = 0
        call setwinvar(oldwinnr, 'qfhist_checkwin', 1)
        if a:winnr >=# 0
            if a:winnr ># 0
                execute a:winnr 'wincmd w'
            endif
            lopen
        else
            copen
        endif
        return call(a:func, a:args)
    finally
        if winnr('$') !=# oldwinnum
            " quickfix/location-list window was not opened.
            execute (a:winnr >=# 0 ? 'lclose' : 'cclose')
        endif
        windo unlet! w:qfhist_checkwin
        execute oldwinnr 'wincmd w'
        let &eventignore = eventignore
    endtry
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

function! s:has_item(list, expr) abort
    return !empty(filter(copy(a:list), a:expr))
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
