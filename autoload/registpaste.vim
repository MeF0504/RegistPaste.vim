scriptencoding utf-8

let s:registers = []
let s:bid = -1
let s:wid = -1
let s:pPs_key = split('p P [p [P ]p ]P zp zP', ' ')
let s:reg = ''
let s:pPs = {}
let s:mapargs = []

function! registpaste#enable() abort
    augroup RegistPaste
        autocmd!
        autocmd TextYankPost * call s:save_reg()
    augroup END
    let s:reg = get(g:, 'registpaste_used_register', '"')
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

function! s:get_clipboard_info() abort
    let cbs = split(&clipboard, ',')
    let res = ['"']
    for cb in cbs
        if cb ==# 'unnamed' || cb ==# 'autoselect'
            call add(res, '*')
        elseif cb ==# 'unnamedplus' || cb ==# 'autoselectplus'
            call add(res, '+')
        elseif cb =~# 'exclude'
            break
        endif
    endfor
    return res
endfunction

function! s:save_reg() abort
    if match(s:get_clipboard_info(), v:register) == -1
        return
    endif
    let reg_max = get(g:, 'registpaste_max_reg', 10)
    let is_filter = get(g:, 'registpaste_is_filter', 1)
    let regtype = getregtype('')
    if regtype =~ "\<c-v>"
        let t = 'b'
    elseif regtype ==# 'v'
        let t = 'c'
    elseif regtype ==# 'V'
        let t = 'l'
    else
        let t = ''
    endif
    let add_item = {
                \ 'str': getreg(''),
                \ 'type': t,
                \ }
    if is_filter
        let idx = match(
                    \ map(copy(s:registers), {key, val -> val.str ==# getreg('')}),
                    \ 1)
    else
        let idx = -1
    endif
    call extend(s:registers, [add_item], 0)
    if idx != -1
        call remove(s:registers, idx+1)
    elseif len(s:registers) > reg_max
        call remove(s:registers, reg_max, len(s:registers)-1)
    endif
endfunction

function! s:select_paste(pP) abort
    let cnt = v:count
    if match(s:pPs_key, a:pP) == -1
        return
    endif
    if match(s:get_clipboard_info(), v:register) == -1
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
    if !&modifiable
        echohl ErrorMsg
        echomsg "Cannot make changes, 'modifiable' is off."
        echohl None
        return
    endif

    let max_width = get(g:, 'registpaste_max_width', &columns*2/3)
    let tmp_list = deepcopy(s:registers)
    let reg_list = map(copy(s:registers), 'printf("[%s] %s", v:val.type, v:val.str)')
    if has('popupwin')
        let config = #{
                    \ line: 'cursor+1',
                    \ col: 'cursor',
                    \ pos: 'topleft',
                    \ maxwidth: max_width,
                    \ cursorline: v:true,
                    \ }
        let s:wid = popup_create(reg_list, config)
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
        let s:wid = nvim_open_win(s:bid, v:false, config)
        call win_execute(s:wid, 'setlocal winhighlight=CursorLine:PmenuSel')
    endif
    call win_execute(s:wid, 'setlocal cursorline')
    call win_execute(s:wid, 'setlocal nowrap')
    call win_execute(s:wid, 'setlocal nofoldenable')
    call win_execute(s:wid, 'normal! gg')
    echo '"j/k":move; "J":go down; "K":go up; "D":delete; "<Enter>/<Space>":paste; "<esc>/x":cancel'
    while 1
        redraw
        try
            let key = getcharstr()
        catch /^Vim:Interrupt$/
            " ctrl-c (interrupt)
            call s:close_win()
            break
        endtry
        if key ==# "j" || key ==# "\<Down>"
            call win_execute(s:wid, 'normal! j')
        elseif key ==# "k" || key ==# "\<Up>"
            call win_execute(s:wid, 'normal! k')
        elseif key ==# "\<Enter>" || key ==# "\<Space>"
            let s:registers = tmp_list
            let ln = line('.', s:wid)
            " popup_select に従えばset_str (cb) -> closeだが，
            " pasteでコケるとwindowが残ってしまうのでこうする
            let wid = s:wid
            call s:close_win()
            call s:set_str(a:pP, cnt, wid, ln)
            break
        elseif key ==# 'J'
            let idx = line('.', s:wid)-1
            if idx == len(tmp_list)-1
                continue
            endif
            let tmp = remove(tmp_list, idx)
            call insert(tmp_list, tmp, idx+1)
            call s:update_window(s:wid, s:bid, tmp_list)
            call win_execute(s:wid, 'normal! j')
        elseif key ==# 'K'
            let idx = line('.', s:wid)-1
            if idx == 0
                continue
            endif
            let tmp = remove(tmp_list, idx)
            call insert(tmp_list, tmp, idx-1)
            call s:update_window(s:wid, s:bid, tmp_list)
            call win_execute(s:wid, 'normal! k')
        elseif key ==# 'D'
            let idx = line('.', s:wid)-1
            call remove(tmp_list, idx)
            call s:update_window(s:wid, s:bid, tmp_list)
        elseif key == "\<esc>" || key == 'x'
            call s:close_win()
            break
        endif
    endwhile
    normal! :
endfunction

function! s:set_str(pP, cnt, id, res) abort
    if a:res <= 0
        return
    endif
    let reg = s:registers[a:res-1]
    call setreg(s:reg, reg.str, reg.type)
    call s:exec_paste(a:pP, a:cnt, s:reg)
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

function! s:close_win() abort
    if has('popupwin')
        call popup_close(s:wid)
    elseif has('nvim')
        call nvim_win_close(s:wid, v:false)
    endif
    let s:wid = -1
endfunction

function! s:update_window(wid, bid, reg_list) abort
    let str_list = map(copy(a:reg_list), 'printf("[%s] %s", v:val.type, v:val.str)')
    if has('popupwin')
        call popup_settext(a:wid, str_list)
    elseif has('nvim')
        call nvim_buf_set_lines(a:bid, 0, -1, 0, str_list)
    endif
endfunction

