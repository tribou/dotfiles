" lightline.vim
set laststatus=2
set noshowmode
let g:lightline = {
      \ 'colorscheme': 'rigel',
      \ 'active': {
      \   'left': [
      \             [ 'linter_errors', 'linter_warnings' ],
      \             [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename' ]
      \           ],
      \ },
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
      \   'gitbranch': 'fugitive#head',
      \   'cocstatus': 'coc#status',
      \ },
      \ }

function! SplitPath()
  let s = split(expand('%'), '/')
  if len(s) > 1
    let i = 0
    let path = ''
    " Get first character of each directory except last one
    while i < len(s) - 2
      let path .= strpart(s[i], 0, 1)
      let path .= '/'
      let i += 1
    endwhile
    let path .= s[-2] . '/' . s[-1]
    return path
  endif
  return expand('%')
endfunction

function! LightlineFilename()
  let path = SplitPath()
  let modified = &modified ? ' +' : ''
  return path . modified
endfunction


" lightline-ale
let g:lightline.component_expand = {
      \  'linter_warnings': 'lightline#ale#warnings',
      \  'linter_errors': 'lightline#ale#errors',
      \ }

let g:lightline.component_type = {
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \ }



