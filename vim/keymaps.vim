"
" Key Mappings
"
" misc
nnoremap <silent> <esc><esc> :<c-u>noh<CR>
nnoremap <Leader>r :<c-u>source ~/.vimrc<CR>
nnoremap <Leader>w <c-w><c-w>
nnoremap <Leader>q :<c-u>q<CR>

" Reveal syntax
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" popup menu browsing
inoremap <expr> <c-j> pumvisible() ? "\<c-n>" : "\<c-j>"
inoremap <expr> <c-k> pumvisible() ? "\<c-p>" : "\<c-k>"

" buffer browsing
nnoremap <silent> <Leader>d :<c-u>bd<CR><c-g>
nmap <silent> <Leader>k <Plug>(dotfiles-bnext)
nmap <silent> <Leader>j <Plug>(dotfiles-bprevious)

" scratch/preview window browsing
nnoremap <silent> <Leader>c :<c-u>pc<CR>

" fzf
nnoremap <silent> <c-p> :<c-u>Fzf<CR>
nnoremap <silent> <c-s> :<c-u>Rg!<CR>
nnoremap <silent> <c-b> :<c-u>Buffers<CR>
nnoremap <silent> <c-c> :<c-u>Commits<CR>

" fugitive
" noremap <silent> <Leader>b :Gblame<CR>
nmap <silent> <Leader>b <Plug>(dotfiles-gblame)
noremap <silent> <Leader>o :Gbrowse<CR>

" NERDTree
map <silent> <Leader>t :<c-u>NERDTreeToggle<CR>
map <silent> <Leader>f :<c-u>NERDTreeFind<CR>

" undotree
nnoremap <silent> <Leader>u :<c-u>UndotreeToggle<CR>

" ALE
nmap <Leader>ad :<c-u>ALEDetail<CR>
nmap <Leader>af :<c-u>ALEFix<CR>
nmap <Leader><Leader>f :<c-u>ALEFix<CR>
nmap <Leader>ah :<c-u>ALEHover<CR>
nmap <Leader>h :<c-u>ALEHover<CR>
nmap <Leader>ai :<c-u>ALEInfo<CR>
nmap <Leader>an :<c-u>ALENext<CR>
nmap <Leader>at :<c-u>ALEToggle<CR>

" coc.nvim
" Show commands
nmap <space>c :<c-u>CocList commands<CR>
nmap <space>r <Plug>(coc-rename)
nmap <silent> <space>d <Plug>(coc-definition)
nmap <silent> <space>f :<c-u>call CocActionAsync('doHover')<CR>
nmap <silent> <space>h :<c-u>call CocActionAsync('doHover')<CR>
" Manage extensions
nnoremap <space>e  :<c-u>CocList extensions<CR>
" Find symbol of current document
nnoremap <space>o  :<c-u>CocList outline<CR>
" Search workspace symbols
nnoremap <space>s  :<c-u>CocList -I symbols<CR>
" Do default action for next item.
nnoremap <space>j  :<c-u>CocNext<CR>
" Do default action for previous item.
nnoremap <space>k  :<c-u>CocPrev<CR>
" Resume latest coc list
nnoremap <space>p  :<c-u>CocListResume<CR>

" Prettier
nmap <Leader><Leader>p :<c-u>Prettier<CR>

" vim-jsdoc
nnoremap <c-1> <Plug>(jsdoc)

" vim-vdebug
nmap <F5> :<c-u>VdebugStart<CR>

" Filetype-dependent key remapping
" autocmd FileType css nnoremap <silent> <buffer> K :call LanguageClient#textDocument_definition()<CR>
" Global key remapping to ALE by default
nnoremap <silent> K :<c-u>ALEGoToDefinition<CR>

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
