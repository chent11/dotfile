#!/usr/bin/env bash
#
# Verify a machine provisioned by bootstrap.sh. Every symlink, system package,
# mise tool, shell integration, multiplexer config, Neovim feature and git
# setting is checked for presence *and* behaviour, so a green run means the
# environment is the one this repo describes. CI runs it on clean Ubuntu and
# macOS images (.github/workflows/bootstrap.yml); run it locally any time:
#
#   ~/dotfile/tests/check.sh        # exit 0 when every check passes
#
# bash 3.2 compatible (macOS ships that version). Needs no sudo.

set -u

DOTFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
  Linux)  OS=linux ;;
  Darwin) OS=macos ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

# The environment bootstrap.sh leaves behind, without going through an
# interactive shell (the shell itself is tested further down).
if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"
fi
MISE_SHIMS="$HOME/.local/share/mise/shims"
export PATH="$MISE_SHIMS:$HOME/.local/bin:$PATH"
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export TERM="${TERM:-xterm-256color}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0 FAIL=0

# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
section() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
pass()    { PASS=$((PASS + 1)); printf '    \033[32mok\033[0m    %s\n' "$*"; }
fail()    { FAIL=$((FAIL + 1)); printf '    \033[1;31mFAIL\033[0m  %s\n' "$*"; }
indent()  { sed 's/^/          /'; }

# check LABEL CMD [ARGS...]: pass when CMD exits 0, otherwise show its output
check() {
  local label="$1" out
  shift
  if out="$("$@" 2>&1)"; then pass "$label"
  else fail "$label"; printf '%s\n' "$out" | tail -15 | indent; fi
}
# sh_check LABEL 'SNIPPET': SNIPPET runs under bash -e with pipefail
# (has_line replaces `grep -q` in pipelines: -q exits at the first match, the
# writer gets SIGPIPE and pipefail would report that as a failure)
sh_check() { check "$1" bash -o pipefail -ec "has_line() { grep \"\$@\" >/dev/null; }; $2"; }
# eq LABEL EXPECTED ACTUAL
eq() { if [ "$2" = "$3" ]; then pass "$1: $2"; else fail "$1: expected '$2', got '$3'"; fi; }
# has LABEL NEEDLE HAYSTACK
has() {
  case "$3" in
    *"$2"*) pass "$1" ;;
    *) fail "$1: '$2' not found in: $(printf '%s' "$3" | tr '\n' ' ' | head -c 200)" ;;
  esac
}

resolve() {
  if readlink -f / >/dev/null 2>&1; then readlink -f "$1"
  else python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
  fi
}
mode() {
  if [ "$OS" = macos ]; then stat -f %Lp "$1"; else stat -c %a "$1"; fi
}
# run a command line under a pseudo-terminal, the way a login shell sees it
in_pty() {
  if [ "$OS" = macos ]; then script -q /dev/null bash -c "$1"
  else script -qec "$1" /dev/null
  fi
}

# --------------------------------------------------------------------------
# 1. symlinks: parsed from the `link` lines of bootstrap.sh so the two never drift
# --------------------------------------------------------------------------
section "Symlinks into \$HOME"
while read -r src dest; do
  [ -n "$src" ] || continue
  if [ -L "$HOME/$dest" ] && [ "$(resolve "$HOME/$dest")" = "$(resolve "$DOTFILE/$src")" ]; then
    pass "~/$dest -> $src"
  else
    fail "~/$dest should be a symlink to $src"
  fi
done <<EOF
$(sed -n 's/^link "\$DOTFILE\/\([^"]*\)" *"\$HOME\/\([^"]*\)".*/\1 \2/p' "$DOTFILE/bootstrap.sh")
EOF

