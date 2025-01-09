#!/bin/bash

# Ensure a file argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file_to_track>"
    exit 1
fi

file_to_track="$1"

# Check if the file exists
if [ ! -f "$file_to_track" ]; then
    echo "Error: File '$file_to_track' not found."
    exit 1
fi

# Create a directory to store history if it doesn't exist
history_dir="$HOME/.file_history"
mkdir -p "$history_dir"

# Generate a unique history file path for the tracked file
tracked_file_hash=$(echo "$file_to_track" | sha256sum | cut -d' ' -f1)
history_file="$history_dir/${tracked_file_hash}.history"

# If no history exists, save the initial version
if [ ! -f "$history_file" ]; then
    cp "$file_to_track" "$history_file"
    echo "Tracking started for '$file_to_track'. Initial snapshot saved."
    exit 0
fi

# Compare the current file with the last saved snapshot (word-level changes highlighted)
diff_output=$(wdiff "$history_file" "$file_to_track")

# If no differences, notify the user
if [ -z "$diff_output" ]; then
    echo "No changes detected in '$file_to_track'."
    exit 0
fi

# Show the differences with inline changes highlighted
echo "Changes detected in '$file_to_track':"
echo
echo "$diff_output"

# Ask the user if they want to save the current version as the latest snapshot
read -p "Save current version as the latest snapshot? (y/n): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
    cp "$file_to_track" "$history_file"
    echo "Snapshot updated for '$file_to_track'."
else
    echo "Snapshot not updated."
fi
