# mise Default Packages Design

**Date:** 2026-03-22
**Scope:** Add default packages files for Node, Ruby, and Python so mise auto-installs global packages after each runtime installation.

## Background

mise supports default packages files for Node, Ruby, and Python:

| Runtime | File | Installed via |
|---------|------|---------------|
| Node | `~/.default-node-packages` | npm install -g |
| Ruby | `~/.default-gems` | gem install |
| Python | `~/.default-python-packages` | pip install |

mise reads these files automatically after installing any version of the respective runtime. This replaces manual install steps in `bootstrap.sh` and the `npm-install-global` shell function.

## New Dotfiles

### `default-node-packages`

Replaces the `npm-install-global` function in `lib/commands.sh` as the source of truth for global Node packages (function is kept for manual re-runs):

```
eas-cli
eslint_d
editorconfig
intelephense
js-yaml
jsonlint
neovim
prettier
react-devtools
nodemon
tern
tslint
typescript
bash-language-server
flow-bin
vue-language-server
vscode-css-languageserver-bin
vscode-html-languageserver-bin
```

### `default-gems`

Replaces the manual `gem install` block in `bootstrap.sh`:

```
neovim
solargraph
```

### `default-python-packages`

Replaces the manual `pip3 install` block in `bootstrap.sh`:

```
pynvim
```

## Changes to Existing Files

### `bootstrap.sh`

**Add** three symlink calls alongside other dotfile symlinks:
```bash
linkFileToHome "default-node-packages" ".default-node-packages"
linkFileToHome "default-gems" ".default-gems"
linkFileToHome "default-python-packages" ".default-python-packages"
```

**Remove** the manual gem install block:
```bash
if  [ -s "$(which gem)"  ] && [ -z "$(gem list -i "^neovim$")" ]
then
  gem install neovim solargraph --no-document
fi
```

**Remove** the manual pynvim pip install block:
```bash
if [ -s "$(which python3)" ] && ! python3 -c "import pynvim" &>/dev/null
then
  pip3 install --user pynvim
fi
```

### `goss.yaml`

Add symlink existence assertions:
```yaml
/root/.default-node-packages:
  exists: true
  filetype: symlink
/root/.default-gems:
  exists: true
  filetype: symlink
/root/.default-python-packages:
  exists: true
  filetype: symlink
```

## Notes

- `npm-install-global` in `lib/commands.sh` is kept for manual re-runs — it remains useful for recovering a broken global install without reinstalling Node.
- The default packages files are symlinked (not copied) so changes in the dotfiles repo take effect immediately.
- goss symlink assertions follow the existing bug fix policy: regressions in symlink setup are caught by `just test`.
