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
" Plug 'altercation/vim-colors-solarized'
Plug 'lifepillar/vim-solarized8'
Plug 'lifepillar/vim-colortemplate'
Plug 'Rigellute/rigel'

" Misc
Plug 'airblade/vim-gitgutter'
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
" Plug 'ap/vim-buftabline'
Plug 'tribou/vim-buftabline'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-easy-align'
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'terryma/vim-multiple-cursors'
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
Plug 'tpope/vim-git'
Plug 'tpope/vim-dotenv'
Plug 'mileszs/ack.vim'
Plug 'justinmk/vim-sneak'
Plug 'ap/vim-css-color'
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
Plug 'w0rp/ale', { 'tag': 'v2.*' }
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Todo - test ncm2 for autocompletion
" Plug 'ncm2/ncm2'
" ncm2: you need to install completion sources to get completions. Check
" our wiki page for a list of sources: https://github.com/ncm2/ncm2/wiki
" Plug 'ncm2/ncm2-bufword'
" Plug 'ncm2/ncm2-tmux'
" Plug 'ncm2/ncm2-path'

" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" Plug '~/dev/vim-snippets'

" Misc syntax
Plug 'tpope/vim-liquid'
Plug 'autozimu/LanguageClient-neovim', {
  \ 'branch': 'next',
  \ 'do': 'bash install.sh',
  \ }

" Other JS/CSS/HTML
Plug 'mattn/emmet-vim', { 'for': ['css', 'html'] }
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
Plug '~/dev/vim-syntax-js'
Plug 'pangloss/vim-javascript', { 'tag': '1.2.*' }
Plug 'mxw/vim-jsx'
Plug 'jparise/vim-graphql', { 'tag': '1.*' }
Plug 'HerringtonDarkholme/yats.vim'  " Typescript syntax
" Plug 'ianks/vim-tsx' " Possible indentation issues with TSX
Plug 'mhartington/nvim-typescript', {'do': './install.sh'} " Typescript deoplete integration

call plug#end()


" various settings
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
set termguicolors
set background=dark
colorscheme solarized8_flat " rigel
set diffopt=filler,internal,algorithm:histogram,indent-heuristic
set ignorecase
set smartcase

" source some aliases for shell
set shell=/bin/bash\ --rcfile\ ~/.ssh/api_keys

" paste and keep register
xnoremap <expr> p 'pgv"'.v:register.'y'
" Or could try
" xnoremap p "_dP


" local vimrc support
set secure
set exrc


" custom filetype settings
autocmd BufNewFile,BufRead apple-app-site-association set filetype=json
autocmd BufNewFile,BufRead *Dockerfile* set filetype=dockerfile
autocmd BufNewFile,BufRead .babelrc,.bowerrc,.eslintrc,.jshintrc set filetype=json
autocmd BufNewFile,BufRead .ripgreprc set filetype=conf
autocmd BufNewFile,BufRead *.conf set filetype=conf
autocmd BufNewFile,BufRead *.css set filetype=scss
autocmd BufNewFile,BufRead .env* set filetype=sh
autocmd BufNewFile,BufRead .env*.php set filetype=php
autocmd Filetype Makefile setlocal ts=4 sw=4 sts=0 expandtab


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


" deoplete
let g:deoplete#enable_at_startup = 1


" LanguageClient-neovim
let g:LanguageClient_serverCommands = {
    \ 'css': ['css-languageserver', '--stdio'],
    \ 'html': ['html-languageserver', '--stdio'],
    \ 'less': ['css-languageserver', '--stdio'],
    \ 'sass': ['css-languageserver', '--stdio'],
    \ 'scss': ['css-languageserver', '--stdio'],
    \ }
    " \ 'php': ['php-language-server'],
    " \ 'golang': ['go-langserver'],
    " \ 'typescript': ['javascript-typescript-stdio'],
    " \ 'typescript.tsx': ['javascript-typescript-stdio'],
    " \ 'javascript': ['flow lsp'],
    " \ 'javascript.jsx': ['flow lsp'],
    " \ 'yaml': ['yaml-language-server'],
" Disable linting + highlighting errors... let ALE do that through other means
let g:LanguageClient_diagnosticsEnable = 0
" let g:LanguageClient_rootMarkers = ['.flowconfig']


" editorconfig-vim
let g:EditorConfig_core_mode = 'external_command'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
"let g:EditorConfig_verbose=1


" UltiSnips
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-n>"
let g:UltiSnipsJumpBackwardTrigger="<c-p>"


" If you want :UltiSnipsEdit to split your window.
"let g:UltiSnipsEditSplit="vertical"


" buftabline
let g:buftabline_show=2
let g:buftabline_indicators=1
let g:buftabline_numbers=0
let g:buftabline_path=1


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


" vim-multiple-cursors
" let g:multi_cursor_select_all_key = '<c-a>'


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
