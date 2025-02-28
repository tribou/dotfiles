# dotfiles

### Quick Start

```sh
git clone https://github.com/tribou/dotfiles.git
cd dotfiles
./bootstrap.sh
```

### Regenerate a new GPG key

https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key

### Config

**`~/.ssh/api_keys`** file

- `GIT_SIGNING_KEY` - export the gpg public signing key if it should be used. Find it with `gpg --list-keys`.
