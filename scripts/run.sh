#!/bin/bash
# Run script for Edith

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Check if app exists, build if not
if [ ! -d "$BUILD_DIR/Edith.app" ]; then
    echo "App not found. Building first..."
    "$SCRIPT_DIR/build.sh" Debug
fi

echo "Launching Edith..."
open "$BUILD_DIR/Edith.app"
