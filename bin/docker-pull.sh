#!/bin/bash

# === CONFIGURATION ===
REGISTRY_HOST="${REGISTRY_HOST:-docker-proxy.local:5000}"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <image[:tag]>"
  echo "Example: $0 nginx:alpine"
  exit 1
fi

# Split into name and tag
IMAGE_INPUT="$1"
IMAGE_NAME=$(echo "$IMAGE_INPUT" | cut -d: -f1)
IMAGE_TAG=$(echo "$IMAGE_INPUT" | cut -s -d: -f2)

# Default tag to "latest" if missing
if [[ -z "$IMAGE_TAG" ]]; then
  IMAGE_TAG="latest"
fi

# Detect official images with no namespace
if [[ "$IMAGE_NAME" != */* ]]; then
  IMAGE_PATH="library/$IMAGE_NAME"
else
  IMAGE_PATH="$IMAGE_NAME"
fi

PROXY_IMAGE="$REGISTRY_HOST/$IMAGE_PATH:$IMAGE_TAG"
FINAL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"

echo "📥 Pulling from proxy: $PROXY_IMAGE"
docker pull "$PROXY_IMAGE" || { echo "❌ Failed to pull image"; exit 1; }

echo "🏷️ Retagging to: $FINAL_IMAGE"
docker tag "$PROXY_IMAGE" "$FINAL_IMAGE"

echo "✅ Done! You can now use image '$FINAL_IMAGE'."
