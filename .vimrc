" Functions that have to load first
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


call plug#begin('~/.local/share/nvim/plugged')

" Misc
Plug 'airblade/vim-gitgutter'
Plug 'altercation/vim-colors-solarized'
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
" Plug 'ap/vim-buftabline'
Plug 'tribou/vim-buftabline'
" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
Plug 'jiangmiao/auto-pairs'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
"Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
"Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-commentary'
Plug 't9md/vim-surround_custom_mapping'
"Plug 'vim-scripts/marvim'

"" Syntax/Auto-complete
Plug 'w0rp/ale', { 'tag': 'v2.*' }
"Plug 'scrooloose/syntastic'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"Plug 'Valloric/YouCompleteMe', { 'do': './install.py --gocode-completer --tern-completer' }
Plug 'editorconfig/editorconfig-vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'tpope/vim-liquid'
" Plug '~/dev/vim-snippets'
" Plug 'autozimu/LanguageClient-neovim', {
"     \ 'branch': 'next',
"     \ 'do': 'bash install.sh',
"     \ }

" Other webdev
Plug 'mattn/emmet-vim'
Plug 'JulesWang/css.vim'
Plug 'cakebaker/scss-syntax.vim'
Plug 'wavded/vim-stylus'
Plug 'mustache/vim-mustache-handlebars'

" Markdown
Plug 'euclio/vim-markdown-composer', { 'do': function('BuildComposer') }

"" Golang
"Plug 'fatih/vim-go', { 'tag': '*' }

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
" Plug 'ruanyl/vim-fixmyjs'
Plug '~/dev/vim-syntax-js'
" Plug 'flowtype/vim-flow' using flow-language-server instead
Plug 'pangloss/vim-javascript', { 'tag': '1.2.*' }
Plug 'mxw/vim-jsx'
Plug 'jparise/vim-graphql', { 'tag': '1.*' }
Plug 'HerringtonDarkholme/yats.vim'
Plug 'mhartington/nvim-typescript', {'do': './install.sh'}

call plug#end()


" various settings
silent !mkdir -p $HOME/.vim/swapfiles
syntax enable
set clipboard+=unnamed
set conceallevel=0
colorscheme solarized
set background=dark
set directory=$HOME/.vim/swapfiles//
set number
filetype plugin indent on
set tabstop=2
set shiftwidth=2
set expandtab ts=2 sw=2 ai
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
set hidden
nmap <esc><esc> :noh<return>


" custom filetype settings
autocmd BufNewFile,BufRead apple-app-site-association set filetype=json
autocmd BufNewFile,BufRead *Dockerfile* set filetype=dockerfile
autocmd BufNewFile,BufRead .babelrc,.bowerrc,.eslintrc,.jshintrc set filetype=json
autocmd BufNewFile,BufRead *.conf set filetype=conf
autocmd BufNewFile,BufRead *.css set filetype=scss
autocmd BufNewFile,BufRead .env* set filetype=sh
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


" ale
" set nocompatible
" filetype off
" let &runtimepath.=',~/.local/share/nvim/plugged/ale'
" filetype plugin on
" silent! helptags ALL
let g:ale_completion_enabled = 0 " using deoplete instead
let g:ale_fix_on_save = 1
let g:ale_javascript_eslint_executable = 'eslint_d'
let g:ale_javascript_eslint_use_global = 1
let g:ale_linters = {
  \   'javascript': [
  \       'eslint',
  \       'flow',
  \   ],
  \   'javascript.jsx': [
  \       'eslint',
  \       'flow',
  \   ],
  \   'elixir': [
  \       'mix',
  \   ],
  \   'sh': [
  \       'language_server',
  \   ],
  \   'vue': [
  \       'vls',
  \   ],
  \}
let g:ale_fixers = {
  \   'javascript': [
  \       'eslint',
  \       'prettier',
  \   ],
  \   'javascript.jsx': [
  \       'eslint',
  \       'prettier',
  \   ],
  \   'json': [
  \       'prettier',
  \   ],
  \   'typescript': [
  \       'prettier',
  \   ],
  \   'vue': [
  \       'prettier',
  \   ],
  \   'scss': [
  \       'prettier',
  \   ],
  \   'css': [
  \       'prettier',
  \   ],
  \   'less': [
  \       'prettier',
  \   ],
  \   'markdown': [
  \       'prettier',
  \   ],
  \   'yaml': [
  \       'prettier',
  \   ],
  \   'html': [
  \       'tidy',
  \   ],
  \   'php': [
  \       'php_cs_fixer',
  \   ],
  \   'go': [
  \       'goimports',
  \       'gofmt',
  \   ],
  \}
  " \   'javascript': [
  " \       'eslint',
  " \       'flow-language-server',
  " \   ],
  " \   'javascript.jsx': [
  " \       'eslint',
  " \       'flow-language-server',
  " \   ],
" nmap <Leader><Leader>f <Plug>(ale_fix)
" nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
" nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>


" ctrlp
let g:ctrlp_custom_ignore = {
  \ 'dir':  '^(build|dist|node_modules|\.(git|hg|svn|tmp|vagrant))$',
  \ 'file': '\v\.(exe|so|swp|dll)$',
  \ }
