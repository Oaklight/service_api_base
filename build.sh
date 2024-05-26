#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Define the configuration file path
CONFIG_FILE="config.yaml"

# Source the parse.sh script to read configuration from config.yaml
source ./parse.sh

# Define the base Dockerfile path
DOCKERFILE_TEMPLATE="$DOCKERFILE_TEMPLATE"

# Define the output directory for Dockerfiles
OUTPUT_DIR="$OUTPUT_DIR"

# Define the base images and corresponding tags
BASE_IMAGES=("${BASE_IMAGES[@]}")
TAG_SUFFIXES=("${TAG_SUFFIXES[@]}")

# Define the tag prefix
TAG_PREFIX="$TAG_PREFIX"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to create a Dockerfile for a specific base image
create_dockerfile() {
    local base_image=$1
    local tag_suffix=$2
    local tag="$TAG_PREFIX:$tag_suffix"

    # Ensure the Dockerfile template exists
    if [[ ! -f "$DOCKERFILE_TEMPLATE" ]]; then
        echo "Dockerfile template does not exist."
        exit 1
    fi

    # Create a new Dockerfile with the specified base image
    # Use 'cat' to redirect the template content into a new file
    cat "$DOCKERFILE_TEMPLATE" | sed "s|FROM python:3.11-slim|FROM $base_image|g" >"$OUTPUT_DIR/Dockerfile"

    if [[ $? -ne 0 ]]; then
        echo "Failed to create Dockerfile for $base_image."
        exit 1
    fi

    echo "Created Dockerfile for $base_image with tag $tag"
}

# Function to build a Docker image
build_image() {
    local dockerfile_path="$OUTPUT_DIR/Dockerfile"
    local tag=$1

    # Build the Docker image
    docker build -f "$dockerfile_path" -t "$tag" .

    if [[ $? -ne 0 ]]; then
        echo "Docker build failed for $tag."
        exit 1
    fi

    echo "Built image with tag $tag"
}

# Function to push a Docker image to the registry
push_image() {
    local tag=$1

    # Push the Docker image
    docker push "$tag"

    if [[ $? -ne 0 ]]; then
        echo "Docker push failed for $tag."
        exit 1
    fi

    echo "Pushed image with tag $tag"
}

# Function to clean up after build and push
clean_up() {
    # Remove Dockerfiles
    rm -rf "$OUTPUT_DIR"

    # Remove intermediate images created during the build
    docker rmi $(docker images -q --filter "reference=$TAG_PREFIX:*") -f

    # Remove build cache
    docker builder prune -f
}

# Default to cleaning up
CLEAN_UP=true

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --no-clean)
        CLEAN_UP=false
        shift # Remove --no-clean from processing
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

# Main script execution
{
    # Loop over base images and their corresponding tags
    for i in "${!BASE_IMAGES[@]}"; do
        create_dockerfile "${BASE_IMAGES[$i]}" "${TAG_SUFFIXES[$i]}"
        build_image "$TAG_PREFIX:${TAG_SUFFIXES[$i]}"
    done

    # Tag additional versions and push
    for tag_suffix in "${TAG_SUFFIXES[@]}"; do
        tag="$TAG_PREFIX:$tag_suffix"
        short_tag="$TAG_PREFIX:${tag_suffix##*-}" # Tag without version
        docker tag "$tag" "$short_tag"
        push_image "$tag"
    done

    # Push the 'latest' tag
    docker tag "$TAG_PREFIX:${TAG_SUFFIXES[-1]##*-}" "$TAG_PREFIX:latest"
    push_image "$TAG_PREFIX:latest"

    # Clean up after build and push if --no-clean is not specified
    if $CLEAN_UP; then
        clean_up
    fi

} || {
    echo "An error occurred."
    exit 1
}

echo "All images have been built, tagged, and pushed successfully."
