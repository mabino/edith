#!/bin/bash
# Notarization script for Edith
# Requires: Apple Developer account, app-specific password, and valid signing identity

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Edith.app"

# Configuration - set these environment variables or modify defaults
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"  # App-specific password from appleid.apple.com
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application}"

usage() {
    echo "Usage: $0"
    echo ""
    echo "Required environment variables:"
    echo "  APPLE_ID         - Your Apple ID email"
    echo "  TEAM_ID          - Your Apple Developer Team ID"
    echo "  APP_PASSWORD     - App-specific password from appleid.apple.com"
    echo ""
    echo "Optional environment variables:"
    echo "  SIGNING_IDENTITY - Code signing identity (default: 'Developer ID Application')"
    echo ""
    echo "Example:"
    echo "  APPLE_ID=dev@example.com TEAM_ID=ABC123 APP_PASSWORD=xxxx-xxxx-xxxx-xxxx ./notarize.sh"
    exit 1
}

# Validate required variables
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_PASSWORD" ]; then
    echo "Error: Missing required environment variables"
    usage
fi

# Build release if needed
if [ ! -d "$APP_PATH" ]; then
    echo "Building release version..."
    "$SCRIPT_DIR/build.sh" Release
fi

echo "=== Notarization Process ==="

# Step 1: Code sign the app
echo "1. Signing app with '$SIGNING_IDENTITY'..."
codesign --force --deep --options runtime \
    --sign "$SIGNING_IDENTITY" \
    --timestamp \
    "$APP_PATH"

codesign --verify --verbose "$APP_PATH"
echo "✓ App signed"

# Step 2: Create ZIP for notarization
ZIP_PATH="$BUILD_DIR/Edith.zip"
echo "2. Creating ZIP archive..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "✓ ZIP created: $ZIP_PATH"

# Step 3: Submit for notarization
echo "3. Submitting for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait

# Step 4: Staple the notarization ticket
echo "4. Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

echo "✓ Notarization complete!"
echo ""
echo "The notarized app is at: $APP_PATH"
echo ""
echo "To create a distributable DMG, consider using create-dmg or similar tools."
