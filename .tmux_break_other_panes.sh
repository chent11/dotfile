#!/bin/bash
# Get the current pane ID
current_pane=$(tmux display-message -p "#{pane_id}")

# Break all other panes into separate windows
tmux list-panes -F "#{pane_id}" | grep -v "$current_pane" | xargs -I {} tmux break-pane -d -s {}
