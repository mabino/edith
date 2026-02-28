# Edith - Iteration Notes

## Current State: v1.2 Zoom & Font Size Menus ✓

Build and tests verified 2025-01.

## What's Done
- File > New Text Document (⌘N)
- Settings window (⌘,) with three tabs: Text Encodings, Appearance, Editor Defaults
- Restore Defaults button in settings
- Line number gutter with proper alignment
- View > Show/Hide Line Numbers toggle
- View > Zoom In (⌘=), Zoom Out (⌘-), Actual Size (⌘0)
- Format > Font > Bigger (⇧⌘+), Smaller (⌥⌘-)
- Actual Size disabled when already at default zoom
- Zoom In/Out disabled at bounds (4x max, 0.25x min)
- 146 unit tests + 26 UI tests

## Tests
Run `./scripts/test.sh` to verify all functionality.
UI tests cover zoom menu states and keyboard shortcuts.

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
