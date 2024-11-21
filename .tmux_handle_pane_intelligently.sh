#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 <mode> [window_index]"
  echo "  mode: Specify 'join' to join an existing pane, or 'split' to split the current pane."
  echo "  window_index: The index of the window to operate on (required for 'join' mode only)."
  exit 1
}

# Check if mode was provided
if [ -z "$1" ]; then
  echo "Error: Mode not specified."
  usage
fi

# Assign the mode and window index variables
mode="$1"

# Get the dimensions of the current pane
total_width=$(tmux display-message -p "#{pane_width}")
total_height=$(tmux display-message -p "#{pane_height}")
total_height=$((total_height * 2 + 5))

# Decide the split direction
if [ "$total_width" -gt "$total_height" ]; then
  split_direction="h"
else
  split_direction="v"
fi

# Execute the appropriate command based on mode and chosen direction
if [ "$mode" == "join" ]; then
  # Check if window_index was provided
  if [ -z "$2" ]; then
    echo "Error: window_index is required for 'join' mode."
    usage
  fi

  window_index="$2"

  # Validate if the provided window index exists
  if ! tmux list-windows | grep -q "^$window_index:"; then
    echo "Error: Window index $window_index does not exist."
    exit 1
  fi

  # Join pane in the chosen direction
  tmux join-pane -$split_direction -s "$window_index"
elif [ "$mode" == "split" ]; then
  tmux split-window -$split_direction -c "#{pane_current_path}"
else
  echo "Error: Invalid mode specified. Use 'join' or 'split'."
  usage
fi

# Exit successfully
exit 0