let g:ctrlp_user_command = ['.git/', 'cd %s && git ls-files -oc --exclude-standard | grep -v "build/\|dist/\|node_modules/\|public/\|vendor/\|\.gz\|\.tgz\|\.png\|\.jpg\|\.jpeg\|\.gif"']
let g:ctrlp_working_path_mode = 'r'


" deoplete
let g:deoplete#enable_at_startup = 1

" LanguageClient-neovim
" let g:LanguageClient_serverCommands = {
"     \ 'golang': ['go-langserver'],
"     \ 'typescript': ['javascript-typescript-stdio'],
"     \ }
    " \ 'javascript': ['flow-language-server', '--stdio'],
    " \ 'javascript.jsx': ['flow-language-server', '--stdio'],
    " \ 'yaml': ['yaml-language-server'],
" nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
" nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>

let g:LanguageClient_rootMarkers = ['.flowconfig']

" editorconfig-vim
let g:EditorConfig_core_mode = 'external_command'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
"let g:EditorConfig_verbose=1


" marvim
" let marvim_find_key = 'mf'      " change find key from <F2> to 'space' 
" let marvim_store_key = 'ms'     " change store key from <F3> to 'ms' 
" let marvim_register = 'q'       " change used register from 'q' to 'c' 


" NERDTree
map <c-t> :NERDTreeToggle<CR>


" syntastic
" let g:syntastic_mode_map = {
"   \ "mode": "active",
"   \ "passive_filetypes": ["scss"] }
" let g:syntastic_javascript_checkers = ['eslint']
" let g:syntastic_javascript_eslint_exec = 'eslint_d'
" let g:syntastic_javascript_eslint_args = '--cache'
" let g:syntastic_typescript_checkers = ['tslint']
" "let g:syntastic_typescript_tslint_args = ''
" let g:syntastic_flow_checkers = ['']
" let g:syntastic_go_checkers = ['gofmt', 'golint']
" let g:syntastic_yaml_checkers = ['jsyaml']
" "let g:syntastic_go_checkers = ['gofmt', 'golint', 'go']
" "let g:syntastic_javascript_flow_exe = 'flow'
" "let g:syntastic_javascript_checkers = ['eslint', 'flow']
" "let g:statline_syntastic = 0
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*
" "let g:syntastic_always_populate_loc_list = 1
" "let g:syntastic_auto_loc_list = 1
" let g:syntasitc_ignore_files = ['node_modules']
" let g:syntastic_check_on_open = 0
" let g:syntastic_check_on_wq = 0


" UltiSnips
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-n>"
let g:UltiSnipsJumpBackwardTrigger="<c-p>"


" If you want :UltiSnipsEdit to split your window.
"let g:UltiSnipsEditSplit="vertical"


" lightline.vim
set laststatus=2
set noshowmode
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'active': {
      \   'left': [
      \             [ 'linter_errors', 'linter_warnings' ],
      \             [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename' ]
      \           ],
      \ },
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
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
  " let splitpath = split(expand('%'), '/')
  " let path = len(splitpath) < 2 ? expand('%') : join([splitpath[-2], splitpath[-1]], '/')
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


" buftabline
let g:buftabline_show=2
let g:buftabline_indicators=1
let g:buftabline_numbers=0
let g:buftabline_path=1


" vim-fixmyjs
" noremap <Leader><Leader>f :Fixmyjs<CR>   
" let g:fixmyjs_engine = 'eslint'
" let g:fixmyjs_use_local = 1
" let g:fixmyjs_executable = 'eslint_d'
" let g:fixmyjs_rc_filename = ['.eslintrc.yml', '.eslintrc', '.eslintrc.yml']


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
nmap <c-1> <Plug>(jsdoc)


" vim-jsx
let g:jsx_ext_required = 0


" vim-markdown-composer
" let g:markdown_composer_custom_css = [
"   \ 'https://cdn.jsdelivr.net/gh/sindresorhus/github-markdown-css@2/github-markdown.css',
"   \ ]


" vim-surround_custom_mapping
let g:surround_custom_mapping = {}
let g:surround_custom_mapping._ = {
  \ 'j':  "/* \r */",
  \ 'h':  "{{!-- \r --}}",
  \ 'x':  "{/* \r */}",
  \ }


" YouCompleteMe
" let g:ycm_autoclose_preview_window_after_completion = 1


" Other
"function! SyntaxItem()
"  return synIDattr(synID(line("."),col("."),1),"name")
"endfunction
"
"set statusline+=%{SyntaxItem()}

" Moving lines
" Normal mode
" nnoremap <c-j> :m .+1<cr>==
" nnoremap <c-k> :m .-2<cr>==

" Insert mode
" inoremap <C-j> <ESC>:m .+1<CR>==gi
" inoremap <C-k> <ESC>:m .-2<CR>==gi

" Visual mode
" vnoremap <C-j> :m '>+1<CR>gv=gv
" vnoremap <C-k> :m '<-2<CR>gv=gv
