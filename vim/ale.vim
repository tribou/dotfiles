" ale
let g:ale_completion_enabled = 0 " using deoplete instead
let g:ale_fix_on_save = 0 " enable on project-by-project basis with local .exrc
let g:ale_floating_preview = 1
let g:ale_javascript_eslint_executable = 'eslint_d'
let g:ale_javascript_eslint_use_global = 1
let g:ale_typescript_eslint_executable = 'eslint_d'
let g:ale_typescript_eslint_use_global = 1
let g:ale_php_langserver_executable = $HOME . '/.composer/vendor/bin/php-language-server.php'
let g:ale_php_langserver_use_global = 1
let g:ale_php_cs_fixer_executable = $HOME . '/.composer/vendor/bin/php-cs-fixer'
let g:ale_php_cs_fixer_use_global = 1
" let g:ale_php_cs_fixer_options = '--cache-file ' . $HOME . '/.vim/php-cs-fixer-cache' . getcwd() . '/.php_cs.cache'
let g:ale_php_cs_fixer_options = '--using-cache=no'
let g:ale_go_bingo_executable = 'gopls'
let g:ale_linters = {
  \   'javascript': [
  \       'eslint',
  \   ],
  \   'javascript.jsx': [
  \       'eslint',
  \   ],
  \   'json': [
  \       'jsonlint',
  \   ],
  \   'typescript': [
  \       'eslint',
  \       'tsserver',
  \   ],
  \   'typescriptreact': [
  \       'eslint',
  \       'tsserver',
  \   ],
  \   'elixir': [
  \       'mix',
  \   ],
  \   'php': [
  \       'php',
  \       'langserver',
  \   ],
  \   'sh': [
  \       'language_server',
  \       'shellcheck',
  \   ],
  \   'go': [
  \       'gofmt',
  \       'golint',
  \       'gopls',
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
  \       'eslint',
  \       'prettier',
  \   ],
  \   'typescript.tsx': [
  \       'eslint',
  \       'prettier',
  \   ],
  \   'typescriptreact': [
  \       'eslint',
  \       'prettier',
  \   ],
  \   'json': [
  \       'prettier',
  \   ],
  \   'jsonc': [
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
  \   'sh': [
  \       'trim_whitespace',
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
  \   'terraform': [
  \       'terraform',
  \   ],
  \}
