"
" Helper Functions
"
" misc
function! NextBuffer()
  if !exists('b:NERDTree') && !exists('b:fugitive_type')
    bnext
    file
  endif
endfunction

function! PreviousBuffer()
  if !exists('b:NERDTree') && !exists('b:fugitive_type')
    bprevious
    file
  endif
endfunction

" Export functions in <Plug> namespace
nnoremap <Plug>(dotfiles-bnext) :<c-u>call NextBuffer()<CR>
nnoremap <Plug>(dotfiles-bprevious) :<c-u>call PreviousBuffer()<CR>
