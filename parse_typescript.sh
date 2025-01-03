#!/bin/bash

# Check if a file argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <typescript_file>"
    exit 1
fi

typescript_file="$1"

# Check if the file exists
if [ ! -f "$typescript_file" ]; then
    echo "Error: File '$typescript_file' not found."
    exit 1
fi

# Clean the file to remove escape sequences and terminal artifacts
cleaned_file=$(mktemp)
cat "$typescript_file" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > "$cleaned_file"

# Extract outputs of all `ls -l` commands
ls_outputs=$(awk '/ls -l/{flag=1; next} flag && /^[^$]/ {print; next} /^[[:space:]]*$/ {flag=0}' "$cleaned_file")

# Get the first and last `ls -l` outputs
parsed_output=$(echo "$ls_outputs" | awk 'NR==1,/^$/')

# Clean up temporary file
rm -f "$cleaned_file"

echo "$parsed_output"