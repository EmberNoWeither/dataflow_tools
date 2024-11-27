#!/bin/bash

# Default max depth
MAX_DEPTH=5

# Check if directory path is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 directory_path [max_depth]"
    exit 1
fi

directory="$1"

# Check if max depth is provided
if [ $# -eq 2 ]; then
    MAX_DEPTH=$2
fi

# Check if the directory exists
if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' does not exist."
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to count images in a directory
count_images() {
    local dir="$1"
    local depth="$2"
    local prefix="$3"

    local subdirs=($(find "$dir" -maxdepth 1 -mindepth 1 -type d | sort))
    local subdir_count=${#subdirs[@]}
    local total_subdir_count=0
    local subdir_counts=""

    # Process all subdirectories
    if [ "$depth" -lt "$MAX_DEPTH" ]; then
        for subdir in "${subdirs[@]}"; do
            local subdir_result=$(count_images "$subdir" $((depth + 1)) "$prefix   ")
            local subdir_image_count=$(echo "$subdir_result" | tail -n 1)
            total_subdir_count=$((total_subdir_count + subdir_image_count))
            subdir_counts+=" + $subdir_image_count"
        done

        # Display only first 10 subdirectories
        if [ "$subdir_count" -gt 10 ]; then
            printf "${RED}%s   (showing 10 out of %d subdirectories)${NC}\n" "$prefix" "$subdir_count"
            for i in "${!subdirs[@]}"; do
                if [ "$i" -lt 10 ]; then
                    count_images "${subdirs[$i]}" $((depth + 1)) "$prefix   " | head -n -1
                else
                    break
                fi
            done
        else
            for subdir in "${subdirs[@]}"; do
                count_images "$subdir" $((depth + 1)) "$prefix   " | head -n -1
            done
        fi
    fi

    # Count images in current directory (excluding subdirectories)
    local current_dir_count=$(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.tif" -o -iname "*.webp" \) | wc -l)

    # Print current directory without count
    printf "${GREEN}%s%s ${BLUE}(calculating...)${NC}\n" "$prefix" "$(basename "$dir")"

    # Print the sum formula
    local total_count=$((current_dir_count + total_subdir_count))
    printf "${BLUE}%s   Sum: %d = %d%s${NC}\n" "$prefix" "$total_count" "$current_dir_count" "$subdir_counts"

    # Return the total count for parent directories
    echo $total_count
}

# Start counting from the root directory
count_images "$directory" 0 ""