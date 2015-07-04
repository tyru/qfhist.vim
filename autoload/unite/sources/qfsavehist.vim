scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim


function! unite#sources#qfsavehist#define()
  return [s:qfhist_source, s:qfhist_local_source]
endfunction"}}}


let s:qfhist_source = {
      \ 'name' : 'qfhist',
      \ 'description' : 'candidates from quickfix history',
      \ 'default_kind' : 'command',
      \ 'hooks' : {},
      \}

function! s:qfhist_source.gather_candidates(args, context)
    return map(qfsavehist#get_histories(), '{
    \ "word" : printf("[%d] %s", v:key + 1, v:val.title),
    \ "abbr" : printf("[%d] %s", v:key + 1, v:val.title),
    \ "action__command" : "call qfsavehist#set_history(".(v:key+1).")",
    \ }')
endfunction


let s:qfhist_local_source = {
      \ 'name' : 'qfhist/local',
      \ 'description' : 'candidates from location history',
      \ 'default_kind' : 'command',
      \ 'hooks' : {},
      \}

function! s:qfhist_local_source.gather_candidates(args, context)
    return map(qfsavehist#get_local_histories(), '{
    \ "word" : printf("[%d] %s", v:key + 1, v:val.title),
    \ "abbr" : printf("[%d] %s", v:key + 1, v:val.title),
    \ "action__command" : "call qfsavehist#set_local_history(" . v:key . ")",
    \ }')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
