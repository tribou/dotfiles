"
" Helper Functions
"
" misc
function! DeleteBuffer()
  if exists('b:NERDTree') || exists('b:fugitive_type')
    bdelete
    file
  else
    bprevious
    bdelete #
    file
  endif
endfunction

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
  if exists('b:fugitive_type') && b:fugitive_type == 'temp'
    " exe 'echom "exists"'
    exe 'normal gq'
  elseif exists('b:fugitive_type') && b:fugitive_type == 'commit'
    " exe 'echom "in a commit"'
    " do nothing...
  else
    " exe 'echom "doesnt exist"'
    Gblame
  endif
endfunction

" Export functions in <Plug> namespace
nnoremap <Plug>(dotfiles-bdelete) :<c-u>call DeleteBuffer()<CR>
nnoremap <Plug>(dotfiles-bnext) :<c-u>call NextBuffer()<CR>
nnoremap <Plug>(dotfiles-bprevious) :<c-u>call PreviousBuffer()<CR>
nnoremap <Plug>(dotfiles-gblame) :<c-u>call ToggleGblame()<CR>

command! ToggleGblame call ToggleGblame()
command! Compare Gedit master:%
