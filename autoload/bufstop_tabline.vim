let s:buffers_cache      = {}
let s:buffers_sort       = []
let s:buffers_real_sort  = []

let s:last_switch_to_num = 1

function! bufstop_tabline#update_buffers_cache(sort)
    let buffers = BufstopGetBufferInfo()

    let s:buffers_cache = {}
    let s:buffers_real_sort = []

    for i in range(0, len(buffers)-1)
        let buf = buffers[i]
        let cached_buf = {}

        let cached_buf.path        = buf.path
        let cached_buf.shortname   = buf.shortname
        let cached_buf.tabline_key = g:bufstop_tabline_keys[i]
        let cached_buf.bufno       = buf.bufno

        let cached_buf.modified    = match(buf.attributes,'+') > -1 ? 1 : 0
        let cached_buf.loaded      = match(buf.attributes,'[ha]') > -1 ? 1 : 0
        let cached_buf.active      = (i == 0)

        let s:buffers_cache[buf.bufno] = cached_buf

        if cached_buf.loaded || g:bufstop_tabline_show_unloaded_buffers
            call add(s:buffers_real_sort, buf.bufno)
        endif
    endfor

    if a:sort || len(s:buffers_sort) != len(s:buffers_real_sort)
        let s:buffers_sort = s:buffers_real_sort
    endif
endfunction

" that creates a bufstop_tabline. this can be used in other places
" though, like the status line
function! bufstop_tabline#make_line(...)
    call bufstop_tabline#update_buffers_cache(a:0 > 0 ? a:1 : 1)

    let separator = get(g:, 'bufstop_tabline_key_separator', ':')
    let width = winwidth(0)
    let length = 0
    let tabline = ''

    for i in range(0, len(s:buffers_sort)-1)
        let buf = s:buffers_cache[s:buffers_sort[i]]

        if !(buf.loaded || g:bufstop_tabline_show_unloaded_buffers)
            continue
        endif

        let key = buf.tabline_key

        if key == ''
            continue
        endif

        " the beginning, the speed key

            let before = i == 0 ? '' : ' '
            if buf.active
                " length of a key and the separator
                let before .= repeat(' ',len(key)+separator)
            else
                let before .= key . separator
            endif

            let part_length = len(before)
            if length + part_length > width
                let before = before[:width-length-1]
                let part_length = len(before)
            endif
            let tabline .= (buf.active ? '%#TabLineSel#' : '%#TabLineTabNr#').before
            let length += part_length
            if length >= width
                break
            endif

        " the middle, aka the file name

            let mod = buf.modified ? '+' : ''
            let middle = buf.shortname . mod . ' '

            let part_length = len(middle)
            if length + part_length > width
                let middle = middle[:width-length-1]
                let part_length = len(middle)
            endif
            let tabline .= (buf.active ? '%#TabLineSel#' : '%#TabLine#').middle
            let length += part_length
            if length >= width
                break
            endif
    endfor

    let tabline .= '%#TabLineFill#'

    return tabline
endfunction

function! bufstop_tabline#show()
    let location = g:bufstop_tabline_location
    let s:old_show = location == 'status' ? &laststatus : &showtabline
    let s:old_line = location == 'status' ? &statusline : &tabline

    let s:old_maxfuncdepth = &maxfuncdepth
    set maxfuncdepth=1000

    call s:SetLine(location, bufstop_tabline#make_line(1), 2)

    let order = range(0,min([len(s:buffers_sort), len(g:bufstop_tabline_keys)])-1)
    let current = 0
    let close = 0
    while !close
        echo '(Bufstop)'

        let code = getchar()
        let key = nr2char(code)

        if key == ':'
            call feedkeys(":")
            let switch_to_num = -1
            let close = 1
        elseif has_key(g:bufstop_tabline_command_keys, key)
            let cmd = g:bufstop_tabline_command_keys[key]
            if cmd[0] == ':'
                call bufstop_tabline#close(location)
                exec g:bufstop_tabline_command_keys[key]
                return
            else
                if cmd[-1:][0] == '!'
                    let close = 1
                    let cmd = cmd[0:-2]
                endif

                if cmd == 'right'
                    let switch_to_num = order[(current+1) % len(order)]
                elseif cmd == 'left'
                    let switch_to_num = order[current == 0 ? len(order)-1 : current-1]
                elseif cmd == 'last'
                    let switch_to_num = len(order) > 1 ? order[1] : -1
                elseif cmd == 'repeat'
                    let switch_to_num = len(order) > s:last_switch_to_num ? order[s:last_switch_to_num] : -1
                endif
            endif
        else
            let switch_to_num = strridx(g:bufstop_tabline_keys, key)
            if switch_to_num > -1 && switch_to_num < len(order)
                let s:last_switch_to_num = switch_to_num
            endif
            let close = 1
        endif

        if switch_to_num > -1 && switch_to_num < len(order)
            let neworder = []
            for i in order
                if i < switch_to_num
                    call add(neworder,i+1)
                elseif i > switch_to_num
                    call add(neworder,i)
                else
                    call add(neworder,0)
                endif
            endfor
            let order = neworder
            let current = index(order,0)

            call BufstopSwitchTo(switch_to_num)
            call s:SetLine(location, bufstop_tabline#make_line(0), 2)

            if close && g:bufstop_tabline_highlight_time > 0
                exec 'sleep '.g:bufstop_tabline_highlight_time.'m'
            endif
        endif

        echo ""
    endwhile

    call bufstop_tabline#close(location)
endfunction

function! bufstop_tabline#close(location)
    call s:SetLine(a:location, s:old_line, s:old_show)
    let &maxfuncdepth = s:old_maxfuncdepth
endfunction

function! s:SetLine(location, line, show)
    if a:location == 'status'
        let &laststatus = a:show
        let &statusline = a:line
    else
        let &showtabline = a:show
        let &tabline = a:line
    endif
    redraw
endfunction

