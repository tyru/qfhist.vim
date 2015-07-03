scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim




augroup qfsavehist-temp
    autocmd!
augroup END


let s:histories = []

function! qfsavehist#clear() abort
    let s:histories = []
endfunction

function! qfsavehist#save() abort
    if &filetype !=# 'qf'
        call s:error('qfsavehist#save() must be called in quickfix window!!')
        return
    endif
    if s:is_location_list()
        call qfsavehist#save_loclist()
    else
        call qfsavehist#save_qflist()
    endif
endfunction

function! qfsavehist#save_qflist() abort
    call s:save_history(s:, 'histories',
    \                   getqflist(), g:qfsavehist_max_history_count)
endfunction

function! qfsavehist#save_loclist(winnr) abort
    call s:save_history(w:, 'qfsavehist_histories',
    \                   getloclist(a:winnr), g:qfsavehist_max_history_count)
endfunction

" TODO: Support w:quickfix_title backward compatibility?
function! s:save_history(scope, varname, qflist, hist_count) abort
    if !has_key(a:scope, a:varname)
        let a:scope[a:varname] = []
    endif
    let a:scope[a:varname] = [{
    \   'qflist' : a:qflist,
    \   'title' : w:quickfix_title,
    \}] + a:scope[a:varname]
    if len(a:scope[a:varname]) > a:hist_count
        let a:scope[a:varname] = a:scope[a:varname][: a:hist_count - 1]
    endif
endfunction


function! qfsavehist#get_histories() abort
    return copy(s:histories)
endfunction

function! qfsavehist#get_local_histories() abort
    return copy(get(w:, 'qfsavehist_histories', []))
endfunction

function! qfsavehist#get_history(histnr) abort
    if a:histnr < 0 || a:histnr >= len(s:histories)
        throw 'qfsavehist: out of range.'
    endif
    return s:histories[a:histnr]
endfunction

function! qfsavehist#set_history(histnr, ...) abort
    if a:histnr < 0 || a:histnr >= len(s:histories)
        throw 'qfsavehist: out of range.'
    endif
    let history = s:histories[a:histnr]
    let args = [history.qflist] + a:000
    let ret = call('setqflist', args)
    if &filetype ==# 'qf'
        call s:set_quickfix_title(history.title)
    else
        execute 'autocmd qfsavehist-temp WinEnter *'
        \       'call s:set_quickfix_title(' . string(history.title) . ')'
    endif
    return ret
endfunction

function! qfsavehist#get_local_history(histnr) abort
    if !exists('w:qfsavehist_histories')
        throw 'qfsavehist: no histories.'
    endif
    if a:histnr < 0 || a:histnr >= len(w:qfsavehist_histories)
        throw 'qfsavehist: out of range.'
    endif
    return w:qfsavehist_histories[a:histnr]
endfunction

function! qfsavehist#set_local_history(winnr, histnr, ...) abort
    if !exists('w:qfsavehist_histories')
        throw 'qfsavehist: no histories.'
    endif
    if a:histnr < 0 || a:histnr >= len(w:qfsavehist_histories)
        throw 'qfsavehist: out of range.'
    endif
    let history = w:qfsavehist_histories[a:histnr]
    let args = [a:winnr, history.qflist] + a:000
    let ret = call('setloclist', args)
    if &filetype ==# 'qf'
        call s:set_quickfix_title(history.title)
    else
        execute 'autocmd qfsavehist-temp WinEnter *'
        \       'call s:set_quickfix_title(' . string(history.title) . ')'
    endif
    return ret
endfunction


" TODO: Support location-list
" Current window is locaation-list window or not?
function! s:is_location_list() abort
    return 0
endfunction

function! s:set_quickfix_title(title) abort
    if &filetype ==# 'qf'
        let w:quickfix_title = a:title
        autocmd! qfsavehist-temp
    endif
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