for script in "$DOTFILE"/bin/*; do
  [ -f "$script" ] || continue
  case "$script" in *.lua) continue ;; esac
  name="$(basename "$script")"
  if [ -x "$HOME/.local/bin/$name" ] && [ "$(resolve "$HOME/.local/bin/$name")" = "$(resolve "$script")" ]; then
    pass "~/.local/bin/$name -> bin/$name (executable)"
  else
    fail "~/.local/bin/$name should be an executable link to bin/$name"
  fi
done
# the spell submodule tracks only the compiled list; en.utf-8.add is ignored there
check "git submodules checked out" test -s "$DOTFILE/.config/nvim/spell/en.utf-8.add.spl"

# --------------------------------------------------------------------------
# 2. system packages (apt / Homebrew layer)
# --------------------------------------------------------------------------
section "System packages"
for t in git git-lfs curl wget jq zsh rg fd python3 go cc unzip; do
  check "$t on PATH" command -v "$t"
done
if [ "$OS" = linux ]; then
  for t in xclip fuser clang fc-cache xz; do check "$t on PATH" command -v "$t"; done
  check "command-not-found hook present" test -f /etc/zsh_command_not_found
else
  check "brew on PATH" command -v brew
fi
sh_check "cc compiles and runs a C program" \
  "printf 'int main(void){return 0;}' > '$TMP/a.c' && cc -o '$TMP/a' '$TMP/a.c' && '$TMP/a'"
sh_check "go builds and runs a program" \
  "printf 'package main\nimport \"fmt\"\nfunc main(){fmt.Println(\"go ok\")}\n' > '$TMP/m.go' && cd '$TMP' && go run m.go | has_line 'go ok'"

# --------------------------------------------------------------------------
# 3. mise: every tool in .config/mise/config.toml resolves through a shim and runs
# --------------------------------------------------------------------------
section "mise tools"
check "mise installed" mise --version
sh_check "mise config parses and nothing is missing" \
  "mise ls --missing --no-header | { [ '$OS' = macos ] && grep -v '^btop ' || cat; } | { ! grep .; }"

bin_for() {
  case "$1" in
    neovim)         echo nvim ;;
    npm:typescript) echo tsc ;;
    npm:*|pipx:*)   echo "${1#*:}" ;;
    *)              echo "$1" ;;
  esac
}
version_of() {
  case "$1" in
    tmux) tmux -V ;;
    *)    "$1" --version ;;
  esac
}
TOOLS="$(awk '/^\[/{sec=$1} sec=="[tools]" && /=/{gsub(/"/,"",$1); print $1}' "$DOTFILE/.config/mise/config.toml")"
for tool in $TOOLS; do
  bin="$(bin_for "$tool")"
  if [ "$tool" = btop ] && [ "$OS" = macos ]; then
    # no macOS build upstream: bootstrap.sh installs it with Homebrew instead
    check "btop installed by Homebrew" brew list --versions btop
    check "btop --version" btop --version
    continue
  fi
  path="$(command -v "$bin" 2>/dev/null || true)"
  case "$path" in
    "$MISE_SHIMS"/*)
      if ver="$(version_of "$bin" 2>&1)"; then
        pass "$tool: $(printf '%s' "$ver" | head -1 | cut -c1-60)"
      else
        fail "$tool: $bin --version failed"; printf '%s\n' "$ver" | tail -5 | indent
      fi ;;
    "") fail "$tool: $bin not on PATH" ;;
    *)  fail "$tool: $bin resolves to $path instead of a mise shim" ;;
  esac
done
has "node major version pinned to 24" "v24." "$(node --version 2>&1)"

# --------------------------------------------------------------------------
# 4. tool behaviour: each tool does its job, not just prints a version
# --------------------------------------------------------------------------
section "Tool behaviour"
printf 'import os\n\nx: int = "a"\n' > "$TMP/bad.py"
printf 'x = 1\n' > "$TMP/good.py"
printf 'const n: number = 1;\nexport {};\n' > "$TMP/good.ts"
printf 'const n: number = "x";\nexport {};\n' > "$TMP/bad.ts"

sh_check "node runs JavaScript"                  "node -e 'process.exit(1 + 1 === 2 ? 0 : 1)'"
sh_check "tsc accepts a valid file"              "tsc --noEmit --strict '$TMP/good.ts'"
sh_check "tsc rejects a type error (TS2322)"     "{ tsc --noEmit --strict '$TMP/bad.ts' || true; } | has_line TS2322"
check    "typescript-language-server runs"       typescript-language-server --version
sh_check "ruff check flags an unused import"     "{ ruff check --output-format concise '$TMP/bad.py' || true; } | has_line F401"
sh_check "ruff format --check passes clean code" "ruff format --check '$TMP/good.py'"
sh_check "black --check passes clean code"       "black -q --check '$TMP/good.py'"
sh_check "pyright reports a type error"          "{ pyright '$TMP/bad.py' || true; } | has_line 'not assignable'"
sh_check "mypy reports a type error"             "{ mypy --no-color-output '$TMP/bad.py' || true; } | has_line 'Incompatible types'"
sh_check "pylint flags an unused import"         "{ pylint --disable=all --enable=unused-import '$TMP/bad.py' || true; } | has_line W0611"
check    "pre-commit runs"                       pre-commit --version
sh_check "uv runs python"                        "uv run -q --no-project python -c 'print(1)' | has_line -x 1"
sh_check "fzf filters input"                     "printf 'apple\nbanana\n' | fzf --filter ban | has_line -x banana"
sh_check "zoxide records and queries a directory" \
  "_ZO_DATA_DIR='$TMP/zo' zoxide add '$TMP' && _ZO_DATA_DIR='$TMP/zo' zoxide query '$(basename "$TMP")' | has_line -x '$TMP'"
sh_check "zoxide init emits the z function"      "zoxide init zsh | has_line __zoxide_z"
sh_check "atuin opens a fresh history database" \
  "ATUIN_SESSION=dotfile-check ATUIN_DB_PATH='$TMP/atuin.db' ATUIN_RECORD_STORE_PATH='$TMP/records.db' atuin history list"
sh_check "atuin config sets enter_accept" "grep -Eq '^enter_accept *= *true' '$HOME/.config/atuin/config.toml'"
sh_check "atuin init emits the Ctrl+R widget"    "atuin init zsh --disable-up-arrow | has_line atuin-search"
sh_check "delta picks up [delta] from ~/.gitconfig" "delta --show-config | has_line -E '^ *line-numbers += *true'"
sh_check "lazygit config.yml is valid YAML" \
  "uv run -q --no-project --with pyyaml python -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' '$DOTFILE/.config/lazygit/config.yml'"
sh_check "lazygit renders diffs with delta"      "grep -q 'command: delta' '$DOTFILE/.config/lazygit/config.yml'"
check    "tree-sitter CLI runs"                  tree-sitter --version
check    "cargo runs"                            cargo --version
sh_check "rustc compiles and runs a program" \
  "printf 'fn main(){println!(\"rust ok\")}' > '$TMP/h.rs' && rustc -o '$TMP/h' '$TMP/h.rs' && '$TMP/h' | has_line 'rust ok'"

# --------------------------------------------------------------------------
# 5. zsh: start a real interactive shell under a pty and inspect it from inside
# --------------------------------------------------------------------------
section "zsh"
check ".zshrc parses (zsh -n)" zsh -n "$DOTFILE/.zshrc"
for d in .oh-my-zsh .oh-my-zsh/custom/plugins/zsh-autosuggestions \
         .oh-my-zsh/custom/plugins/zsh-syntax-highlighting .oh-my-zsh/custom/themes/powerlevel10k; do
  check "~/$d present" test -d "$HOME/$d"
done

cat > "$TMP/probe.zsh" <<'EOF'
print "theme=$ZSH_THEME"
print "p10k=$( (( $+functions[p10k] )) && print yes || print no)"
print "p10k_config=$( (( ${#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS} )) && print yes || print no)"
print "autosuggest=$( (( $+functions[_zsh_autosuggest_start] )) && print yes || print no)"
print "highlight=$( (( $+functions[_zsh_highlight] )) && print yes || print no)"
print "gitfast=$( (( $+functions[_git] )) && print yes || print no)"
print "mise=$(whence -w mise)"
print "z=$(whence -w z)"
print "zi=$(whence -w zi)"
print "ctrl_r=$(bindkey '^R')"
print "ctrl_t=$(bindkey '^T')"
print "alt_c=$(bindkey '^[c')"
print "editor=$EDITOR"
print "visual=$VISUAL"
print "vim_alias=$(alias vim)"
print "nvim=$(command -v nvim)"
print "cargo=$(command -v cargo)"
print "histsize=$HISTSIZE"
print "sharehistory=$( [[ -o sharehistory ]] && print on || print off)"
print "shims=$( [[ ":$PATH:" == *":$HOME/.local/share/mise/shims:"* ]] && print yes || print no)"
print "fzf_default=$FZF_DEFAULT_COMMAND"
print "title=$ZSH_THEME_TERM_TITLE_IDLE"
print "PROBE_END"
EOF
# no config wizard (CI has no ~/.p10k.zsh) and no oh-my-zsh update prompt
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true DISABLE_AUTO_UPDATE=true
# The probe writes its answers to a file. The pty output is kept separately to
# scan for startup errors; prompt and terminal escapes there can garble lines.
ZOUT="$(in_pty "zsh -ic 'source $TMP/probe.zsh > $TMP/probe.out'" 2>&1 | tr -d '\r')"
ZPROBE="$(cat "$TMP/probe.out" 2>/dev/null)"
zget() { printf '%s\n' "$ZPROBE" | sed -n "s/^$1=//p" | head -1; }

has "interactive zsh starts and runs a command" PROBE_END "$ZPROBE"
noise="$(printf '%s\n' "$ZOUT" | grep -Ei "command not found|no such file|can't change option|parse error|ERROR|permission denied" || true)"
if [ -z "$noise" ]; then pass "zsh startup printed no errors"
else fail "zsh startup printed errors"; printf '%s\n' "$noise" | indent; fi
eq  "oh-my-zsh theme"                    "powerlevel10k/powerlevel10k" "$(zget theme)"
eq  "powerlevel10k loaded"               yes "$(zget p10k)"
eq  "~/.p10k.zsh prompt config applied"  yes "$(zget p10k_config)"
eq  "zsh-autosuggestions loaded"         yes "$(zget autosuggest)"
eq  "zsh-syntax-highlighting loaded"     yes "$(zget highlight)"
eq  "gitfast completion loaded"          yes "$(zget gitfast)"
eq  "mise activated (shell function)"    "mise: function" "$(zget mise)"
eq  "zoxide: z"                          "z: function"  "$(zget z)"
eq  "zoxide: zi"                         "zi: function" "$(zget zi)"
has "Ctrl+R bound to atuin"              atuin-search    "$(zget ctrl_r)"
has "Ctrl+T bound to fzf files"          fzf-file-widget "$(zget ctrl_t)"
has "Alt+C bound to fzf cd"              fzf-cd-widget   "$(zget alt_c)"
eq  "EDITOR"                             nvim "$(zget editor)"
eq  "VISUAL"                             nvim "$(zget visual)"
has "vim aliased to nvim"                nvim "$(zget vim_alias)"
has "nvim resolves to the mise install"  mise "$(zget nvim)"
has "cargo on PATH"                      cargo "$(zget cargo)"
eq  "HISTSIZE"                           50000 "$(zget histsize)"
eq  "SHARE_HISTORY"                      on "$(zget sharehistory)"
eq  "mise shims on PATH"                 yes "$(zget shims)"
has "FZF_DEFAULT_COMMAND uses fd"        "fd --type f" "$(zget fzf_default)"
eq  "terminal title is the path, capped"  "%35<…<%~%<<" "$(zget title)"
for c in _mise _uv _atuin _delta; do
  check "generated completion ~/.cache/zsh/completions/$c" test -s "$HOME/.cache/zsh/completions/$c"
done

# --------------------------------------------------------------------------
# 6. tmux
# --------------------------------------------------------------------------
section "tmux"
check "tmux runs" tmux -V
SOCK=dotfile-check
tmux -L $SOCK kill-server 2>/dev/null || true
if tmux -L $SOCK -f /dev/null new-session -d -s check 'sleep 120'; then
  check "~/.tmux.conf loads without errors" tmux -L $SOCK source-file "$HOME/.tmux.conf"
  eq  "prefix"            'C-;'          "$(tmux -L $SOCK show-options -gv prefix)"
  eq  "prefix2"           M-e            "$(tmux -L $SOCK show-options -gv prefix2)"
  eq  "copy-mode keys"    vi             "$(tmux -L $SOCK show-window-options -gv mode-keys)"
  eq  "default-terminal"  tmux-256color  "$(tmux -L $SOCK show-options -gv default-terminal)"
  eq  "focus-events"      on             "$(tmux -L $SOCK show-options -gv focus-events)"
  if [ "$OS" = macos ]; then clip=pbcopy; else clip=xclip; fi
  has "copy-mode-vi y pipes to $clip" "$clip" "$(tmux -L $SOCK list-keys -T copy-mode-vi | grep -E ' y +send')"
  has "prefix j runs the pane script" ".tmux_handle_pane_intelligently.sh" "$(tmux -L $SOCK list-keys -T prefix | grep -E ' j +')"
  tmux -L $SOCK kill-server
else
  fail "tmux server could not start"
fi
for s in .tmux_break_other_panes.sh .tmux_handle_pane_intelligently.sh; do
  check "$s parses (bash -n)" bash -n "$DOTFILE/$s"
done

# --------------------------------------------------------------------------
# 7. zellij
# --------------------------------------------------------------------------
section "zellij"
check "zellij runs"                           zellij --version
check "config.kdl valid (zellij setup --check)" zellij setup --check
check "layout 'compact' valid"                zellij --layout compact setup --check
# the compact layout's bar is zellij's compact-bar with tab numbers, fetched by
# zellij from a release of github.com/chent11/zellij-compact-bar; bootstrap.sh
# pre-grants its permissions so the one-row bar never shows a permission prompt
ZBAR=$(sed -n 's/^ *compact-bar location="\(https:[^"]*\)".*/\1/p' "$DOTFILE/.config/zellij/config.kdl")
has "config.kdl uses a zellij-compact-bar release" \
  "https://github.com/chent11/zellij-compact-bar/releases/download/" "$ZBAR"
