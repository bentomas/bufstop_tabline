if exists('g:loaded_bufstop_tabline')
  finish
endif

let g:bufstop_tabline_speed_key_separator = ''

" only show tabline (list of buffers) if we have more than one
" buffer to show...
function! s:CheckForMoreThanOneBuffer()
    let numBuffers = len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))
    if numBuffers > 1
        set showtabline=2
        set tabline=%!bufstop_tabline#make_tabline()
    else
        set tabline=''
        set showtabline=0
    endif

endfunction

if has("autocmd")
    autocmd BufWinEnter * :call s:CheckForMoreThanOneBuffer()
endif
