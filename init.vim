" Functions that have to load first
"
" vim-markdown-composer
function! BuildComposer(info)
  if a:info.status != 'unchanged' || a:info.force
    if has('nvim')
      !cargo build --release
    else
      !cargo build --release --no-default-features --features json-rpc
    endif
  endif
endfunction

" Python
" Follow python virtualenvs provider instructions to setup:
" https://github.com/zchee/deoplete-jedi/wiki/Setting-up-Python-for-Neovim
" https://neovim.io/doc/user/provider.html
let g:python_host_prog = expand('~/.pyenv/versions/py2nvim/bin/python')
let g:python3_host_prog = expand('~/.pyenv/versions/py3nvim/bin/python')


call plug#begin('~/.local/share/nvim/plugged')

" Themes
Plug 'altercation/vim-colors-solarized'
Plug 'lifepillar/vim-solarized8'
Plug 'lifepillar/vim-colortemplate'
Plug 'Rigellute/rigel'
Plug 'nanotech/jellybeans.vim'
Plug 'joshdick/onedark.vim'
Plug 'challenger-deep-theme/vim', { 'as': 'challenger-deep' }

" Plug 'file://'.expand('~/dev/twodark.vim'), { 'branch': 'dev' }
" Plug 'file://'.expand('~/dev/rigel'), { 'branch': 'dev' }

" Misc
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
Plug 'tribou/vim-buftabline'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align'
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tommcdo/vim-fubitive'
"Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-dispatch'
Plug 't9md/vim-surround_custom_mapping'
Plug 'tpope/vim-speeddating'
Plug 'tpope/vim-dotenv'
Plug 'mileszs/ack.vim'
Plug 'justinmk/vim-sneak'
" Plug 'junegunn/rainbow_parentheses.vim'
Plug 'mbbill/undotree'

" Debugging
Plug 'vim-vdebug/vdebug', { 'on': 'VdebugStart' }

" Auto-formatting
Plug 'editorconfig/editorconfig-vim', { 'commit': '68f8136d2b018bfa9b23403e87d3d65bc942cbc3' }
" Using this only for the manual :Prettier command
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'javascript.jsx', 'typescript', 'typescript.tsx', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }

" Auto-complete
Plug 'dense-analysis/ale', { 'tag': 'v2.*' }
" coc.nvim and vscode-compatible extensions
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-tslint-plugin', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-css', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-highlight', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-git', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-snippets', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-eslint', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-sources', {'rtp': 'packages/emoji', 'do': 'yarn install --frozen-lockfile'}
" Plug 'neoclide/coc-emmet', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-solargraph', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-yaml', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-html', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-lists', {'do': 'yarn install --frozen-lockfile'}
Plug 'marlonfan/coc-phpls', {'do': 'yarn install --frozen-lockfile'}
Plug 'iamcco/coc-svg', {'do': 'yarn install --frozen-lockfile'}
Plug 'amiralies/coc-elixir', {'do': 'yarn install --frozen-lockfile'}
Plug 'andys8/vscode-jest-snippets', {'do': 'npm ci'}
" Plug 'flowtype/flow-for-vscode', {'do': 'yarn install --frozen-lockfile'}

" TODO: test ncm2 for autocompletion
" Plug 'ncm2/ncm2'
" ncm2: you need to install completion sources to get completions. Check
" our wiki page for a list of sources: https://github.com/ncm2/ncm2/wiki
" Plug 'ncm2/ncm2-bufword'
" Plug 'ncm2/ncm2-tmux'
" Plug 'ncm2/ncm2-path'

" Misc syntax
" TODO: test vim-polyglot and remove most other syntax plugins
" Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-liquid'

" Other JS/CSS/HTML
" Plug 'mattn/emmet-vim', { 'for': ['css', 'html'] }
Plug 'JulesWang/css.vim'
Plug 'cakebaker/scss-syntax.vim'
Plug 'wavded/vim-stylus'
Plug 'mustache/vim-mustache-handlebars'

