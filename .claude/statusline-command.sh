#!/bin/sh
# Claude Code status line - mirrors Powerlevel10k lean prompt style
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
if [ -n "$cwd" ]; then
  home="$HOME"
  case "$cwd" in
    "$home"*) cwd="~${cwd#$home}" ;;
  esac
fi

# Build status parts
parts=""

# Directory
if [ -n "$cwd" ]; then
  parts="$cwd"
fi

# Git repo / worktree
if [ -n "$repo" ]; then
  git_info="$repo"
  if [ -n "$git_worktree" ]; then
    git_info="$git_info [$git_worktree]"
  fi
  parts="$parts  $git_info"
elif [ -n "$git_worktree" ]; then
  parts="$parts  [$git_worktree]"
fi

# Model
if [ -n "$model" ]; then
  parts="$parts  $model"
fi

# Context usage
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  parts="$parts  ctx:${used_int}%"
fi

printf '%s' "$parts"
