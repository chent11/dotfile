# dotfile

Personal dotfiles for Linux / WSL2 and macOS: Neovim, zsh (oh-my-zsh + Powerlevel10k), tmux, zellij, Claude Code settings.

## New machine

```sh
# 0. macOS only: compiler + git
xcode-select --install

# 1. Give the machine SSH access to GitHub (submodules use git@ URLs)
ssh-keygen -t ed25519 -C "$USER@$(hostname)"
cat ~/.ssh/id_ed25519.pub        # add to https://github.com/settings/keys

# 2. Clone and bootstrap
git clone --recurse-submodules git@github.com:chent11/dotfile.git ~/dotfile
~/dotfile/bootstrap.sh
```

`bootstrap.sh --help` lists the `--skip-*` flags. The script is idempotent; files it replaces in `$HOME` are moved to `~/.dotfile-backup/<timestamp>/`.

On Linux it uses apt, the Neovim AppImage (`bin/neovim-update`) and `cargo install tree-sitter-cli`; on macOS it installs Homebrew if needed and takes neovim, tree-sitter-cli and zellij from there.

## Updating Neovim

```sh
neovim-update            # Linux: checks the latest release, verifies sha256, installs to /usr/bin/nvim
brew upgrade neovim      # macOS
```
