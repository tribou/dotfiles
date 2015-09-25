call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
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

call plug#end()

" various settings
syntax on
colorscheme SlateDark
filetype plugin on
set number
set tabstop=4
set shiftwidth=4
autocmd Filetype yaml setlocal ts=2 sts=2 sw=2

" crontab editing
autocmd filetype crontab setlocal nobackup nowritebackup

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

