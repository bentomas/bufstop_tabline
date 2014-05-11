let s:buffers_cache     = {}
let s:buffers_sort      = []
let s:buffers_real_sort = []
let s:buffer_active     = -1

let g:bufstop_tabline_sort = 1

function! bufstop_tabline#update_buffers_cache()
    let buffers = BufstopGetBufferInfo()

    let s:buffers_real_sort = []
    for i in range(0, len(buffers)-1)
        let buf = buffers[i]
        let cached_buf = {}

        let cached_buf.path      = buf.path
        let cached_buf.shortname = buf.shortname
        let cached_buf.modified  = match(buf.attributes,' +') > -1 ? 1 : 0
        let cached_buf.speedkey  = buf.key
        let cached_buf.bufno     = buf.bufno
        let cached_buf.active    = (i == 0)

        let s:buffers_cache[buf.bufno] = cached_buf

        call add(s:buffers_real_sort, buf.bufno)
    endfor

    if g:bufstop_tabline_sort || len(s:buffers_sort) != len(s:buffers_real_sort)
        let s:buffers_sort = s:buffers_real_sort
    endif
endfunction

" quick function to for putting bufferline in the tabline
function! bufstop_tabline#make_tabline()
    call bufstop_tabline#update_buffers_cache()

    let width = winwidth(0)
    let length = 0
    let tabline = ''

    for i in range(0, min([len(g:BufstopSpeedKeys), len(s:buffers_sort)])-1)
        let buf = s:buffers_cache[s:buffers_sort[i]]

        " the beginning, the speed key

            let before = i == 0 ? '' : ' '
            if buf.active
                " length of a speedkey and the separator
                let before .= repeat(' ',1+strlen(g:bufstop_tabline_speed_key_separator))
            else
                let before .= buf.speedkey . g:bufstop_tabline_speed_key_separator
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

    for bufnum in s:buffers_sort[len(g:BufstopSpeedKeys):]
        if length < width
            let tabline .= '.'
            let length += 1
        endif
    endfor

    return tabline
endfunction
