#!/bin/bash

# Check if required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <source_directory> <sample_size> <output_folder_name>"
    exit 1
fi

source_dir="$1"
sample_size="$2"
output_folder_name="$3"

# Generate JSON file name
json_file="$(basename "$source_dir")_counts.json"

# Check if JSON file exists, if not, generate it
if [ ! -f "$json_file" ]; then
    echo "JSON file not found. Generating..."
    chmod +x ./count_images_v2.sh
    ./count_images_v2.sh "$source_dir"
    if [ ! -f "$json_file" ]; then
        echo "Failed to generate JSON file. Exiting."
        exit 1
    fi
fi

# Function to parse JSON and sample images
sample_images() {
    local json="$1"
    local dir="$2"
    local output_dir="$3"
    
    local name=$(echo "$json" | jq -r '.name')
    local current=$(echo "$json" | jq -r '.current')
    local total=$(echo "$json" | jq -r '.total')
    
    local current_dir="$dir"
    local output_subdir="$output_dir/${name}_samples"
    mkdir -p "$output_subdir"

    # Sample images from current directory
    local sample_count=$(echo "scale=0; $current * $sample_size / $total_images" | bc)
    if [ "$sample_count" -gt 0 ]; then
        echo "Sampling from $current_dir"
        find "$current_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.tif" -o -iname "*.webp" \) | shuf -n "$sample_count" | xargs -I {} cp {} "$output_subdir/"
        echo "Sampled $sample_count images from $current_dir"
    fi

    # Process subdirectories
    echo "$json" | jq -c '.subdirs[]' | while read -r subdir; do
        local subdir_name=$(echo "$subdir" | jq -r '.name')
        sample_images "$subdir" "$current_dir/$subdir_name" "$output_subdir"
    done
}

# Create output directory
output_dir="./${output_folder_name}_samples"
mkdir -p "$output_dir"

# Read JSON file and start sampling
json_content=$(cat "$json_file")
total_images=$(echo "$json_content" | jq -r '.total')

echo "Total images: $total_images"
echo "Sample size: $sample_size"
echo "Sampling ratio: $(echo "scale=4; $sample_size / $total_images" | bc)"

sample_images "$json_content" "$source_dir" "$output_dir"

echo "Sampling complete. Results are in $output_dir"