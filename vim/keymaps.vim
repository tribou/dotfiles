"
" Key Mappings
"
" misc
nnoremap <silent> <esc><esc> :noh<CR>
nnoremap <Leader>r :source ~/.vimrc<CR>
nnoremap <Leader>w <c-w><c-w>
nnoremap <Leader>q :q<CR>

" popup menu browsing
inoremap <expr> <c-j> pumvisible() ? "\<c-n>" : "\<c-j>"
inoremap <expr> <c-k> pumvisible() ? "\<c-p>" : "\<c-k>"

" buffer browsing
nmap <silent> <Leader>d <Plug>(dotfiles-bdelete)
nmap <silent> <Leader>k <Plug>(dotfiles-bnext)
nmap <silent> <Leader>j <Plug>(dotfiles-bprevious)

" scratch/preview window browsing
nnoremap <silent> <Leader>c :pc<CR>

" fzf
nnoremap <silent> <c-p> :Fzf<CR>
nnoremap <silent> <c-s> :Rg!<CR>
nnoremap <silent> <c-b> :Buffers<CR>
nnoremap <silent> <c-c> :Commits<CR>
nnoremap <silent> <c-h> :<c-u>History<CR>

" fugitive
noremap <silent> <Leader>b :Gblame<CR>
noremap <silent> <Leader>o :Gbrowse<CR>

" NERDTree
map <silent> <Leader>t :NERDTreeToggle<CR>
map <silent> <Leader>f :NERDTreeFind<CR>

" undotree
nnoremap <silent> <Leader>u :UndotreeToggle<CR>

" ALE
nmap <Leader>ad :ALEDetail<CR>
nmap <Leader>af :ALEFix<CR>
nmap <Leader><Leader>f :ALEFix<CR>
nmap <Leader>ah :ALEHover<CR>
nmap <Leader>h :ALEHover<CR>
nmap <Leader>ai :ALEInfo<CR>
nmap <Leader>an :ALENext<CR>
nmap <Leader>at :ALEToggle<CR>

" Prettier
nmap <Leader><Leader>p :Prettier<CR>

" vim-jsdoc
nnoremap <c-1> <Plug>(jsdoc)

" vim-vdebug
nmap <F5> :VdebugStart<CR>

" Filetype-dependent key remapping
" autocmd FileType css nnoremap <silent> <buffer> K :call LanguageClient#textDocument_definition()<CR>
" Global key remapping to ALE by default
nnoremap <silent> K :ALEGoToDefinition<CR>

" Moving/selection
nnoremap H ^
vnoremap H ^
nnoremap J *
nnoremap L $
vnoremap L $

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
