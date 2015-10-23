call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'Valloric/YouCompleteMe'
Plug 'flazz/vim-colorschemes'
Plug 'airblade/vim-gitgutter'
Plug 'kien/ctrlp.vim'
Plug 'bling/vim-airline'
Plug 'editorconfig/editorconfig-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'terryma/vim-multiple-cursors'
Plug 'pangloss/vim-javascript'
Plug 'mattn/emmet-vim'
Plug 'mxw/vim-jsx'
Plug 'suan/vim-instant-markdown'
Plug 'scrooloose/syntastic'

call plug#end()

" various settings
syntax on
colorscheme SlateDark
set number
filetype plugin indent on
set tabstop=2
set shiftwidth=2
set expandtab ts=2 sw=2 ai

" custom filetype settings
au BufNewFile,BufRead *.Dockerfile set filetype=dockerfile
au BufNewFile,BufRead .eslintrc set filetype=json

" crontab editing
autocmd filetype crontab setlocal nobackup nowritebackup

" syntastic
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_javascript_eslint_exec = 'eslint_d'
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" vim-airline
let g:airline#extensions#tabline#enabled = 1

" ctrlp
let g:ctrlp_custom_ignore = {
  \ 'dir':  'node_modules$\|\.(git|hg|svn|vagrant)$',
  \ 'file': '\v\.(exe|so|dll)$',
  \ }

let g:ctrlp_working_path_mode = 'r'
let g:EditorConfig_core_mode = 'external_command'
let g:EditorConfig_verbose=1

" vim-instant-markdown
let g:instant_markdown_slow = 1

