# dotfile

Personal dotfiles for Linux / WSL2 and macOS: Neovim, zsh (oh-my-zsh + Powerlevel10k), tmux, zellij, lazygit, mise tool list, Claude Code settings.

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

System packages come from apt (Linux) or Homebrew (macOS, installed if needed). Everything else — neovim, node, tmux, zellij, fzf, tree-sitter, uv, atuin, zoxide, delta, linters — is installed by [mise](https://mise.jdx.dev) from `.config/mise/config.toml`, identically on both platforms.

## Updating tools

```sh
mise upgrade             # every "latest" entry in .config/mise/config.toml -> newest release
mise ls                  # what is installed and which config selects it
mise use -g neovim@nightly   # switch a tool; pin with an exact version instead of "latest"
```
