" fzf
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Customize fzf colors to match your color scheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

let g:fzf_commits_log_options = '--all --graph --abbrev-commit --date=local --date=short --color=always '
  \ . '--pretty=format:"%C(yellow)%h %C(cyan)%ad%C(auto)%d %Creset%s %C(blue)<%aN>"'
let $FZF_DEFAULT_COMMAND = 'fd --type file --color=always --hidden --exclude .git'
let $FZF_DEFAULT_OPTS = ' --ansi --hscroll-off=80 --multi'
let g:fzf_layout = { 'window': 'enew' }

command! -bang -nargs=* Fzf
  \ call fzf#run({
  \ 'source': 'fd --type file --color=always --hidden --exclude .git',
  \ 'sink': 'e',
  \ 'options': ' --preview="bat --color=always {}" --preview-window=up:60%'
  \ })

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --pretty --smart-case --max-columns=160 '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview('up:60%', '?'),
  \   <bang>0)

