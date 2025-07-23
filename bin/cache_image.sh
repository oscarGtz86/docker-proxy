#!/bin/bash

# === CONFIGURATION ===
REGISTRY_HOST="${REGISTRY_HOST:-docker-proxy.local:5000}"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <image[:tag]>"
  echo "Example: $0 nginx:alpine"
  echo "Example: $0 ubuntu  # defaults to :latest"
  exit 1
fi

# Split image and tag
IMAGE_INPUT="$1"
IMAGE_NAME=$(echo "$IMAGE_INPUT" | cut -d: -f1)
IMAGE_TAG=$(echo "$IMAGE_INPUT" | cut -s -d: -f2)

if [[ -z "$IMAGE_TAG" ]]; then
  IMAGE_TAG="latest"
fi

FULL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"

# Handle official images (no namespace) - add library/ prefix for registry
if [[ "$IMAGE_NAME" != */* ]]; then
  REGISTRY_IMAGE="$REGISTRY_HOST/library/$IMAGE_NAME:$IMAGE_TAG"
else
  REGISTRY_IMAGE="$REGISTRY_HOST/$IMAGE_NAME:$IMAGE_TAG"
fi

echo "🐳 Docker Image Caching Workflow"
echo "================================="
echo "Source Image: $FULL_IMAGE"
echo "Registry Image: $REGISTRY_IMAGE"
echo ""

echo "📥 Step 1/3: Pulling image from Docker Hub..."
docker pull "$FULL_IMAGE" || { 
  echo "❌ Failed to pull image from Docker Hub"
  exit 1
}

echo "🏷️ Step 2/3: Tagging image for local registry..."
docker tag "$FULL_IMAGE" "$REGISTRY_IMAGE" || { 
  echo "❌ Failed to tag image"
  exit 1
}

echo "📦 Step 3/3: Pushing image to local registry..."
docker push "$REGISTRY_IMAGE" || { 
  echo "❌ Failed to push image to registry"
  exit 1
}

echo ""
echo "✅ Success! Image cached successfully."
echo "📋 Summary:"
echo "   • Pulled: $FULL_IMAGE"
echo "   • Tagged: $REGISTRY_IMAGE"
echo "   • Pushed to registry: $REGISTRY_HOST"
echo ""
echo "💡 On Host 2, pull with:"
echo "   docker pull $REGISTRY_IMAGE"
echo ""
echo "💡 Or use the pull script:"
echo "   ./bin/pull_image.sh $IMAGE_INPUT"
