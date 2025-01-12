#!/bin/bash

# Step 1: Extract workflow information and save to .json
find . -type f -iname "*.png" -exec bash -c '
    workflow=$(exiftool -s -Workflow "$1" | sed "s/Workflow\s*:\s*//")
    if [ -n "$workflow" ]; then
        echo "$workflow" > "${1%.png}.json"
        echo "Saved workflow to ${1%.png}.json"
    else
        echo "No workflow found in $1"
    fi
' bash {} \;

# Step 2: Delete all files except .json and .md files, and echo the deleted files
find . -type f ! \( -iname "*.json" -o -iname "*.md" \) -exec bash -c '
    echo "Removing file: $1"
    rm -f "$1"
' bash {} \;
