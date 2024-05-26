#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Define the configuration file path
CONFIG_FILE="config.yaml"

# Function to run yq inside a Docker container
docker_yq() {
    docker run --rm -i -v "${PWD}":/workdir mikefarah/yq:latest "$@"
}

# Function to run yq natively
native_yq() {
    yq "$@"
}

# Check if yq is installed natively
if command -v yq &>/dev/null; then
    YQ_CMD=native_yq
else
    YQ_CMD=docker_yq
fi

# Read configuration from config.yaml
OUTPUT_DIR=$($YQ_CMD e '.output_dir' "$CONFIG_FILE")
DOCKERFILE_TEMPLATE=$($YQ_CMD e '.dockerfile_template' "$CONFIG_FILE")
TAG_PREFIX=$($YQ_CMD e '.tag_prefix' "$CONFIG_FILE")
TAG_LATEST=$($YQ_CMD e '.tag_latest' "$CONFIG_FILE")

# Read base images and corresponding tag suffixes from config.yaml
BASE_IMAGES=()
TAG_SUFFIXES=()
while IFS= read -r base_image; do
    BASE_IMAGES+=("$base_image")
done < <($YQ_CMD e '.base_images[].base_image' "$CONFIG_FILE")
while IFS= read -r tag_suffix; do
    TAG_SUFFIXES+=("$tag_suffix")
done < <($YQ_CMD e '.base_images[].tag_suffix' "$CONFIG_FILE")

# Print out the variables for debugging
echo "Output Directory: $OUTPUT_DIR"
echo "Dockerfile Template: $DOCKERFILE_TEMPLATE"
echo "Tag Prefix: $TAG_PREFIX"
echo "Tag Latest: $TAG_LATEST"
echo "Base Images: ${BASE_IMAGES[*]}"
echo "Tag Suffixes: ${TAG_SUFFIXES[*]}"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Rest of the script remains the same...
