" RegistPaste.vim
" Version: 0.4.2
" Author: MeF
" License: MIT

" popup/floating window
if !(has('popupwin') || exists('*nvim_open_win'))
    finish
endif
" yank post
if !exists('##TextYankPost')
    finish
endif
" win_execute
if !exists('*win_execute')
    finish
endif

if exists('g:loaded_registpaste')
  finish
endif
let g:loaded_registpaste = 1

let s:save_cpo = &cpo
set cpo&vim

if get(g:, 'registpaste_auto_enable', 1)
    call registpaste#enable()
endif

command! RegistPasteResort call registpaste#resort()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