check "compact-bar release asset downloadable" curl -fsSIL -o /dev/null "$ZBAR"
case "$(uname -s)" in
  Darwin) ZPERM="$HOME/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl" ;;
  *)      ZPERM="${XDG_CACHE_HOME:-$HOME/.cache}/zellij/permissions.kdl" ;;
esac
sh_check "compact-bar permissions pre-granted" \
  "grep -A4 -F '\"$ZBAR\" {' '$ZPERM' | grep -q ReadApplicationState"
check "bin/zellij-keys parses (bash -n)"      bash -n "$DOTFILE/bin/zellij-keys"
sh_check "zellij-keys prints the prefix bindings" "zellij-keys | has_line 'Prefix: Ctrl ;'"

# --------------------------------------------------------------------------
# 8. git
# --------------------------------------------------------------------------
section "git"
eq "core.pager"             delta                "$(git config --global core.pager)"
eq "core.editor"            nvim                 "$(git config --global core.editor)"
eq "init.defaultBranch"     main                 "$(git config --global init.defaultBranch)"
eq "interactive.diffFilter" "delta --color-only" "$(git config --global interactive.diffFilter)"
eq "merge.conflictStyle"    zdiff3               "$(git config --global merge.conflictStyle)"
eq "diff.colorMoved"        default              "$(git config --global diff.colorMoved)"
eq "delta.navigate"         true                 "$(git config --global delta.navigate)"
eq "delta.line-numbers"     true                 "$(git config --global delta.line-numbers)"
eq "delta.dark"             true                 "$(git config --global delta.dark)"
eq "protocol.file.allow"    always               "$(git config --global protocol.file.allow)"
eq "filter.lfs.process"     "git-lfs filter-process" "$(git config --global filter.lfs.process)"
eq "filter.lfs.required"    true                 "$(git config --global filter.lfs.required)"
check "user.name set"  git config --global user.name
check "user.email set" git config --global user.email
REPO="$TMP/repo"
git init -q "$REPO"
eq "new repositories start on main" refs/heads/main "$(git -C "$REPO" symbolic-ref HEAD)"
printf 'one\n' > "$REPO/f" && git -C "$REPO" add f \
  && git -C "$REPO" -c user.name=t -c user.email=t@example.com commit -qm init && printf 'two\n' > "$REPO/f"
