# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfile repository for Linux/WSL2 and macOS. It contains:
- Neovim configuration (`~/.config/nvim/`) — the primary focus of active development
- Zsh configuration (`~/.zshrc`) with oh-my-zsh + Powerlevel10k (prompt layout in `.p10k.zsh`), fzf, atuin (history; `.config/atuin/config.toml`), zoxide (cd)
- Tmux configuration (`~/.tmux.conf`) with custom pane scripts
- Zellij configuration (`~/.config/zellij/config.kdl`). The `compact` layout's bar is [chent11/zellij-compact-bar](https://github.com/chent11/zellij-compact-bar), zellij's own compact-bar with tab numbers prefixed (`3:name`); the `compact-bar` alias in `config.kdl` points at a release asset of that repo and zellij downloads it. A URL plugin must be granted permissions and a one-row bar cannot show the prompt, so `bootstrap.sh` writes the grant into zellij's permission cache. When the zellij pin in the mise config moves, cut a matching release there and bump the URL here.
- mise tool list (`~/.config/mise/config.toml`) — the single source of truth for user-level tools (neovim, node, tmux, zellij, fzf, tree-sitter, uv, atuin, zoxide, delta, linters)
- lazygit configuration (`~/.config/lazygit/config.yml`) — OSC 52 clipboard, delta pager
- Global gitignore (`~/.config/git/ignore`) — `.DS_Store` and Claude Code per-machine files
- SSH public keys (git submodule)
- Neovim spell files (git submodule)

## Fresh Machine Setup

`./bootstrap.sh` provisions a new Ubuntu/Debian or macOS machine: system packages (apt or Homebrew), symlinks into `$HOME`, oh-my-zsh + plugins, mise + `mise install` (every tool in `.config/mise/config.toml`, including Neovim and node), rustup, then `bin/nvim-bootstrap.lua` headlessly installs plugins, parsers and Mason packages from `lua/config/tools.lua`, then pre-grants zellij permissions to the compact-bar plugin, then the Meslo Nerd Font (Homebrew cask on macOS, `~/.local/share/fonts` on Linux, skipped with a hint on WSL), then git settings including git-lfs. On a terminal it always asks for git `user.name`/`user.email`, offering the current values as defaults; without a terminal it keeps whatever is set. It is idempotent, bash 3.2 compatible, and backs up anything it replaces to `~/.dotfile-backup/`.

Tools are added with `mise use -g <tool>`, which edits the tracked config through the `~/.config/mise/config.toml` symlink; never hand-install into `~/.local/bin` or `/usr/bin` what mise can provide. `mise upgrade` updates everything pinned to `latest`.

Tools that lack a macOS build upstream (currently only btop) carry `os = ["linux"]` in the mise config and are added to the `brew install` list in `bootstrap.sh` instead; mise skips them on macOS rather than failing.

Platform-conditional bits live in the config files themselves, not the script: `.zshrc` guards Homebrew, mise, cargo and `/etc/zsh_command_not_found`; `.tmux.conf` picks `pbcopy` or `xclip` with `if-shell`.

## Verifying the Setup

`tests/check.sh` checks a provisioned machine end to end: symlinks (parsed from the `link` lines in `bootstrap.sh`), system packages, every tool in the mise config (resolved through a shim and exercised, not just `--version`), an interactive zsh started under a pty (theme, plugins, atuin/fzf/zoxide/mise hooks, aliases), tmux and zellij config loading, git settings, SSH keys and the `.claude/` files. It runs `tests/nvim-check.lua` headlessly, which asserts every lazy.nvim plugin, treesitter parser and Mason package from `lua/config/tools.lua`, makes pyright/clangd/lua_ls attach and report diagnostics, formats with conform, lints with nvim-lint, and verifies the autocmds (commit template, whitespace trim, indent, jsonc). Both are bash 3.2 / stock Neovim and need no sudo; run them after changing anything the bootstrap touches. When a mise tool is added, `check.sh` fails until its binary name is known to `bin_for()`.

`.github/workflows/bootstrap.yml` runs `bootstrap.sh` twice (the second run must change nothing) and then `tests/check.sh` on stock `ubuntu:24.04` and `ubuntu:26.04` containers and on `macos-latest`, on push, PR, weekly and on demand. It needs the `SUBMODULE_TOKEN` repository secret: a fine-grained PAT with read-only Contents on the private submodules `chent11/ssh_pub_keys` and `chent11/vim_spell`.

