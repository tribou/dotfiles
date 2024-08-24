" fzf
let g:fzf_vim = {}
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
let $FZF_DEFAULT_OPTS = '--preview="bat --color=always {}" --preview-window=up --ansi --multi'
if exists('$TMUX')
  let g:fzf_layout = { 'tmux': '70%,90%' }
else
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
endif
let g:fzf_vim.grep_multi_line = 1
let g:fzf_prefer_tmux = 1

" command! -bang -nargs=* Fzf
"   \ call fzf#run({
"   \ 'source': 'fd --type file --color=always --hidden --exclude .git --exclude .yarn/cache',
"   \ 'sink': 'e',
"   \ 'options': ' --tmux 70% --preview="bat --color=always {}"'
"   \ })

" command! -bang -nargs=* Rg
"   \ call fzf#vim#grep(
"   \   'rg --no-column --line-number --hidden --vimgrep -g ''!.git/'' -g ''!.yarn/'' --no-heading --pretty --smart-case --max-columns=160 '.shellescape(<q-args>), 1,
"   \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 3..'}, 'up:60%')
"   \           : fzf#vim#with_preview('up:60%', '?'),
"   \   <bang>0)

