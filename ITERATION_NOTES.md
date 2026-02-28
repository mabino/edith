# Edith - Iteration Notes

## Current State: v1.1 Line Number Gutter Added ✓

Build and tests verified 2026-02-28.

## What's Done
- File > New Text Document (⌘N)
- Settings window (⌘,) with three tabs: Text Encodings, Appearance, Editor Defaults
- Restore Defaults button in settings
- Line number gutter with proper alignment
- 45 unit/integration tests protecting gutter functionality

## Tests
Run `./scripts/test.sh` to verify:
- Text visibility in textarea
- Line numbers appearing top-to-bottom
- Line number alignment with text lines
- Font/color/layout properties

## Suggested Future Enhancements

1. **File operations**: Open, Save, Save As menus
2. **Edit menu**: Find & Replace
3. **App icon**: Add custom icon asset
4. **Toggle line numbers**: Settings option to show/hide gutter
5. **Syntax highlighting**: Basic support
6. **Recent documents**: File > Open Recent

## Tech Stack
- SwiftUI + NSTextView wrapper, @AppStorage, DocumentGroup
- Target: macOS 13.0+

## Scripts
- `./scripts/build.sh [Debug|Release]` - Build the app
- `./scripts/run.sh` - Build and launch
- `./scripts/test.sh` - Run all tests
- `./scripts/notarize.sh` - Sign and notarize for distribution
