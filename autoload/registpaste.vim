scriptencoding utf-8

let s:registers = []
let s:bid = -1
let s:wid = -1
let s:pPs_key = split('p P [p [P ]p ]P zp zP', ' ')
let s:pPs = {}
let s:mapargs = []

function! registpaste#enable() abort
    augroup RegistPaste
        autocmd!
        autocmd TextYankPost * call s:save_reg()
    augroup END
    let tmp = {}
    for p in s:pPs_key | let tmp[p] = p | endfor
    let s:pPs = get(g:, 'registpaste_maps', tmp)
    unlet tmp
    for [p, mapped] in items(s:pPs)
        if match(s:pPs_key, p) != -1
            call add(s:mapargs, maparg(mapped, 'n', 0, 1))
            execute printf('nnoremap %s <Cmd>call <SID>select_paste("%s")<CR>', mapped, p)
            execute printf('vnoremap %s <Cmd>call <SID>select_paste("%s")<CR>', mapped, p)
        endif
    endfor
endfunction

function! registpaste#disable() abort
    augroup RegistPaste
        autocmd!
    augroup END
    for mapped in values(s:pPs)
        execute printf('nunmap %s', mapped)
    endfor
    let s:pPs = {}
    if s:wid != -1
        call nvim_win_close(s:wid, v:false)
        let s:wid = -1
    endif
    if exists('*mapset')
        for pmap in s:mapargs
            if !empty(pmap)
                call mapset('n', 0, pmap)
            endif
        endfor
    endif
    let s:registers = []
    let s:mapargs = []
endfunction

function! registpaste#registers() abort
    for i in range(len(s:registers))
        let reg = s:registers[i]
        echo printf('%2d: [%s] %s', i, reg.type, substitute(reg.str, '\n', '\\n', 'g'))
    endfor
endfunction

function! s:save_reg() abort
    let reg_max = get(g:, 'registpaste_max_reg', 10)
    let regtype = getregtype('')
    if regtype =~ "\<c-v>"
        let t = 'b'
    elseif regtype ==# 'v'
        let t = 'c'
    elseif regtype ==# 'V'
        let t = 'l'
    else
        let t = '?'
    endif
    let add_item = {
                \ 'str': getreg(''),
                \ 'type': t,
                \ }
    call extend(s:registers, [add_item], 0)
    if len(s:registers) > reg_max
        call remove(s:registers, reg_max, len(s:registers)-1)
    endif
endfunction

function! s:select_paste(pP) abort
    let cnt = v:count
    if match(s:pPs_key, a:pP) == -1
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
    let reg_list = map(copy(s:registers), 'printf("[%s] %s", v:val.type, v:val.str)')
    if has('popupwin')
        call popup_menu(reg_list, #{
                    \ callback: function(expand('<SID>').'set_str', [a:pP, cnt]),
                    \ line: 'cursor+1',
                    \ col: 'cursor',
                    \ pos: 'topleft',
                    \ maxwidth: max_width,
                    \ zindex: 90,
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
                    \ 'zindex': 90,
                    \ }
        if s:bid < 0
            let s:bid = nvim_create_buf(v:false, v:true)
        endif
        call nvim_buf_set_lines(s:bid, 0, -1, 0, reg_list)
        if s:wid != -1
            call nvim_win_close(s:wid, v:false)
        endif
        let s:wid = nvim_open_win(s:bid, v:false, config)
        call win_execute(s:wid, 'setlocal cursorline')
        call win_execute(s:wid, 'setlocal nowrap')
        call win_execute(s:wid, 'setlocal nofoldenable')
        call win_execute(s:wid, 'setlocal winhighlight=CursorLine:PmenuSel')
        call win_execute(s:wid, 'normal! gg')
        while 1
            redraw
            let key = getcharstr()
            if key == "j" || key == "\<Down>"
                call win_execute(s:wid, 'normal! j')
            elseif key == "k" || key == "\<Up>"
                call win_execute(s:wid, 'normal! k')
            elseif key == "\<Enter>" || key == "\<Space>"
                let ln = line('.', s:wid)
                call nvim_win_close(s:wid, v:false)
                call s:set_str(a:pP, cnt, s:wid, ln)
                let s:wid = -1
                break
            elseif key == "\<esc>"
                call nvim_win_close(s:wid, v:false)
                let s:wid = -1
                break
            endif
        endwhile
    endif
endfunction

function! s:set_str(pP, cnt, id, res) abort
    if a:res <= 0
        return
    endif
    let reg = s:registers[a:res-1]
    call setreg('"', reg.str, reg.type)
    call s:exec_paste(a:pP, a:cnt, '"')
endfunction

function! s:exec_paste(pP, cnt, reg) abort
    if a:cnt <= 1
        let cnt = 1
    else
        let cnt = a:cnt
    endif
    execute printf('normal! %d"%s%s', cnt, a:reg, a:pP)
    try
        call repeat#set(printf("\<Cmd>call %sexec_paste('%s', %d, '%s')\<CR>", expand('<SID>'), a:pP, a:cnt, a:reg), 1)
    endtry
endfunction

