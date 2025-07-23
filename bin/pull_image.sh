#!/bin/bash

# === CONFIGURATION ===
REGISTRY_HOST="${REGISTRY_HOST:-docker-proxy.local:5000}"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <image[:tag]> [--retag]"
  echo "Example: $0 nginx:alpine"
  echo "Example: $0 ubuntu --retag  # pulls and retags to original name"
  exit 1
fi

# Check if --retag flag is provided
RETAG=false
if [[ "$2" == "--retag" ]]; then
  RETAG=true
fi

# Split image and tag
IMAGE_INPUT="$1"
IMAGE_NAME=$(echo "$IMAGE_INPUT" | cut -d: -f1)
IMAGE_TAG=$(echo "$IMAGE_INPUT" | cut -s -d: -f2)

if [[ -z "$IMAGE_TAG" ]]; then
  IMAGE_TAG="latest"
fi

ORIGINAL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"

# Handle official images (no namespace) - add library/ prefix for registry
if [[ "$IMAGE_NAME" != */* ]]; then
  REGISTRY_IMAGE="$REGISTRY_HOST/library/$IMAGE_NAME:$IMAGE_TAG"
else
  REGISTRY_IMAGE="$REGISTRY_HOST/$IMAGE_NAME:$IMAGE_TAG"
fi

echo "🐳 Docker Image Pull Workflow"
echo "=============================="
echo "Registry Image: $REGISTRY_IMAGE"
echo "Original Name: $ORIGINAL_IMAGE"
echo "Retag: $RETAG"
echo ""

echo "📥 Step 1: Pulling image from registry..."
docker pull "$REGISTRY_IMAGE" || { 
  echo "❌ Failed to pull image from registry"
  echo "💡 Make sure the image was cached on Host 1 using:"
  echo "   ./bin/cache_image.sh $IMAGE_INPUT"
  exit 1
}

if [[ "$RETAG" == "true" ]]; then
  echo "🏷️ Step 2: Retagging to original name..."
  docker tag "$REGISTRY_IMAGE" "$ORIGINAL_IMAGE" || { 
    echo "❌ Failed to retag image"
    exit 1
  }
  
  echo "🗑️ Step 3: Removing registry image to save space..."
  docker rmi "$REGISTRY_IMAGE" || { 
    echo "⚠️ Warning: Failed to remove registry image, but continuing..."
  }
  
  echo ""
  echo "✅ Success! Image pulled, retagged, and cleaned up."
  echo "📋 Summary:"
  echo "   • Pulled: $REGISTRY_IMAGE"
  echo "   • Retagged to: $ORIGINAL_IMAGE"
  echo "   • Removed: $REGISTRY_IMAGE (to save space)"
  echo ""
  echo "💡 You can now use: docker run $ORIGINAL_IMAGE"
else
  echo ""
  echo "✅ Success! Image pulled from registry."
  echo "📋 Summary:"
  echo "   • Pulled: $REGISTRY_IMAGE"
  echo ""
  echo "💡 Use the image with: docker run $REGISTRY_IMAGE"
  echo "💡 Or retag it with: docker tag $REGISTRY_IMAGE $ORIGINAL_IMAGE"
  echo "💡 Or re-run with --retag flag: $0 $IMAGE_INPUT --retag"
fi
