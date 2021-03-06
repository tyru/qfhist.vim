scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim


function! unite#sources#qfhist#define()
  return [s:qfhist_source, s:qfhist_local_source]
endfunction"}}}


let s:qfhist_source = {
      \ 'name' : 'qfhist',
      \ 'description' : 'candidates from quickfix history',
      \ 'default_kind' : 'command',
      \ 'hooks' : {},
      \}

function! s:qfhist_source.gather_candidates(args, context)
    return map(qfhist#get_histories(), '{
    \ "word" : printf("[%d] %s", v:key + 1, v:val.qftitle),
    \ "abbr" : printf("[%d] %s", v:key + 1, v:val.qftitle),
    \ "action__command" : "call qfhist#set_history(".(v:key+1).")",
    \ }')
endfunction


let s:qfhist_local_source = {
      \ 'name' : 'qfhist/local',
      \ 'description' : 'candidates from location history',
      \ 'default_kind' : 'command',
      \ 'hooks' : {},
      \}

function! s:qfhist_local_source.gather_candidates(args, context)
    return map(qfhist#get_histories(), '{
    \ "word" : printf("[%d] %s", v:key + 1, v:val.qftitle),
    \ "abbr" : printf("[%d] %s", v:key + 1, v:val.qftitle),
    \ "action__command" : "call qfhist#set_local_history(0, " . v:key . ")",
    \ }')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
