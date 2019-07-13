"
" Key Mappings
"
" misc
nnoremap <silent> <esc><esc> :noh<CR>
nnoremap <Leader>r :source ~/.vimrc<CR>
nnoremap <Leader>w <c-w><c-w>

" popup menu browsing
inoremap <expr> <c-j> pumvisible() ? "\<c-n>" : "\<c-j>"
inoremap <expr> <c-k> pumvisible() ? "\<c-p>" : "\<c-k>"

" buffer browsing
nnoremap <silent> <Leader>d :bd<CR><c-g>
nnoremap <silent> <Leader>j :bp<CR><c-g>
nnoremap <silent> <Leader>k :bn<CR><c-g>

" scratch/preview window browsing
nnoremap <silent> <Leader>c :pc<CR>

" fzf
nnoremap <silent> <c-p> :FZF<CR>
nnoremap <silent> <c-s> :Rg!<CR>
nnoremap <silent> <c-b> :Buffers<CR>
nnoremap <silent> <c-c> :Commit<CR>

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
autocmd FileType css nnoremap <silent> <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType scss nnoremap <silent> <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType less nnoremap <silent> <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType html nnoremap <silent> <buffer> K :call LanguageClient#textDocument_definition()<CR>
autocmd FileType php nnoremap <silent> <buffer> K :ALEGoToDefinition<CR>
autocmd FileType go nnoremap <silent> <buffer> K :ALEGoToDefinition<CR>
autocmd FileType javascript nnoremap <silent> <buffer> K :ALEGoToDefinition<CR>
autocmd FileType javascript.jsx nnoremap <silent> <buffer> K :ALEGoToDefinition<CR>
autocmd FileType typescript nnoremap <silent> <buffer> K :ALEGoToDefinition<CR>
autocmd FileType typescript.tsx nnoremap <silent> <buffer> K :ALEGoToDefinition<CR>
autocmd FileType sh nnoremap <silent> <buffer> K :ALEGoToDefinition<CR>

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
