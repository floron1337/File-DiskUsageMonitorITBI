#!/bin/bash

# Check if a file argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <typescript_file>"
    exit 1
fi

typescript_file="$1"

# Attempt to locate the typescript file
typescript_path=$(find "$PWD" / -type f -name "$typescript_file" 2>/dev/null | head -n 1)

# Check if the file was found
if [ -z "$typescript_path" ]; then
    echo "Error: File '$typescript_file' not found in the file system."
    exit 1
fi

# Clean the file to remove escape sequences and terminal artifacts
cleaned_file=$(mktemp)
cat "$typescript_path" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > "$cleaned_file"

# Extract outputs of all commands
ls_outputs=$(awk '{if (/ls -l/) print "ls -l"; else print}' "$cleaned_file")

# get the first ls -l output block
first_output=$(echo "$ls_outputs" | awk 'BEGIN {found=0} /ls -l/ && !found {found=1; print; next} found && /ls -l/ {exit} found && /@/ {exit} found {print}')

# Variable to hold the output of the last ls -l command
last_ls_output=""
current_line=1

# Read the variable line by line
while IFS= read -r line; do
    # Check if the line contains an ls -l command
    if [[ "$line" == "ls -l" ]]; then
        last_ls_output=$(echo "$ls_outputs" | awk -v start_line="$current_line" '
        NR >= start_line && !found && /ls -l/ {found=1; print; next}
        NR >= start_line && found && /ls -l/ {exit}
        NR >= start_line && found && /@/ {exit}
        NR >= start_line && found {print}
        END {if (found) print "EOF reached"; exit}')
    fi
    # Increment the line number
    ((current_line++))
done <<< "$ls_outputs"

# Extract outputs of the 'df' command from the typescript file
df_outputs=$(awk '{if (/df/) print "df"; else print}' "$cleaned_file")

# Get the first 'df' output block
first_df_output=$(echo "$df_outputs" | awk 'BEGIN {found=0} /df/ && !found {found=1; print; next} found && /df/ {exit} found && /@/ {exit} found {print}')

# Get the last 'df' output block
last_df_output=$(echo "$df_outputs" | awk 'BEGIN {found=0} /df/ {found=1; next} found && /df/ {last=$0; next} found {last=$0} END {print last}')

# Remove the first line headers from the outputs
first_df_output=$(echo "$first_df_output" | sed '1d')
last_df_output=$(echo "$last_df_output" | sed '1d')

# Store the difference between first and last 'df' outputs
df_diff_output=$(diff -u -U0 <(echo "$first_df_output") <(echo "$last_df_output"))

# Clean up temporary file
rm -f "$cleaned_file"

# Remove the first two lines from the outputs
first_output=$(echo "$first_output" | sed '1,2d')
last_ls_output=$(echo "$last_ls_output" | sed '1,2d')


# Remove the "EOF reached" message from last_ls_output if it exists
last_ls_output=$(echo "$last_ls_output" | sed '/EOF reached/d')

# get the folder that holds the typescript file
typescript_dir=$(dirname "$(realpath "$typescript_path")")

# get the current "ls -l" output in that folder
current_ls_output=$(ls -l "$typescript_dir")

# delete first line of current "ls -l" output
current_ls_output=$(echo "$current_ls_output" | sed '1d')

# Storing the difference between first and last ls -l outputs
diff_output=$(diff -u -U0 <(echo "$first_output") <(echo "$last_ls_output"))

# Store de difference between last  ls -l output in the typescript file and the current ls -l output
diff_output_last_current=$(diff -u -U0 <(echo "$last_ls_output") <(echo "$current_ls_output"))

# explaining what this script does
echo " --------------------------------------------- "
echo
echo " This script analyses the evolution of the file structure by comparing "
echo " the first and last ls -l output within a given typescript file "
echo
echo " --------------------------------------------- "

# Extract deleted and added files from diff output
deleted_files=$(echo "$diff_output" | grep "^-" | grep -v "^---" | awk '{print $NF}')
added_files=$(echo "$diff_output" | grep "^+" | grep -v "^+++" | awk '{print $NF}')

# Display deleted and added files in a user-friendly format
echo 
echo " --- Difference between first and last ls -l output in this typescript file ---"
echo
echo "Deleted files:"
if [ -z "$deleted_files" ]; then
    echo "No deleted files."
else
    echo "$deleted_files"
fi

echo

echo "Added files:"
if [ -z "$added_files" ]; then
    echo "No added files."
else
    echo "$added_files"
fi

echo 


# Display changes in disk usage
echo
echo " --------------------------------------------- "
echo " Disk Usage Analysis"
echo " --------------------------------------------- "


df_diff_output=$(echo "$df_diff_output" | grep -v "^---")


if [ -z "$df_diff_output" ]; then
    echo "No changes in disk usage detected."
else
    echo "Differences in disk usage:"
    echo "$df_diff_output" | grep -E '^[-+]' | grep -v '^+++' | awk '{print $0}'
fi

echo 
echo


echo " --- Difference between the last ls -l command in this typescript file ---"
echo " --- and the current ls -l command ---"
echo

deleted_files2=$(echo "$diff_output_last_current" | grep "^-" | grep -v "^---" | awk '{print $NF}')

added_files2=$(echo "$diff_output_last_current" | grep "^+" | grep -v "^+++" | awk '{print $NF}')

echo "Deleted files:"
echo
if [ -z "$deleted_files2" ]; then
    echo "No deleted files."
else
    echo "$deleted_files2"
fi

echo

echo "Added files:"
echo
if [ -z "$added_files2" ]; then
    echo "No added files."
else
    echo "$added_files2"
fi
