# Edith - Iteration Notes

## Current State: v1.3 Session Restore & General Settings ✓

Build and all tests verified.

## What's Done
- File > New Text Document (⌘N)
- Settings window (⌘,) with four tabs: General, Text Encodings, Appearance, Editor Defaults
- General settings: Re-open documents, Restore unsaved changes, Refresh documents changed on disk
- Restore Defaults button in settings
- Line number gutter with proper alignment and styling
- View > Show/Hide Line Numbers toggle (⇧⌘L)
- View > Zoom In (⌘=), Zoom Out (⌘-), Actual Size (⌘0)
- Format > Font > Bigger (⇧⌘+), Smaller (⌥⌘-)
- Custom invisible character rendering (·↵△° etc.)
- File change detection with reload/ignore banner
- Help window (⌘?)
- Session restore on launch (re-opens previously open **saved** documents)
- 159 unit tests + 31 UI tests

## Session Restore Notes
- Only documents with a saved file path are restored (not untitled documents)
- Data is stored in the sandboxed container:
  `~/Library/Containers/com.edith.texteditor/Data/Library/Application Support/Edith/Restore/`
- Uses applicationShouldTerminate + applicationWillTerminate + NotificationCenter as fallbacks

## Tests
Run `./scripts/test.sh` to verify all functionality.
UI tests cover zoom menu states, keyboard shortcuts, and session restore.

## Next Steps
1. Test session restore manually with a saved document
2. Consider adding unsaved content backup restoration
3. Improve invisible character styling

## Tech Stack
- SwiftUI + NSTextView wrapper, @AppStorage, DocumentGroup
- Target: macOS 13.0+

## Scripts
- `./scripts/build.sh [Debug|Release]` - Build the app
- `./scripts/run.sh` - Build and launch
- `./scripts/test.sh` - Run all tests
- `./scripts/notarize.sh` - Sign and notarize for distribution
