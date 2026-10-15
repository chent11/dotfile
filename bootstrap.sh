#!/usr/bin/env bash
#
# Bootstrap this dotfile repo on a fresh machine: Ubuntu / Debian (incl. WSL2)
# or macOS.
#
# Before running, make sure the machine can reach GitHub over SSH, because the
# submodules use git@github.com URLs:
#
#   ssh-keygen -t ed25519 -C "$USER@$(hostname)"
#   cat ~/.ssh/id_ed25519.pub        # add this key to GitHub
#   git clone --recurse-submodules git@github.com:chent11/dotfile.git ~/dotfile
#   ~/dotfile/bootstrap.sh
#
# macOS only: run `xcode-select --install` first so git and a C compiler exist.
#
# Idempotent: every step checks for existing state before acting, and anything
# it replaces in $HOME is moved to ~/.dotfile-backup/<timestamp>/ first.
#
# Flags:
#   --skip-pkgs    do not run apt-get / Homebrew (no sudo, or packages present)
#   --skip-nvim    do not provision Neovim plugins / LSP servers / parsers
#   --skip-tools   do not install mise (and every tool in .config/mise/config.toml)
#                  or rustup
#   --skip-shell   do not install oh-my-zsh / change login shell

set -euo pipefail

DOTFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfile-backup/$(date +%Y%m%d-%H%M%S)"

case "$(uname -s)" in
  Linux)  OS=linux ;;
  Darwin) OS=macos ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

SKIP_PKGS=0 SKIP_NVIM=0 SKIP_TOOLS=0 SKIP_SHELL=0
for arg in "$@"; do
  case "$arg" in
    --skip-pkgs|--skip-apt|--skip-brew) SKIP_PKGS=1 ;;
    --skip-nvim)  SKIP_NVIM=1 ;;
    --skip-tools|--skip-langs) SKIP_TOOLS=1 ;;
    --skip-shell) SKIP_SHELL=1 ;;
    -h|--help)    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# --------------------------------------------------------------------------