" Markdown
Plug 'euclio/vim-markdown-composer', {
  \ 'do': function('BuildComposer'),
  \ 'for': ['markdown'],
  \ }

"" Golang
Plug 'fatih/vim-go', {
  \ 'tag': '*', 'do': ':GoInstallBinaries',
  \ 'for': ['go'],
  \ }

"" HashiCorp
"Plug 'hashivim/vim-consul'
"Plug 'hashivim/vim-nomadproject'
"Plug 'hashivim/vim-ottoproject'
"Plug 'hashivim/vim-packer'
"Plug 'hashivim/vim-terraform'
"Plug 'hashivim/vim-vagrant'
"Plug 'hashivim/vim-vaultproject'

"" Other Languages
"Plug 'docker/docker', { 'branch': '1.12.x', 'rtp': 'contrib/syntax/vim' }
Plug 'elixir-lang/vim-elixir'
Plug 'vim-scripts/nginx.vim'
"Plug 'apple/swift', { 'branch': 'swift-2.3-branch', 'rtp': 'utils/vim' }
Plug 'cespare/vim-toml'
"Plug 'chrisbra/unicode.vim'

" JavaScript
"Plug 'jelera/vim-javascript-syntax', { 'tag': '*' }
"Plug 'bigfish/vim-js-context-coloring'
Plug 'kchmck/vim-coffee-script'
Plug 'heavenshell/vim-jsdoc'
"Plug 'aaronj1335/underscore-templates.vim'
" Plug '~/dev/vim-syntax-js'
Plug 'pangloss/vim-javascript', { 'tag': '1.2.*' }
Plug 'mxw/vim-jsx'
Plug 'jparise/vim-graphql', { 'tag': '1.*' }
Plug 'HerringtonDarkholme/yats.vim'  " Typescript syntax
" Plug 'ianks/vim-tsx' " Possible indentation issues with TSX
" Plug 'mhartington/nvim-typescript', {'do': './install.sh'} " Typescript deoplete integration

call plug#end()


"" various settings
silent !mkdir -p $HOME/.vim/swapfiles
syntax enable
set clipboard+=unnamed
set conceallevel=0
set directory=$HOME/.vim/swapfiles//
set number
filetype plugin indent on
set tabstop=2
set shiftwidth=2
set expandtab ts=2 sw=2 ai
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
set hidden
set background=dark
set diffopt=filler,internal,algorithm:histogram,indent-heuristic
set ignorecase
set smartcase
set mouse=a

" set status bar to two lines
set cmdheight=2

" enable true color support
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors

"" colorscheme settings
" jellybeans.vim
let g:jellybeans_overrides = {
\    'background': { 'guibg': '011627' },
\}
let g:jellybeans_background_color_256='NONE'

" twodark.vim
let g:twodark_terminal_italics = 1

" colorscheme solarized8_flat
colorscheme challenger_deep



" source some aliases for shell
set shell=/bin/bash\ --rcfile\ ~/.ssh/api_keys


" paste and keep register
xnoremap <expr> p 'pgv"'.v:register.'y'
" Or could try
" xnoremap p "_dP


" local vimrc support
set secure
set exrc


"" custom filetype settings
autocmd BufNewFile,BufRead apple-app-site-association set filetype=json
autocmd BufNewFile,BufRead *Dockerfile* set filetype=dockerfile
autocmd BufNewFile,BufRead .babelrc,.bowerrc,.eslintrc,.jshintrc set filetype=json
autocmd BufNewFile,BufRead .ripgreprc set filetype=conf
autocmd BufNewFile,BufRead *.conf set filetype=conf
autocmd BufNewFile,BufRead *.css set filetype=scss
autocmd BufNewFile,BufRead .env* set filetype=sh
autocmd BufNewFile,BufRead .env*.php set filetype=php
autocmd Filetype Makefile setlocal ts=4 sw=4 sts=0 expandtab
autocmd FileType json syntax match Comment +\/\/.\+$+


