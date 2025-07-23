#!/bin/bash

# === CONFIGURATION ===
REGISTRY_CONTAINER="${REGISTRY_CONTAINER:-docker-cache}"
REGISTRY_DATA_DIR="${REGISTRY_DATA_DIR:-$(pwd)/registry-data}"

echo "🧹 Docker Registry Cleanup Script"
echo "================================="
echo "Container: $REGISTRY_CONTAINER"
echo "Data Directory: $REGISTRY_DATA_DIR"
echo ""

# Safety confirmation
read -p "⚠️  This will DELETE ALL cached images. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled."
    exit 0
fi

echo ""
echo "🛑 Step 1/4: Stopping registry container..."
if docker stop "$REGISTRY_CONTAINER" 2>/dev/null; then
    echo "✅ Container $REGISTRY_CONTAINER stopped"
else
    echo "⚠️  Container $REGISTRY_CONTAINER was not running or doesn't exist"
fi

echo ""
echo "🗑️ Step 2/4: Removing registry container..."
if docker rm "$REGISTRY_CONTAINER" 2>/dev/null; then
    echo "✅ Container $REGISTRY_CONTAINER removed"
else
    echo "⚠️  Container $REGISTRY_CONTAINER was already removed or doesn't exist"
fi

echo ""
echo "🗑️ Step 3/4: Removing registry data directory..."
if [[ -d "$REGISTRY_DATA_DIR" ]]; then
    rm -rf "$REGISTRY_DATA_DIR" && echo "✅ Registry data directory removed: $REGISTRY_DATA_DIR"
else
    echo "⚠️  Registry data directory doesn't exist: $REGISTRY_DATA_DIR"
fi

echo ""
echo "🚀 Step 4/4: Starting fresh registry..."
if docker compose up -d; then
    echo "✅ Registry started successfully"
else
    echo "❌ Failed to start registry. Check docker-compose.yml"
    exit 1
fi

echo ""
echo "🎉 Registry cleanup completed!"
echo "📋 Summary:"
echo "   • Container stopped and removed: $REGISTRY_CONTAINER"
echo "   • Data directory wiped: $REGISTRY_DATA_DIR"
echo "   • Fresh registry started on port 5000"
echo ""
echo "💡 The registry is now empty and ready for new images."
