#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Define the base Dockerfile path
DOCKERFILE_TEMPLATE="Dockerfile.template"

# Define the output directory for Dockerfiles
OUTPUT_DIR="./dockerfiles"

# Define the base images and corresponding tags
BASE_IMAGES=(
    "python:3.11-alpine"
    "python:3.11-slim"
)

TAG_PREFIX="oaklight/service_api_base"
TAG_SUFFIXES=(
    "3.11-alpine"
    "3.11-slim"
    "alpine"
    "slim"
    "latest"
)

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

# Main script execution
{
    # Create and build Dockerfiles for each base image and tag suffix
    for base_image in "${BASE_IMAGES[@]}"; do
        for tag_suffix in "${TAG_SUFFIXES[@]}"; do
            create_dockerfile "$base_image" "$tag_suffix"
            build_image "$TAG_PREFIX:$tag_suffix"
        done
    done

    # Tag additional versions and push
    docker tag "$TAG_PREFIX:3.11-alpine" "$TAG_PREFIX:alpine"
    docker tag "$TAG_PREFIX:3.11-alpine" "$TAG_PREFIX:latest"
    docker tag "$TAG_PREFIX:3.11-slim" "$TAG_PREFIX:slim"

    # Push all images
    for tag_suffix in "${TAG_SUFFIXES[@]}"; do
        push_image "$TAG_PREFIX:$tag_suffix"
    done

    # Clean up after build and push
    clean_up

} || {
    echo "An error occurred."
    exit 1
}

echo "All images have been built, tagged, and pushed successfully."