sh_check "git diff renders through delta with line numbers" "git -C '$REPO' diff | delta --paging=never | has_line '⋮'"
for f in .DS_Store sub/.DS_Store .claude/settings.local.json .claude/.cc-writes/x; do
  check "globally ignored: $f" git -C "$REPO" check-ignore -q --no-index "$f"
done
check "not ignored: .claude/settings.json" bash -c "! git -C '$REPO' check-ignore -q --no-index .claude/settings.json"
LFS="$TMP/lfs"
git init -q "$LFS"
sh_check "git lfs stores a tracked file as a pointer" "
  cd '$LFS'
  git lfs track '*.bin' >/dev/null
  head -c 2048 /dev/urandom > blob.bin
  git add .gitattributes blob.bin
  git -c user.name=t -c user.email=t@example.com commit -qm lfs
  git lfs ls-files | has_line blob.bin
  git cat-file -p HEAD:blob.bin | has_line '^version https://git-lfs'
"
eq "git var GIT_EDITOR" nvim "$(env -u VISUAL -u EDITOR -u GIT_EDITOR git var GIT_EDITOR)"

# --------------------------------------------------------------------------
# 9. ssh authorised keys from the submodule
# --------------------------------------------------------------------------
section "ssh"
eq "~/.ssh mode"                 700 "$(mode "$HOME/.ssh")"
eq "~/.ssh/authorized_keys mode" 600 "$(mode "$HOME/.ssh/authorized_keys")"
for pub in "$DOTFILE"/ssh_pub_keys/*.pub; do
  [ -f "$pub" ] || continue
  key="$(tr '\n' ' ' < "$pub" | sed 's/  */ /g; s/^ //; s/ $//')"
  check "authorised: $(basename "$pub")" grep -qxF "$key" "$HOME/.ssh/authorized_keys"
