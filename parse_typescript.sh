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

# Extract outputs of all commands
ls_outputs=$(awk '{if (/ls -l/) print "ls -l"; else print}' "$cleaned_file")

# get the first ls -l output block
first_output=$(echo "$ls_outputs" | awk 'BEGIN {found=0} /ls -l/ && !found {found=1; print; next} found && /ls -l/ {exit} found && /floron@/ {exit} found {print}')

# Variable to hold the output of the last ls -l command
last_ls_output=""
current_line=1

# Read the variable line by line
while IFS= read -r line; do
    # Check if the line contains an ls -l command
    if [[ "$line" == *"ls -l"* ]]; then
        last_ls_output=$(echo "$ls_outputs" | awk -v start_line="$current_line" '
        NR >= start_line && !found && /ls -l/ {found=1; print; next}
        NR >= start_line && found && /ls -l/ {exit}
        NR >= start_line && found && /floron@/ {exit}
        NR >= start_line && found {print}
        END {if (found) print "EOF reached"; exit}')
    fi
    # Increment the line number
    ((current_line++))
done <<< "$ls_outputs"

# Clean up temporary file
rm -f "$cleaned_file"

# Remove the first two lines from the outputs
first_output=$(echo "$first_output" | sed '1,2d')
last_ls_output=$(echo "$last_ls_output" | sed '1,2d')

# Remove the "EOF reached" message from last_ls_output if it exists
last_ls_output=$(echo "$last_ls_output" | sed '/EOF reached/d')

# Storing the difference between first and last ls -l outputs
diff_output=$(diff -u <(echo "$first_output") <(echo "$last_ls_output"))

# display first ls -l output
echo "First ls -l output:"
echo "$first_output"
echo

# display last ls -l output
echo "Last ls -l output:"
echo "$last_ls_output"
echo

# Display the diff output
echo "Diff output between first and last ls -l outputs:"
echo "$diff_output"



