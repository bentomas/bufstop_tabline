if exists('g:loaded_bufstop_tabline')
  finish
endif

" bufstop_tabline_key                   = ''
" bufstop_tabline_speed_key_separator   = ':'
" bufstop_tabline_show_unloaded_buffers = 0
" bufstop_tabline_location              = s:default_location
" bufstop_tabline_repeat_key            = g:bufstop_tabline_key
" bufstop_tabline_keys                  = g:BufstopKeys
" bufstop_tabline_highlight_time        = s:default_highlight_time


if has_key(g:, 'bufstop_tabline_key') && g:bufstop_tabline_key != ''
    exec 'map '.g:bufstop_tabline_key.' :call bufstop_tabline#show_fast()<CR>'
endif