done

# --------------------------------------------------------------------------
# 10. Claude Code config shipped in .claude/
# --------------------------------------------------------------------------
section "Claude Code config"
check ".claude/settings.json is valid JSON"    jq empty "$DOTFILE/.claude/settings.json"
check ".claude/keybindings.json is valid JSON" jq empty "$DOTFILE/.claude/keybindings.json"
check ".claude/statusline-command.sh parses"   sh -n "$DOTFILE/.claude/statusline-command.sh"

# --------------------------------------------------------------------------
# 11. Nerd Font
# --------------------------------------------------------------------------
section "Nerd Font"
if [ "$OS" = macos ]; then
  check "font-meslo-lg-nerd-font cask installed" brew list --cask font-meslo-lg-nerd-font
  sh_check "Meslo Nerd Font files present" "ls ~/Library/Fonts /Library/Fonts 2>/dev/null | has_line -i 'MesloLGM.*NerdFont'"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  pass "WSL: fonts are installed on the Windows side (not checked)"
else
  sh_check "Meslo Nerd Font registered with fontconfig" "fc-list | has_line -i 'MesloLGM.*Nerd Font'"
  sh_check "Meslo Nerd Font Mono variant available"     "fc-list : family | has_line -i 'MesloLGM Nerd Font Mono'"
fi

# --------------------------------------------------------------------------
# 12. Neovim: tests/nvim-check.lua exercises plugins, parsers, LSP, formatting
# --------------------------------------------------------------------------
section "Neovim"
check "nvim runs" nvim --version
check "init.lua starts headless without errors" \
  nvim --headless -c 'lua if vim.v.errmsg ~= "" then io.stderr:write(vim.v.errmsg) vim.cmd("cquit 1") end' -c 'qall!'
nvim_out="$(nvim --headless -c "luafile $DOTFILE/tests/nvim-check.lua" 2>&1)"
nvim_rc=$?
printf '%s\n' "$nvim_out"
if [ "$nvim_rc" -eq 0 ]; then pass "tests/nvim-check.lua"; else fail "tests/nvim-check.lua exited $nvim_rc"; fi

# --------------------------------------------------------------------------
section "Summary: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
