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
    local json_subdirs="[]"

    # Process all subdirectories
    if [ "$depth" -lt "$MAX_DEPTH" ]; then
        local json_subdir_array=""
        for subdir in "${subdirs[@]}"; do
            local subdir_result=$(count_images "$subdir" $((depth + 1)) "$prefix   ")
            local subdir_image_count=$(echo "$subdir_result" | tail -n 1 | cut -d' ' -f1)
            local subdir_json=$(echo "$subdir_result" | tail -n 1 | cut -d' ' -f2-)
            total_subdir_count=$((total_subdir_count + subdir_image_count))
            subdir_counts+=" + $subdir_image_count"
            json_subdir_array+="$subdir_json,"
        done
        json_subdirs="[${json_subdir_array%,}]"

        # Display only first 10 subdirectories
        if [ "$subdir_count" -gt 10 ]; then
            printf "${RED}%s   (showing 10 out of %d subdirectories)${NC}\n" "$prefix" "$subdir_count"
            for i in "${!subdirs[@]}"; do
                if [ "$i" -lt 10 ]; then
                    count_images "${subdirs[$i]}" $((depth + 1)) "$prefix   " | sed '$d'
                else
                    break
                fi
            done
        else
            for subdir in "${subdirs[@]}"; do
                count_images "$subdir" $((depth + 1)) "$prefix   " | sed '$d'
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

    # Create JSON object
    local json_object=$(printf '{"name":"%s","current":%d,"total":%d,"subdirs":%s}' "$(basename "$dir")" "$current_dir_count" "$total_count" "$json_subdirs")

    # Return the total count for parent directories and JSON object
    echo "$total_count $json_object"
}

# Start counting from the root directory and capture the result
result=$(count_images "$directory" 0 "")

# Extract the JSON object from the result
json_result=$(echo "$result" | tail -n 1 | cut -d' ' -f2-)

other_results=$(echo "$result" | sed '$d')

echo "$other_results"

# Generate JSON file name
json_file="$(basename "$directory")_counts.json"

# Save JSON to file
echo "$json_result" > "$json_file"
echo "Image count results saved to $json_file"