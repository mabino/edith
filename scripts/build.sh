#!/bin/bash
# Build script for Edith

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Default configuration
CONFIGURATION="${1:-Release}"

echo "Building Edith ($CONFIGURATION)..."

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the project
xcodebuild -project "$PROJECT_DIR/Edith.xcodeproj" \
    -scheme Edith \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -destination 'platform=macOS' \
    build

# Copy the app to build directory
APP_PATH="$BUILD_DIR/DerivedData/Build/Products/$CONFIGURATION/Edith.app"
if [ -d "$APP_PATH" ]; then
    cp -R "$APP_PATH" "$BUILD_DIR/"
    echo "✓ Build complete: $BUILD_DIR/Edith.app"
else
    echo "✗ Build failed: App not found at $APP_PATH"
    exit 1
fi
