# Edith

A native macOS text editor built with Swift and SwiftUI.

![macOS 13.0+](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Core Editing
- **Multi-document support** with tabbed interface
- **Line number gutter** with click-to-select lines (click, drag, Cmd+click for non-contiguous)
- **Syntax highlighting** for 50+ languages via HighlightSwift
- **Find & Replace** with regex/PCRE support, document selector, and Extract All
- **Session restore** - reopens documents and unsaved changes on launch
- **File change detection** with reload/ignore banner

### View Options
- Show/Hide Line Numbers (⇧⌘L)
- Show/Hide Status Bar (⇧⌘/)
- Zoom In/Out (⌘+/⌘-)
- Show invisible characters (spaces, tabs, line endings)

### Settings (⌘,)
- **General**: Document restore, file monitoring, vim mode toggle
- **Text Encodings**: Default encoding for new documents (UTF-8 default)
- **Appearance**: System/Light/Dark mode
- **Editor Defaults**: Font, size, tab width, invisible characters

### Experimental: Vim-like Mode
Enable in Settings > General. Double-tap Esc to toggle.

- **Normal mode**: h/j/k/l navigation, w/b/e word movement, gg/G, 0/$
- **Insert mode**: i/a/I/A/o/O
- **Edit commands**: x, dd, d{motion}, number prefixes (3dd, 2dw)
- **Command mode**: :w, :q, :wq, :s/pattern/replacement/g

Visual indicator: green glow border when in normal/command mode.

## Requirements

- macOS 13.0 or later
- Xcode 15+ (for building)

## Building

```bash
# Build debug version
./scripts/build.sh

# Build release version
./scripts/build.sh Release

# Build and run
./scripts/run.sh

# Run tests
./scripts/test.sh
```

## Installation

### From Source
```bash
git clone https://github.com/mabino/edith.git
cd edith
./scripts/build.sh Release
# App is at build/Release/Edith.app
```

### Notarization (for distribution)
```bash
./scripts/notarize.sh
```
Requires Apple Developer account. See script prompts for Apple ID, Team ID, and app-specific password.

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| New Document | ⌘N |
| Open | ⌘O |
| Save | ⌘S |
| Close | ⌘W |
| Settings | ⌘, |
| Find & Replace | ⌘F |
| Show/Hide Line Numbers | ⇧⌘L |
| Show/Hide Status Bar | ⇧⌘/ |
| Zoom In | ⌘= |
| Zoom Out | ⌘- |
| Actual Size | ⌘0 |
| Help | ⌘? |

## License

MIT License © 2026 Michael Bino

See [LICENSE](LICENSE) for details.
