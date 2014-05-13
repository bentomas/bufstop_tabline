let s:buffers_cache          = {}
let s:buffers_sort           = []
let s:buffers_real_sort      = []

let s:default_location       = 'tab'
let s:default_highlight_time = 150

function! bufstop_tabline#update_buffers_cache(sort)
    let buffers = BufstopGetBufferInfo()

    let s:buffers_real_sort = []
    for i in range(0, len(buffers)-1)
        let buf = buffers[i]
        let cached_buf = {}

        let cached_buf.path      = buf.path
        let cached_buf.shortname = buf.shortname
        let cached_buf.modified  = match(buf.attributes,'+') > -1 ? 1 : 0
        let cached_buf.loaded    = match(buf.attributes,'[ha]') > -1 ? 1 : 0
        let cached_buf.speedkey  = buf.key
        let cached_buf.bufno     = buf.bufno
        let cached_buf.active    = (i == 0)

        let s:buffers_cache[buf.bufno] = cached_buf

        call add(s:buffers_real_sort, buf.bufno)
    endfor

    if a:sort || len(s:buffers_sort) != len(s:buffers_real_sort)
        echom 'sorting'
        let s:buffers_sort = s:buffers_real_sort
    endif
endfunction

" quick function to for putting bufferline in the tabline
function! bufstop_tabline#make_line(...)
    let sort = a:0 > 0 ? a:1 : 1
    echom 'sort: '.sort
    call bufstop_tabline#update_buffers_cache(sort)

    let separator = get(g:, 'bufstop_tabline_speed_key_separator', ':')
    let width = winwidth(0)
    let length = 0
    let tabline = ''

    for i in range(0, len(s:buffers_sort)-1)
        let buf = s:buffers_cache[s:buffers_sort[i]]

        if !buf.loaded || get(g:, 'bufstop_tabline_show_unloaded_buffers', 0)
            continue
        endif

        " the beginning, the speed key

            let before = i == 0 ? '' : ' '
            if buf.active
                " length of a speedkey and the separator
                let before .= repeat(' ',len(buf.speedkey)+separator)
            else
                let before .= buf.speedkey . separator
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

function! bufstop_tabline#show_fast()
    let location = get(g:, 'bufstop_tabline_location', s:default_location)
    let s:old_show = location == 'status' ? &laststatus : &showtabline
    let s:old_line = location == 'status' ? &statusline : &tabline

    let s:old_maxfuncdepth = &maxfuncdepth
    set maxfuncdepth=1000

    call s:SetLine(location, bufstop_tabline#make_line(1), 2)
    echo "(Bufstop)"

    let code = getchar()
    let key = nr2char(code)

    if key == get(g:, 'bufstop_tabline_repeat_key', g:bufstop_tabline_key)
        let switch_to_num = get(s:, 'last_switch_to_num', 1)
    elseif has_key(get(g:, 'bufstop_tabline_command_keys', {}), key)
        call bufstop_tabline#stop(location)
        exec g:bufstop_tabline_command_keys[key]
        return
    else
        let keys = get(g:, 'bufstop_tabline_keys', g:BufstopKeys)
        let switch_to_num = strridx(keys, key)

        if switch_to_num < 0 || key == nr2char(27)
            call bufstop_tabline#stop(location)
            return
        endif
    endif

    let s:last_switch_to_num = switch_to_num
    call BufstopSwitchTo(switch_to_num)

    let highlight_time = get(g:, 'bufstop_tabline_highlight_time', s:default_highlight_time)
    if highlight_time > 0
        echom 'highlighting'
        call s:SetLine(location, bufstop_tabline#make_line(0), 2)
        exec 'sleep '.highlight_time.'m'
        echom 'done highlighting'
    endif

    call bufstop_tabline#stop(location)
endfunction

function! bufstop_tabline#stop(location)
    let &maxfuncdepth = s:old_maxfuncdepth
    call s:SetLine(a:location, s:old_line, s:old_show)
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

