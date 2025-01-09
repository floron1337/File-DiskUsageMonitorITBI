#!/bin/bash

# Check if two file arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <typescript_file1> <typescript_file2>"
    exit 1
fi

typescript_file1="$1"
typescript_file2="$2"

# Function to locate the typescript file
locate_typescript_file() {
    local file="$1"
    find "$PWD" / -type f -name "$file" 2>/dev/null | head -n 1
}

typescript_path1=$(locate_typescript_file "$typescript_file1")
typescript_path2=$(locate_typescript_file "$typescript_file2")

# Check if the files were found
if [ -z "$typescript_path1" ]; then
    echo "Error: File '$typescript_file1' not found in the file system."
    exit 1
fi

if [ -z "$typescript_path2" ]; then
    echo "Error: File '$typescript_file2' not found in the file system."
    exit 1
fi

# Function to extract the last ls -l output from a typescript file
extract_last_ls_output() {
    local typescript_file="$1"
    local cleaned_file=$(mktemp)
    cat "$typescript_file" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > "$cleaned_file"
    local ls_outputs=$(awk '{if (/ls -l/) print "ls -l"; else print}' "$cleaned_file")
    local last_ls_output=""
    local current_line=1

    while IFS= read -r line; do
        if [[ "$line" == *"ls -l"* ]]; then
            last_ls_output=$(echo "$ls_outputs" | awk -v start_line="$current_line" '
            NR >= start_line && !found && /ls -l/ {found=1; print; next}
            NR >= start_line && found && /ls -l/ {exit}
            NR >= start_line && found && /@/ {exit}
            NR >= start_line && found {print}
            END {if (found) print "EOF reached"; exit}')
        fi
        ((current_line++))
    done <<< "$ls_outputs"

    rm -f "$cleaned_file"
    echo "$last_ls_output" | sed '1,2d' | sed '/EOF reached/d'
}

# Extract the last ls -l outputs from both typescript files
last_ls_output1=$(extract_last_ls_output "$typescript_path1")
last_ls_output2=$(extract_last_ls_output "$typescript_path2")

# Show the difference between the last ls -l outputs
diff_output=$(diff -u -U0 <(echo "$last_ls_output1") <(echo "$last_ls_output2"))

# Extract deleted and added files from diff output
deleted_files=$(echo "$diff_output" | grep "^-" | grep -v "^---" | awk '{print $NF}')
added_files=$(echo "$diff_output" | grep "^+" | grep -v "^+++" | awk '{print $NF}')

# Display deleted and added files in a user-friendly format
echo 
echo " --- Difference between the last ls -l in typescript files ---"
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