# helpers (bash 3.2 compatible: macOS ships that version)
# --------------------------------------------------------------------------
step()  { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info()  { printf '    %s\n' "$*"; }
warn()  { printf '    \033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
have()  { command -v "$1" >/dev/null 2>&1; }

# canonical absolute path; BSD readlink gained -f only in macOS 12.3
resolve() {
  if readlink -f / >/dev/null 2>&1; then readlink -f "$1"
  else python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
  fi
}

# link SRC -> DEST, backing up whatever is at DEST unless it is already the link
link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(resolve "$dest")" = "$(resolve "$src")" ]; then
    info "ok      $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP"
    mv "$dest" "$BACKUP/$(basename "$dest")"
    info "backed up $dest -> $BACKUP/"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  info "linked  $dest -> $src"
}

clone_if_missing() {
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then info "ok      $(basename "$dest")"
  else git clone -q --depth=1 "$url" "$dest"; info "cloned  $(basename "$dest")"; fi
}

# put Homebrew on PATH for the rest of this script (Apple Silicon or Intel)
load_brew() {
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# mise shims make every mise-managed tool (node, nvim, tree-sitter, ...)
# resolvable for the rest of this script without an interactive shell
MISE_SHIMS="$HOME/.local/share/mise/shims"
export PATH="$MISE_SHIMS:$HOME/.local/bin:$PATH"

# --------------------------------------------------------------------------
# 0. sanity
# --------------------------------------------------------------------------
step "Repository: $DOTFILE ($OS)"
if [ ! -f "$DOTFILE/.zshrc" ] || [ ! -d "$DOTFILE/.config/nvim" ]; then
  echo "This does not look like the dotfile repo. Aborting." >&2
  exit 1
fi
if [ "$DOTFILE" != "$HOME/dotfile" ]; then
  warn "repo is not at ~/dotfile; .config/zellij/config.kdl expects \$HOME/dotfile/bin/zellij-keys"
fi
if [ "$OS" = macos ] && ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are missing. Run: xcode-select --install   then re-run this script." >&2
  exit 1
fi

git -C "$DOTFILE" submodule update --init --recursive

# --------------------------------------------------------------------------
# 1. system packages: only what the OS itself should own. Everything with a
#    pinned or fast-moving version (tmux, zellij, neovim, node, fzf, ...)
#    comes from mise in step 5 and is listed in .config/mise/config.toml.
# --------------------------------------------------------------------------
if [ "$SKIP_PKGS" = 0 ]; then
  if [ "$OS" = linux ]; then
    step "Installing system packages (apt)"
    if ! have apt-get; then
      warn "apt-get not found; install the equivalents of the list below manually"
    else
      sudo apt-get update -qq
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        git curl wget unzip jq psmisc ca-certificates \
        build-essential clang \
        zsh command-not-found \
        ripgrep fd-find xclip \
        python3 python3-pip python3-venv \
        golang-go
      # Debian/Ubuntu ship fd as "fdfind"; the Neovim picker and .zshrc call "fd".
      if ! have fd && have fdfind; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        info "linked fdfind -> ~/.local/bin/fd"
      fi
    fi
  else
    step "Installing system packages (Homebrew)"
    load_brew
    if ! have brew; then
      NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      load_brew
      info "installed Homebrew"
    fi
    # psmisc/xclip are not needed: macOS has fuser and pbcopy built in.
    # btop comes from brew here: upstream has no macOS binaries for mise.
    brew install -q \
      git curl wget jq \
      zsh \
      ripgrep fd \
      python go btop
  fi
else
  step "Skipping system packages (--skip-pkgs)"
fi

[ "$OS" = macos ] && load_brew
for t in git curl zsh rg jq; do
  have "$t" || { echo "required tool missing: $t" >&2; exit 1; }
done

# --------------------------------------------------------------------------
# 2. symlinks into $HOME
# --------------------------------------------------------------------------
step "Linking config files into \$HOME"
mkdir -p "$HOME/.config" "$HOME/.local/bin"

link "$DOTFILE/.zshrc"                            "$HOME/.zshrc"
link "$DOTFILE/.tmux.conf"                        "$HOME/.tmux.conf"
link "$DOTFILE/.tmux_break_other_panes.sh"        "$HOME/.tmux_break_other_panes.sh"
link "$DOTFILE/.tmux_handle_pane_intelligently.sh" "$HOME/.tmux_handle_pane_intelligently.sh"
link "$DOTFILE/.config/nvim"                      "$HOME/.config/nvim"
link "$DOTFILE/.config/zellij/config.kdl"         "$HOME/.config/zellij/config.kdl"
link "$DOTFILE/.config/zellij/layouts"            "$HOME/.config/zellij/layouts"
link "$DOTFILE/.config/mise/config.toml"          "$HOME/.config/mise/config.toml"
link "$DOTFILE/.config/lazygit/config.yml"        "$HOME/.config/lazygit/config.yml"
link "$DOTFILE/.claude"                           "$HOME/.claude"

for script in "$DOTFILE"/bin/*; do
  [ -f "$script" ] || continue
  case "$script" in *.lua) continue ;; esac   # helpers for other scripts, not commands
  chmod +x "$script"
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# --------------------------------------------------------------------------
# 3. ssh: authorise the public keys from the submodule
# --------------------------------------------------------------------------
step "Authorising SSH public keys from ssh_pub_keys/"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys" && chmod 600 "$HOME/.ssh/authorized_keys"
for pub in "$DOTFILE"/ssh_pub_keys/*.pub; do
  [ -f "$pub" ] || continue
  # join wrapped lines (one key file is split over three lines) and trim
  key="$(tr '\n' ' ' < "$pub" | sed 's/  */ /g; s/^ //; s/ $//')"
  [ -n "$key" ] || continue
  if grep -qxF "$key" "$HOME/.ssh/authorized_keys"; then
    info "ok      $(basename "$pub")"
  else
    printf '%s\n' "$key" >> "$HOME/.ssh/authorized_keys"
    info "added   $(basename "$pub")"
  fi
done

# --------------------------------------------------------------------------
# 4. shell: oh-my-zsh, plugins, theme, login shell
#    (fzf, atuin and zoxide are mise tools; .zshrc wires them up itself)
# --------------------------------------------------------------------------
if [ "$SKIP_SHELL" = 0 ]; then
  step "Setting up zsh"
  ZSH_DIR="$HOME/.oh-my-zsh"
  ZSH_CUSTOM="$ZSH_DIR/custom"
  if [ ! -d "$ZSH_DIR" ]; then
    # KEEP_ZSHRC: the installer must not overwrite our symlinked ~/.zshrc
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    info "ok      oh-my-zsh"
  fi

  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_if_missing https://github.com/romkatv/powerlevel10k             "$ZSH_CUSTOM/themes/powerlevel10k"

  if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
    if chsh -s "$(command -v zsh)"; then info "login shell set to zsh (takes effect at next login)"
    else warn "chsh failed; run: chsh -s $(command -v zsh)"; fi
  fi
  [ -f "$HOME/.p10k.zsh" ] || warn "~/.p10k.zsh is not in the repo; run 'p10k configure' on first zsh start"
else
  step "Skipping shell setup (--skip-shell)"
fi

# --------------------------------------------------------------------------
# 5. tools: mise installs everything in .config/mise/config.toml (node, neovim,
#    tmux, zellij, fzf, tree-sitter, uv, linters, ...) side by side under
#    ~/.local/share/mise and exposes them through shims. rustup stays separate:
#    mise's rust backend only wraps it, and cargo is wanted for ad-hoc builds.
# --------------------------------------------------------------------------
if [ "$SKIP_TOOLS" = 0 ]; then
  step "Installing mise and its tools"
  if [ ! -x "$HOME/.local/bin/mise" ]; then
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh
    info "installed mise $("$HOME/.local/bin/mise" --version)"
  else
    info "ok      mise $("$HOME/.local/bin/mise" --version)"
  fi
  # uv first: the pipx: tools in the config are built with it when present
  mise install uv
  mise install
  mise ls --current --no-header 2>/dev/null | sed 's/^/    /' || true

  if [ ! -f "$HOME/.cargo/env" ]; then
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal
    info "installed rustup"
  else
    info "ok      rust"
  fi
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
else
  step "Skipping mise tools and rustup (--skip-tools)"
fi

# --------------------------------------------------------------------------
# 6. Neovim: plugins, parsers, LSP servers (the binary itself came from mise)
# --------------------------------------------------------------------------
if [ "$SKIP_NVIM" = 0 ]; then
  step "Provisioning Neovim plugins, parsers and LSP servers (headless)"
  if ! have nvim; then
    echo "nvim not found; it is installed by mise in step 5 (do not combine --skip-tools with a fresh machine)." >&2
    exit 1
  fi
  info "ok      $(nvim --version | head -1)"
  mkdir -p "$HOME/.nvim/undodir"   # options.lua: opt.undodir
  for t in node cargo tree-sitter cc; do
    have "$t" || warn "$t not on PATH; some parsers or Mason packages may fail to build"
  done
  nvim --headless -c "luafile $DOTFILE/bin/nvim-bootstrap.lua"
else
  step "Skipping Neovim provisioning (--skip-nvim)"
fi

# --------------------------------------------------------------------------
# 7. git identity (only if unset), editor, delta pager, global ignores
# --------------------------------------------------------------------------
step "Git identity"
if [ -z "$(git config --global user.name || true)" ]; then
  read -rp "    git user.name: " gname  && git config --global user.name  "$gname"
  read -rp "    git user.email: " gmail && git config --global user.email "$gmail"
fi
git config --global init.defaultBranch main
git config --global core.editor nvim
# delta (a mise tool) as diff pager; lazygit's config.yml reuses the same [delta] section
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.dark true
git config --global merge.conflictStyle zdiff3
git config --global diff.colorMoved default
if [ "$OS" = macos ]; then
  # Finder drops .DS_Store into every directory it opens; ignore it in all repos.
  # ~/.config/git/ignore is read by git without any core.excludesFile setting.
  mkdir -p "$HOME/.config/git"
  if ! grep -qxF ".DS_Store" "$HOME/.config/git/ignore" 2>/dev/null; then
    printf '.DS_Store\n' >> "$HOME/.config/git/ignore"
    info "added .DS_Store to ~/.config/git/ignore"
  fi
fi
info "$(git config --global user.name) <$(git config --global user.email)>"

# --------------------------------------------------------------------------
# done
# --------------------------------------------------------------------------
step "Done"
[ -d "$BACKUP" ] && info "replaced files were moved to $BACKUP"
cat <<'EOT'
    Next steps:
      1. Log out and back in (or run: exec zsh) to start the new login shell.
      2. Install a Nerd Font in your terminal; the Neovim config uses its icons.
      3. Run 'p10k configure' if the prompt looks plain.
      4. Optional: 'atuin import zsh' to load an existing ~/.zsh_history, and
         'atuin login' to sync history between machines.
    Updating tools later: 'mise upgrade' moves every "latest" entry in
    .config/mise/config.toml to its newest release.
EOT
