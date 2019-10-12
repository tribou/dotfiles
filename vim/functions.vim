"
" Helper Functions
"
" misc
function! NextBuffer()
  if !exists('b:NERDTree')
    bnext
    file
  endif
endfunction

function! PreviousBuffer()
  if !exists('b:NERDTree')
    bprevious
    file
  endif
endfunction

" Export functions in <Plug> namespace
nnoremap <Plug>(dotfiles-bnext) :<c-u>call NextBuffer()<CR>
nnoremap <Plug>(dotfiles-bprevious) :<c-u>call PreviousBuffer()<CR>
