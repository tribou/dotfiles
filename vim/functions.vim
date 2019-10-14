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

function! ToggleGblame()
  if !exists('b:fugitive_type')
    " exe 'echom "doesnt exist"'
    Gblame
  else
    " exe 'echom "exists"'
    exe 'normal gq'
  endif
endfunction

" Export functions in <Plug> namespace
nnoremap <Plug>(dotfiles-bnext) :<c-u>call NextBuffer()<CR>
nnoremap <Plug>(dotfiles-bprevious) :<c-u>call PreviousBuffer()<CR>
nnoremap <Plug>(dotfiles-gblame) :<c-u>call ToggleGblame()<CR>
