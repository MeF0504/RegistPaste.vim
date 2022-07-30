scriptencoding utf-8

let s:registers = []
let s:bid = -1
let s:pmap = {}
let s:Pmap = {}

function! registpaste#enable() abort
    augroup RegistPaste
        autocmd!
        autocmd TextYankPost * call s:save_reg()
    augroup END
    let s:pmap = maparg('p', 'n', 0, 1)
    let s:Pmap = maparg('P', 'n', 0, 1)
    nnoremap p <Cmd>call <SID>select_paste('p')<CR>
    nnoremap P <Cmd>call <SID>select_paste('P')<CR>
endfunction

function! registpaste#disable() abort
    augroup RegistPaste
        autocmd!
    augroup END
    nunmap p
    nunmap P
    if exists('*mapset')
        if !empty(s:pmap)
            call mapset('n', 0, s:pmap)
        endif
        if !empty(s:Pmap)
            call mapset('n', 0, s:Pmap)
        endif
    endif
    let s:registers = []
endfunction

function! registpaste#registers() abort
    for i in range(len(s:registers))
        let reg = s:registers[i]
        echo printf('%2d: %s%s', i, reg.block?'[b] ':'', substitute(reg.str, '\n', '\\n', 'g'))
    endfor
endfunction

function! s:save_reg() abort
    let reg_max = get(g:, 'registpaste_max_reg', 10)
    let add_item = {
                \ 'str': getreg(''),
                \ 'block': getregtype('') =~ "\<c-v>",
                \ }
    call extend(s:registers, [add_item], 0)
    if len(s:registers) > reg_max
        call remove(s:registers, reg_max, len(s:registers)-1)
    endif
endfunction

function! s:exec_paste(pP, cnt, reg) abort
    if a:cnt <= 1
        let cnt = 1
    else
        let cnt = a:cnt
    endif
    execute printf('normal! %d"%s%s', cnt, a:reg, a:pP)
endfunction

function! s:select_paste(pP) abort
    let cnt = v:count
    if !(a:pP ==# 'p' || a:pP ==# 'P')
        return
    endif
    if !(v:register == '*' || v:register == '"')
        call s:exec_paste(a:pP, cnt, v:register)
        return
    endif
    if empty(s:registers)
        call s:exec_paste(a:pP, cnt, v:register)
        return
    endif
    if len(s:registers) == 1
        call s:set_str(a:pP, cnt, 0, 1)
        return
    endif

    let max_width = get(g:, 'registpaste_max_width', &columns*2/3)
    let reg_list = map(copy(s:registers), 'v:val.block ? "[b] ".v:val.str : v:val.str')
    if has('popupwin')
        call popup_menu(reg_list, #{
                    \ callback: function(expand('<SID>').'set_str', [a:pP, cnt]),
                    \ line: 'cursor+1',
                    \ col: 'cursor',
                    \ pos: 'topleft',
                    \ maxwidth: max_width,
                    \ })
    elseif has('nvim')
        let width = 1
        for str in reg_list
            if len(str) > width
                let width = len(str)
            endif
        endfor
        let width += 1
        if width > max_width
            let width = max_width
        endif

        let config = {
                    \ 'relative': 'cursor',
                    \ 'row': 1,
                    \ 'col': 0,
                    \ 'width': width,
                    \ 'height': len(reg_list),
                    \ 'style': 'minimal',
                    \ 'anchor': 'NW',
                    \ 'border': 'single',
                    \ }
        if s:bid < 0
            let s:bid = nvim_create_buf(v:false, v:true)
        endif
        call nvim_buf_set_lines(s:bid, 0, -1, 0, reg_list)
        let wid = nvim_open_win(s:bid, v:false, config)
        call win_execute(wid, 'setlocal cursorline')
        call win_execute(wid, 'setlocal nowrap')
        call win_execute(wid, 'setlocal winhighlight=CursorLine:PmenuSel')
        call win_execute(wid, 'normal! gg')
        while 1
            redraw
            let key = getcharstr()
            if key == "j" || key == "\<Down>"
                call win_execute(wid, 'normal! j')
            elseif key == "k" || key == "\<Up>"
                call win_execute(wid, 'normal! k')
            elseif key == "\<Enter>" || key == "\<Space>"
                call s:set_str(a:pP, cnt, 0, line('.', wid))
                call nvim_win_close(wid, v:false)
                break
            elseif key == "\<esc>"
                call nvim_win_close(wid, v:false)
                break
            endif
        endwhile
    endif
endfunction

function! s:set_str(pP, cnt, id, res) abort
    if a:res <= 0
        return
    endif
    " let @" = s:registers[a:res-1]
    let reg = s:registers[a:res-1]
    if reg.block
        call setreg('"', reg.str, 'b')
    else
        call setreg('"', reg.str)
    endif
    call s:exec_paste(a:pP, a:cnt, '"')
endfunction

