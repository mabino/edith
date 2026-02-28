#!/bin/bash
# Test script for Edith

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Running Edith tests..."

xcodebuild test \
    -project "$PROJECT_DIR/Edith.xcodeproj" \
    -scheme Edith \
    -destination 'platform=macOS' \
    -quiet

echo "✓ All tests passed"
