call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'scrooloose/nerdtree'
Plug 'Valloric/YouCompleteMe'
Plug 'flazz/vim-colorschemes'
Plug 'airblade/vim-gitgutter'
Plug 'kien/ctrlp.vim'
Plug 'bling/vim-airline'
Plug 'editorconfig/editorconfig-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'terryma/vim-multiple-cursors'

call plug#end()

syntax on
colorscheme SlateDark

let g:airline#extensions#tabline#enabled = 1
let g:ctrlp_custom_ignore = {
  \ 'dir':  'node_modules$\|\.(git|hg|svn|vagrant)$',
  \ 'file': '\v\.(exe|so|dll)$',
  \ }

let g:ctrlp_working_path_mode = 'r'