" crontab editing
autocmd filetype crontab setlocal nobackup nowritebackup


" macros/registers
" camelCase what is dasherized
let @c = '/-x~'
" Change import to require
let @i = 'deiconst/fromdei=/''vg_S)irequire$w'
" CSS create image mixin with braces
let @m = 'VS{jwi@mixin image A, 100px, 100px;jAj'
" CSS add image classname
let @n = '/@wwwv/,hykPa I.jj'
" Insert return
let @r = 'A'
map , @r


" ack.vim
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif


" coc.nvim
set updatetime=300
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=yes
" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')
" autocmd CursorHold * silent call CocActionAsync('doHover')
" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"


" deoplete
let g:deoplete#enable_at_startup = 1


" editorconfig-vim
let g:EditorConfig_core_mode = 'external_command'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
"let g:EditorConfig_verbose=1


" NERDTree
let g:NERDTreeWinPos = 'right'


" UltiSnips
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
" let g:UltiSnipsExpandTrigger="<tab>"
" let g:UltiSnipsJumpForwardTrigger="<c-n>"
" let g:UltiSnipsJumpBackwardTrigger="<c-p>"


" If you want :UltiSnipsEdit to split your window.
"let g:UltiSnipsEditSplit="vertical"


" buftabline
let g:buftabline_show=2
let g:buftabline_indicators=1
let g:buftabline_numbers=0
let g:buftabline_path=1


" vim-commentary
autocmd FileType json setlocal commentstring=//\ %s


" vim-dotenv
function! s:env(var) abort
  return exists('*DotenvGet') ? DotenvGet(a:var) : eval('$'.a:var)
endfunction


" vim-flow
let g:flow#autoclose = 1
let g:flow#enable = 0


" vim-fugitive
"set statusline+=%{fugitive#statusline()}


" indentLine
"let g:indentLine_char = '.'
"let g:indentLine_conceallevel = 0


" vim-javascript
let g:javascript_plugin_flow = 1
let g:javascript_plugin_jsdoc = 1
" let g:javascript_opfirst = 1
" let g:javascript_opfirst = '\%([<>,?^%|*&]\|\/[^/*]\|\([-:+]\)\1\@!\|=>\@!\|in\%(stanceof\)\=\>\)'
" let g:javascript_continuation = '\%([<=,?/*^%|&:]\|+\@<!+\|-\@<!-\|=\@<!>\|\<in\%(stanceof\)\=\)'

" vim-jsdoc
let g:jsdoc_allow_input_prompt = 1
let g:jsdoc_input_description = 1
let g:jsdoc_access_descriptions = 2
let g:jsdoc_underscore_private = 1
let g:jsdoc_enable_es6 = 1


" vim-jsx
let g:jsx_ext_required = 0


" vim-markdown-composer
" let g:markdown_composer_custom_css = [
"   \ 'https://cdn.jsdelivr.net/gh/sindresorhus/github-markdown-css@2/github-markdown.css',
"   \ ]


" vim-prettier
let g:prettier#autoformat = 0


"vim-sneak
let g:sneak#label = 1


" vim-surround_custom_mapping
let g:surround_custom_mapping = {}
let g:surround_custom_mapping._ = {
  \ 'j':  "/* \r */",
  \ 'h':  "{{!-- \r --}}",
  \ 'x':  "{/* \r */}",
  \ }
let g:surround_custom_mapping.html = {
  \ 'm':  "{{#\1view helper: \1}}\r{{/\1\1}}",
  \ }


" nvim-typescript
let g:nvim_typescript#diagnostics_enable = 0 " Use ALE for linting


" Other
"function! SyntaxItem()
"  return synIDattr(synID(line("."),col("."),1),"name")
"endfunction
"
"set statusline+=%{SyntaxItem()}


source $DOTFILES/vim/lightline.vim
source $DOTFILES/vim/ale.vim
source $DOTFILES/vim/fzf.vim
source $DOTFILES/vim/keymaps.vim
source $DOTFILES/vim/visual-at.vim
