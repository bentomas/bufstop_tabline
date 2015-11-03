if exists('g:loaded_bufstop_tabline')
  finish
endif

let s:defaults = {}
"let s:defaults['bufstop_tabline_location']              = 'status'
let s:defaults['bufstop_tabline_location']              = 'tab'
let s:defaults['bufstop_tabline_key_separator']         = ':'
let s:defaults['bufstop_tabline_show_unloaded_buffers'] = 0
let s:defaults['bufstop_tabline_highlight_time']        = 150

let s:defaults['bufstop_tabline_keys']                  = g:BufstopKeys
let s:defaults['bufstop_tabline_command_keys']          = {}

for key in keys(s:defaults)
  if !exists('g:'.key)
    exec 'let g:'.key.' = s:defaults["'.key.'"]'
  endif
endfor


if g:bufstop_tabline_mapping != ''
    exec 'map '.g:bufstop_tabline_mapping.' :call bufstop_tabline#show()<CR>'
endif