## Applying Changes

This repo is maintained as a git-tracked dotfile directory. Edited files here are the source of truth — changes take effect when Neovim is restarted (or `:source %` for Lua files during a session). There is no build step.

To reload tmux config in a live session: `tmux source-file ~/.tmux.conf`

## Neovim Architecture

**Entry point:** `init.lua` — bootstraps lazy.nvim, loads core config modules, then auto-discovers all plugin specs from `lua/plugins/*.lua`.

**Config modules** (`lua/config/`):
- `options.lua` — vim options (leader key, folding, indentation, search, UI)
- `keymaps.lua` — global keymaps not tied to any plugin
- `autocmds.lua` — autocommands (commit template injection, filetype tweaks, trailing whitespace trimming)
- `tools.lua` — the lists of LSP servers, Mason tools and treesitter parsers; the single source of truth read by `lsp.lua`, `treesitter.lua` and `bin/nvim-bootstrap.lua`

**Plugin specs** (`lua/plugins/`):
- `lsp.lua` — nvim-cmp, nvim-lspconfig, mason, conform (formatting), nvim-lint; LSP servers: pyright, clangd, lua_ls
- `editor.lua` — flash.nvim, aerial.nvim, undotree, lualine, Comment.nvim, highlight-undo
- `git.lua` — vim-fugitive, gitsigns
- `snacks.lua` — snacks.nvim (picker, explorer, indent guides, terminal, zen, scratch); picker uses `fd` + `rg` for files/grep
- `ai.lua` — `coder/claudecode.nvim` Claude Code integration (snacks terminal provider; `<leader>a*` and `<A-h>` keymaps)
- `treesitter.lua` — uses a fork (`chent11/nvim-treesitter`, branch `spell-checking-for-string`) instead of upstream
- `colorscheme.lua` — gruvbox (active), plus lazy-loaded alternatives

**Key design decisions:**
- Mason installs servers/tools but `automatic_enable = false` — servers are explicitly enabled via `vim.lsp.enable(servers)`
- Treesitter uses a personal fork to add spell-checking inside strings
- snacks picker respects both `.gitignore` and `.fdignore` for file search and live grep (each source passes `--ignore-file` explicitly)
- snacks.nvim picker: each source (`grep`, `grep_word`, `files`, …) is configured independently under `opts.picker.sources`; settings do not inherit across sources

## Keymap Placement Convention

- `lua/config/keymaps.lua` — Neovim built-in mappings and global mappings that have no plugin dependency (motion tweaks, register ops, window nav, etc.)
- `lua/plugins/<plugin>.lua` — any keymap that calls a plugin command or function goes in the plugin's own spec file, inside its `keys = { … }` table

Never add plugin-dependent keymaps to `keymaps.lua`.

## Indentation Conventions

Default: 4-space indent. Overridden to 2-space for: `vim`, `html`, `css`, `json`, `javascript`, `typescript`, `lua`, `sh`, `zsh` (set in `autocmds.lua`).

Note: `vim-sleuth` (in `lsp.lua`) auto-detects and may override these defaults based on existing file content.

## Commit Message Convention

Commits follow Conventional Commits: `fix:`, `feat:`, `refactor:`, `chore:`, `docs:`, `test:`. Opening a `COMMIT_EDITMSG` buffer automatically injects the staged diff and these guidelines as comments (via `autocmds.lua`). Subject line limit: 50 chars; body: 72 chars.

## Multiplexer Prefix

Both tmux and zellij use `Ctrl+;` as the prefix, not the default `C-b`. The zellij bar numbers its tabs (`1:`, `2:`, …) to match `prefix+1..9`; it is zellij's compact-bar (fork: chent11/zellij-compact-bar), which collapses tabs that do not fit into `← +N` / `+N →` markers, so the bar never overflows the row. Shell tab titles are the path capped at 35 characters (`ZSH_THEME_TERM_TITLE_IDLE` in `.zshrc`). Tmux keeps `M-e` (Alt+e) as `prefix2` for terminals that cannot send Ctrl+;. Ctrl+; needs extended key reporting from the terminal: zellij uses the kitty keyboard protocol (Windows Terminal 1.25+, Ghostty, WezTerm, kitty, iTerm2 3.5+), tmux asks for xterm modifyOtherKeys (Ghostty, WezTerm, kitty, iTerm2; Windows Terminal needs a `sendInput` binding for `\u001b[59;5u`).
