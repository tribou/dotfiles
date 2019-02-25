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
Plug 'jiangmiao/auto-pairs'
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
Plug 'fatih/vim-go', { 'tag': '*', 'do': ':GoInstallBinaries' }

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

" ale
let g:ale_completion_enabled = 0 " using deoplete instead
let g:ale_fix_on_save = 0 " enable on project-by-project basis with local .exrc
let g:ale_javascript_eslint_executable = 'eslint_d'
let g:ale_javascript_eslint_use_global = 1
let g:ale_linters = {
  \   'javascript': [
  \       'eslint',
  \   ],
  \   'javascript.jsx': [
  \       'eslint',
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
  \       'eslint',
  \       'prettier',
  \   ],
  \   'javascript.jsx': [
  \       'eslint',
  \       'prettier',
  \   ],
  \   'typescript': [
  \       'prettier',
  \       'tslint',
  \   ],
  \   'typescript.tsx': [
  \       'prettier',
  \       'tslint',
  \   ],
  \   'json': [
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
  \   'php': [
  \       'php_cs_fixer',
  \   ],
  \   'go': [
  \       'goimports',
  \       'gofmt',
  \   ],
  \}
  " \   'html': [
  " \       'tidy',
  " \   ],


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
" command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --pretty --smart-case --max-columns=160 '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)


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
nnoremap <Leader>r :source ~/.vimrc<CR>
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
nmap <Leader>ad :ALEDetail<CR>
nmap <Leader>af :ALEFix<CR>
nmap <Leader><Leader>f :ALEFix<CR>
nmap <Leader>ah :ALEHover<CR>
nmap <Leader>ai :ALEInfo<CR>
nmap <Leader>an :ALENext<CR>
nmap <Leader>at :ALEToggle<CR>

" Prettier
nmap <Leader><Leader>p :Prettier<CR>

" vim-jsdoc
nnoremap <c-1> <Plug>(jsdoc)

" Filetype-dependent key remapping
autocmd FileType css nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType scss nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType less nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType html nnoremap <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType php nnoremap <buffer> K :ALEGoToDefinition<CR>
autocmd FileType go nnoremap <buffer> K :ALEGoToDefinition<CR>
autocmd FileType javascript nnoremap <buffer> K :ALEGoToDefinition<CR>
autocmd FileType javascript.jsx nnoremap <buffer> K :ALEGoToDefinition<CR>
autocmd FileType typescript nnoremap <buffer> K :ALEGoToDefinition<CR>
autocmd FileType typescript.tsx nnoremap <buffer> K :ALEGoToDefinition<CR>
autocmd FileType sh nnoremap <buffer> K :ALEGoToDefinition<CR>

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
