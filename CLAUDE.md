# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfile repository for a Linux/WSL2 environment. It contains:
- Neovim configuration (`~/.config/nvim/`) — the primary focus of active development
- Zsh configuration (`~/.zshrc`) with oh-my-zsh + Powerlevel10k
- Tmux configuration (`~/.tmux.conf`) with custom pane scripts
- SSH public keys (git submodule)
- Neovim spell files (git submodule)

## Applying Changes

This repo is maintained as a git-tracked dotfile directory. Edited files here are the source of truth — changes take effect when Neovim is restarted (or `:source %` for Lua files during a session). There is no build step.

To reload tmux config in a live session: `tmux source-file ~/.tmux.conf`

## Neovim Architecture

**Entry point:** `init.lua` — bootstraps lazy.nvim, loads core config modules, then auto-discovers all plugin specs from `lua/plugins/*.lua`.

**Config modules** (`lua/config/`):
- `options.lua` — vim options (leader key, folding, indentation, search, UI)
- `keymaps.lua` — global keymaps not tied to any plugin
- `autocmds.lua` — autocommands (commit template injection, filetype tweaks, trailing whitespace trimming)

**Plugin specs** (`lua/plugins/`):
- `lsp.lua` — nvim-cmp, nvim-lspconfig, mason, conform (formatting), nvim-lint; LSP servers: pyright, clangd, lua_ls, kotlin_lsp
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

## Tmux Prefix

Prefix is `M-e` (Alt+e), not the default `C-b`.
