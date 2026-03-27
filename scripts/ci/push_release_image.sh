#!/bin/bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
    echo "用法: $0 <runtime> <image_repo> <build_tag> <date_tag>" >&2
    exit 1
fi

RUNTIME="$1"
IMAGE_REPO="$2"
BUILD_TAG="$3"
DATE_TAG="$4"
IMAGE_TAR="${RUNTIME}-image.tar"

if [[ "$RUNTIME" == "latex" ]]; then
    echo "Processing LaTeX image (AMD64 only)..."
    docker load -i "$IMAGE_TAR"
    docker tag "$IMAGE_REPO:$BUILD_TAG" "$IMAGE_REPO:latest"
    docker tag "$IMAGE_REPO:$BUILD_TAG" "$IMAGE_REPO:$DATE_TAG"
    docker push "$IMAGE_REPO:latest"
    docker push "$IMAGE_REPO:$DATE_TAG"
    exit 0
fi

echo "Processing multi-arch image for $RUNTIME..."
docker buildx build \
    --platform "linux/amd64,linux/arm64" \
    --tag "$IMAGE_REPO:latest" \
    --tag "$IMAGE_REPO:$DATE_TAG" \
    --build-arg "GITEA_VERSION=$BUILD_TAG" \
    --build-arg "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --push \
    "./runtime-${RUNTIME}"
