call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'altercation/vim-colors-solarized'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'editorconfig/editorconfig-vim'
Plug 'elixir-lang/vim-elixir'
Plug 'jiangmiao/auto-pairs'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'mattn/emmet-vim'
Plug 'mustache/vim-mustache-handlebars'
Plug 'mxw/vim-jsx'
Plug 'pangloss/vim-javascript'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
"Plug 'scrooloose/syntastic'
Plug 'suan/vim-instant-markdown'
Plug 't9md/vim-surround_custom_mapping'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-repeat'
Plug 'Valloric/YouCompleteMe'
Plug 'vim-scripts/nginx.vim'

call plug#end()

" various settings
syntax enable
colorscheme solarized
set background=dark

set number
filetype plugin indent on
set tabstop=2
set shiftwidth=2
set expandtab ts=2 sw=2 ai

" custom filetype settings
autocmd BufNewFile,BufRead *.Dockerfile set filetype=dockerfile
autocmd BufNewFile,BufRead .babelrc,.bowerrc,.eslintrc,.jshintrc set filetype=json
autocmd BufNewFile,BufRead *.conf set filetype=conf

" crontab editing
autocmd filetype crontab setlocal nobackup nowritebackup

" ctrlp
let g:ctrlp_custom_ignore = {
  \ 'dir':  'node_modules$\|\.(git|hg|svn|tmp|vagrant)$',
  \ 'file': '\v\.(exe|so|swp|dll)$',
  \ }
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

let g:ctrlp_working_path_mode = 'r'

" editorconfig-vim
let g:EditorConfig_core_mode = 'external_command'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
"let g:EditorConfig_verbose=1

" NERDTree
map <c-t> :NERDTreeToggle<CR>

" syntastic
"let g:syntastic_javascript_checkers = ['eslint']
"let g:syntastic_javascript_eslint_exec = 'eslint_d'
"let g:statline_syntastic = 0
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 0
"let g:syntastic_check_on_wq = 0

" vim-airline
let g:airline#extensions#tabline#enabled = 1

" vim-instant-markdown
let g:instant_markdown_slow = 1

" vim-fugitive
"set statusline+=%{fugitive#statusline()}

" vim-surround_custom_mapping
let g:surround_custom_mapping = {}
let g:surround_custom_mapping.javascript = {
  \ 'j':  "/* \r */",
  \ 'x':  "{/* \r */}",
  \ }

" YouCompleteMe
let g:ycm_autoclose_preview_window_after_completion = 1
