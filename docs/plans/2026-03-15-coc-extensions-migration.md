# CoC Extensions Migration Design

## Summary

Migrate CoC extension management from vim-plug to `g:coc_global_extensions` (the current CoC-recommended approach). Update bootstrap to install extensions headlessly so the CI test passes.

## Changes

### `init.vim`

**Remove** lines 85-101 (individual `Plug 'neoclide/coc-*'` entries).

**Keep** `Plug 'neoclide/coc.nvim', {'branch': 'release'}` — framework stays in vim-plug.

**Keep** `Plug 'andys8/vscode-jest-snippets'` — not a CoC npm extension, it's a VS Code snippet pack used as a vim plugin. Remove the `{'do': 'npm ci'}` build hook (snippets need no build step).

**Add** after `call plug#end()`:

```vim
" CoC extensions (managed by CoC, not vim-plug)
let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-pairs',
  \ 'coc-css',
  \ 'coc-highlight',
  \ 'coc-json',
  \ 'coc-git',
  \ 'coc-snippets',
  \ 'coc-eslint',
  \ 'coc-emoji',
  \ 'coc-solargraph',
  \ 'coc-yaml',
  \ 'coc-html',
  \ 'coc-lists',
  \ 'coc-svg',
  \ ]
```

Extension mapping notes:
- `coc-sources` (packages/emoji) → `coc-emoji` (standalone, active)
- `coc-elixir` (amiralies, archived) → dropped (`@elixir-tools/coc-elixir` does not exist on npm)
- All others: direct rename from Plug entry to npm package name

### `scripts/bootstrap-test.sh`

Add after `nvim --headless +PlugInstall +qall`:

```bash
echo "==> Installing CoC extensions..."
nvim --headless -c "CocUpdateSync" -c "qall" 2>/dev/null
```

`CocUpdateSync` installs all extensions listed in `g:coc_global_extensions` that are not yet present, then exits synchronously.

### Test

`tests/integration/nvim_health.bats` line 32-34 stays unchanged — the assertion `[ -d "$HOME/.config/coc/extensions/node_modules" ]` will pass once bootstrap installs extensions.

## What Does NOT Change

- `Plug 'neoclide/coc.nvim', {'branch': 'release'}` stays in vim-plug
- `coc-settings.json` untouched
- All other vim-plug entries untouched
- goss.yaml untouched
