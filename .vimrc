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
" Using fzf instead of ctrlp
" Plug 'ctrlpvim/ctrlp.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
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
"Plug 'vim-scripts/marvim'
Plug 'mileszs/ack.vim'
Plug 'justinmk/vim-sneak'
Plug 'ap/vim-css-color'
" Plug 'junegunn/rainbow_parentheses.vim'
Plug 'mbbill/undotree'

" Debugging
Plug 'vim-vdebug/vdebug'

" Auto-formatting
Plug 'editorconfig/editorconfig-vim'
" Using this only for the manual :Prettier command
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'javascript.jsx', 'typescript', 'typescript.tsx', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }

" Auto-complete
"Plug 'scrooloose/syntastic'
"Plug 'Valloric/YouCompleteMe', { 'do': './install.py --gocode-completer --tern-completer' }
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
Plug 'HerringtonDarkholme/yats.vim'  " Typescript syntax
Plug 'ianks/vim-tsx'
" Plug 'mhartington/nvim-typescript', {'do': './install.sh'}

" PHP
Plug 'roxma/LanguageServer-php-neovim',  {'do': 'composer install && composer run-script parse-stubs'}

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
  \   'typescript': [
  \       'tslint',
  \       'tsserver',
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
  \   ],
  \   'javascript.jsx': [
  \   ],
  \   'json': [
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
  \   'php': [
  \       'php_cs_fixer',
  \   ],
  \   'go': [
  \       'goimports',
  \       'gofmt',
  \   ],
  \}
  " \   'typescript': [
  " \       'prettier',
  " \       'tslint',
  " \   ],
  " \   'javascript': [
  " \       'eslint',
  " \       'flow-language-server',
  " \   ],
  " \   'javascript.jsx': [
  " \       'eslint',
  " \       'prettier',
  " \   ],
  " \   'javascript.jsx': [
  " \       'eslint',
  " \       'flow-language-server',
  " \   ],
  " \   'json': [
  " \       'prettier',
  " \   ],
  " \   'html': [
  " \       'tidy',
  " \   ],


" ctrlp
let g:ctrlp_custom_ignore = {
  \ 'dir':  '^(dist|node_modules|\.(git|hg|svn|tmp|vagrant))$',
  \ 'file': '\v\.(exe|so|swp|dll)$',
  \ }
let g:ctrlp_user_command = ['.git/', 'cd %s && git ls-files -oc --exclude-standard | grep -v "dist\.?.*/\|node_modules/\|vendor/\|\.gz\|\.tgz\|\.png\|\.jpg\|\.jpeg\|\.gif"']
let g:ctrlp_working_path_mode = 'r'


" deoplete
let g:deoplete#enable_at_startup = 1


" LanguageClient-neovim
let g:LanguageClient_serverCommands = {
    \ 'css': ['css-languageserver', '--stdio'],
    \ 'golang': ['go-langserver'],
    \ 'html': ['html-languageserver', '--stdio'],
    \ 'less': ['css-languageserver', '--stdio'],
    \ 'sass': ['css-languageserver', '--stdio'],
    \ 'scss': ['css-languageserver', '--stdio'],
    \ 'javascript': ['javascript-typescript-stdio', '--stdio'],
    \ 'javascript.jsx': ['javascript-typescript-stdio', '--stdio'],
    \ 'typescript': ['javascript-typescript-stdio'],
    \ 'typescript.tsx': ['javascript-typescript-stdio'],
    \ 'php': ['php-language-server'],
    \ }
    " \ 'javascript': ['flow-language-server', '--stdio'],
    " \ 'javascript.jsx': ['flow-language-server', '--stdio'],
    " \ 'yaml': ['yaml-language-server'],
" Disable linting + highlighting errors... let ALE do that through other means
let g:LanguageClient_diagnosticsEnable = 0

" let g:LanguageClient_rootMarkers = ['.flowconfig']


" editorconfig-vim
let g:EditorConfig_core_mode = 'external_command'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
"let g:EditorConfig_verbose=1

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
let $FZF_DEFAULT_COMMAND = 'fd --type file --color=always --hidden --exclude .git'
let $FZF_DEFAULT_OPTS = ''
      \ . ' --ansi'  " support fd colors

command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --pretty --smart-case --max-columns=160 '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

" marvim
" let marvim_find_key = 'mf'      " change find key from <F2> to 'space' 
" let marvim_store_key = 'ms'     " change store key from <F3> to 'ms' 
" let marvim_register = 'q'       " change used register from 'q' to 'c' 


" ncm2
" enable ncm2 for all buffers
" autocmd BufEnter * call ncm2#enable_for_buffer()

" IMPORTANTE: :help Ncm2PopupOpen for more information
" set completeopt=noinsert,menuone,noselect


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


" YouCompleteMe
" let g:ycm_autoclose_preview_window_after_completion = 1


" Other
"function! SyntaxItem()
"  return synIDattr(synID(line("."),col("."),1),"name")
"endfunction
"
"set statusline+=%{SyntaxItem()}

"
" Key Mappings
"
" misc
nnoremap <esc><esc> :noh<CR>
nnoremap <Leader>r :source %<CR>
nnoremap <Leader>w <c-w><c-w>

" buffer browsing
nnoremap <Leader>d :bd<CR>
nnoremap <Leader>j :bp<CR>
nnoremap <Leader>k :bn<CR>

" fzf
nnoremap <silent> <c-p> :FZF<CR>
nnoremap <silent> <c-s> :Rg!<CR>
nnoremap <silent> <c-b> :Buffers<CR>
nnoremap <silent> <Leader>c :Commit<CR>

" fugitive
noremap <silent> <Leader>b :Gblame<CR>
noremap <silent> <Leader>o :Gbrowse<CR>

" NERDTree
map <Leader>t :NERDTreeToggle<CR>

" undotree
nnoremap <Leader>u :UndotreeToggle<CR>

" ALE
" nmap <Leader><Leader>f <Plug>(ale_fix)

" vim-jsdoc
nnoremap <c-1> <Plug>(jsdoc)

" LanguageClient
" nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
" nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
" Filetype-dependent key remapping
autocmd FileType css nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType scss nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType less nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType golang nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType html nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType php nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType javascript nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType javascript.jsx nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType typescript nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType typescript.tsx nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>

" noremap <Leader><Leader>f :Fixmyjs<CR>   

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
"
