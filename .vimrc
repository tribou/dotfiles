call plug#begin('~/.vim/plugged')


" Misc
Plug 'airblade/vim-gitgutter'
Plug 'altercation/vim-colors-solarized'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'jiangmiao/auto-pairs'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-repeat'
Plug 't9md/vim-surround_custom_mapping'
Plug 'vim-scripts/marvim'

" Syntax/Auto-complete
Plug 'scrooloose/syntastic'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --gocode-completer --tern-completer' }
Plug 'editorconfig/editorconfig-vim'

" Other webdev
Plug 'mattn/emmet-vim'
Plug 'JulesWang/css.vim'
Plug 'cakebaker/scss-syntax.vim'
Plug 'wavded/vim-stylus'
Plug 'mustache/vim-mustache-handlebars'

" Markdown
Plug 'suan/vim-instant-markdown'

" Golang
Plug 'fatih/vim-go'

" HashiCorp
Plug 'hashivim/vim-consul'
Plug 'hashivim/vim-nomadproject'
Plug 'hashivim/vim-ottoproject'
Plug 'hashivim/vim-packer'
Plug 'hashivim/vim-terraform'
Plug 'hashivim/vim-vagrant'
Plug 'hashivim/vim-vaultproject'

" Other Languages
Plug 'docker/docker', { 'rtp': 'contrib/syntax/vim' }
Plug 'elixir-lang/vim-elixir'
Plug 'vim-scripts/nginx.vim'
Plug 'apple/swift', { 'rtp': 'utils/vim' }
Plug 'cespare/vim-toml'
Plug 'chrisbra/unicode.vim'

" JavaScript
Plug 'jelera/vim-javascript-syntax'
Plug 'bigfish/vim-js-context-coloring'
Plug 'kchmck/vim-coffee-script'
Plug 'flowtype/vim-flow'
Plug 'heavenshell/vim-jsdoc'
Plug 'mxw/vim-jsx'
Plug 'aaronj1335/underscore-templates.vim'
" Plug 'pangloss/vim-javascript'
Plug '~/dev/vim-syntax-js'

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

" ctrlp
let g:ctrlp_custom_ignore = {
  \ 'dir':  '^(build|node_modules|\.(git|hg|svn|tmp|vagrant))$',
  \ 'file': '\v\.(exe|so|swp|dll)$',
  \ }
let g:ctrlp_user_command = ['.git/', 'cd %s && git ls-files -oc --exclude-standard | grep -v "build/\|node_modules/\|public/\|vendor/"']

let g:ctrlp_working_path_mode = 'r'

" editorconfig-vim
let g:EditorConfig_core_mode = 'external_command'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
"let g:EditorConfig_verbose=1

" marvim
let marvim_find_key = 'mf'      " change find key from <F2> to 'space' 
let marvim_store_key = 'ms'     " change store key from <F3> to 'ms' 
let marvim_register = 'q'       " change used register from 'q' to 'c' 

" NERDTree
map <c-t> :NERDTreeToggle<CR>

" syntastic
let g:syntastic_mode_map = {
  \ "mode": "active",
  \ "passive_filetypes": ["scss"] }
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_javascript_eslint_exec = 'eslint_d'
let g:syntastic_javascript_eslint_args = '--cache'
let g:syntastic_flow_checkers = ['']
let g:syntastic_go_checkers = ['gofmt', 'golint']
let g:syntastic_yaml_checkers = ['jsyaml']
"let g:syntastic_go_checkers = ['gofmt', 'golint', 'go']
"let g:syntastic_javascript_flow_exe = 'flow'
"let g:syntastic_javascript_checkers = ['eslint', 'flow']
"let g:statline_syntastic = 0
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
let g:syntasitc_ignore_files = ['node_modules']
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0

" vim-airline
let g:airline#extensions#tabline#enabled = 1

" vim-instant-markdown
let g:instant_markdown_slow = 1

" vim-flow
let g:flow#autoclose = 1
let g:flow#enable = 0

" vim-fugitive
"set statusline+=%{fugitive#statusline()}

" indentLine
let g:indentLine_char = '.'
let g:indentLine_conceallevel = 0

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

" vim-surround_custom_mapping
let g:surround_custom_mapping = {}
let g:surround_custom_mapping.javascript = {
  \ 'x':  "{/* \r */}",
  \ }
let g:surround_custom_mapping._ = {
  \ 'j':  "/* \r */",
  \ 'h':  "{{!-- \r --}}",
  \ }

" YouCompleteMe
let g:ycm_autoclose_preview_window_after_completion = 1
