if exists('g:loaded_yanklist')
  finish
endif

let s:yanks = []
let s:before = 0

function! yanks#list()
  if len(s:yanks) < 1
    echoh WarningMsg
    echo "no yanks to show"
    echoh None
    return
  endif
  let s:buf = nvim_create_buf(v:false, v:true)
  " let width = nvim_win_get_width(nvim_get_current_win()) - 20
  let opts = {
    \ 'style': 'minimal',
    \ 'relative': 'cursor',
    \ 'width': 100,
    \ 'height': len(s:yanks),
    \ 'row': 0,
    \ 'col': 1,
  \}
  let out = nvim_buf_set_lines(s:buf, 0, 0, v:false, s:yanks)
  let s:win = nvim_open_win(s:buf, v:true, opts)
  set ft=yanks
  setl nowrap
  syn match YankLine /.*[[:cntrl:]]$/
  syn match YankWord /.*[[:print:]]$/
  nmap <buffer> <silent> <Esc> :call yanks#close()<cr>
  nmap <buffer> <silent>  :call yanks#put()<cr>
  nmap <buffer> <silent> dd :call yanks#delete()<cr>
  nmap <buffer> <silent> P :call yanks#putbefore()<cr>
endfunction

function! yanks#delete()
  let yank = s:yanks[line(".") - 1]
  call filter(s:yanks, 'v:val != yank')
  call yanks#close()
  call yanks#list()
endfunction

function! yanks#put()
  call setreg('"', s:yanks[line(".") - 1])
  call yanks#close()
  normal! ""p
endfunction

function! yanks#clear()
  let s:yanks = []
endfunction

function! yanks#putbefore()
  call setreg('"', s:yanks[line(".") - 1])
  call yanks#close()
  normal! ""P
endfunction

function! yanks#close()
  if exists('s:win')
    call execute("close " . s:win)
  endif
endfunction

function! yanks#add()
  let yank = getreg('"')
  if len(yank) < 3
    return
  endif
  call filter(s:yanks, 'v:val != yank')
  call insert(s:yanks, yank)
  if len(s:yanks) > 25
    call remove(s:yanks, -1)
  endif
endfunction

let s:cachefile = '~/.cache/yanks.json'
if filereadable(expand(s:cachefile))
  let cache = readfile(expand(s:cachefile))
  if !empty(cache)
    let s:yanks = json_decode(cache[0])
  endif
endif

function! yanks#save()
  call writefile([ json_encode(s:yanks) ], expand( s:cachefile ), "b")
endfunction

augroup Yanks
  autocmd!
  autocmd TextYankPost * call yanks#add()
  autocmd VimLeave * call yanks#save()
  hi link YankLine Search
  hi link YankWord DiffAdd
augroup END

noremap <silent> <Plug>(Yanks) :call yanks#list()<cr>

let g:loaded_yanklist = 1
