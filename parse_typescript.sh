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
# ls_outputs=$(awk '/ls -l/{flag=1; next} flag && /^[^$]/ {print; next} /^[[:space:]]*$/ {flag=0}' "$cleaned_file")
# ls_outputs=$(awk '/ls -l/ {flag=1; print; next} flag && /^[^$]/ {print; next} /^[[:space:]]*$/ {flag=0}' "$cleaned_file")
ls_outputs=$(awk '{if (/ls -l/) print "ls -l"; else print}' "$cleaned_file")
# Get the first and last `ls -l` outputs
# parsed_output=$(echo "$ls_outputs" | awk 'NR==1,/^$/')

# Get the first `ls -l` output block
# first_output=$(echo "$ls_outputs" | awk '/ls -l/,/ls -l/')
# first_output=$(echo "$ls_outputs" | awk '/ls -l/ {found=1} found && /floron@/ {exit} found {print}')
# first_output=$(echo "$ls_outputs" | awk '/ls -l/ {found=1} found && /floron@/ {exit} found && /ls -l/ {exit} found {print}')
first_output=$(echo "$ls_outputs" | awk 'BEGIN {found=0} /ls -l/ && !found {found=1; print; next} found && /ls -l/ {exit} found && /floron@/ {exit} found {print}')

# Clean up temporary file
rm -f "$cleaned_file"

echo "First ls -l output:"
echo "$first_output"
# echo "$parsed_output"