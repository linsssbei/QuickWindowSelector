# QuickWindowSelector

A fast, keyboard-driven window switcher for macOS. Press a hotkey to instantly search and switch to any window on your screen.

![macOS](https://img.shields.io/badge/macOS-13.0+-orange.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-green.svg)

## Features

- **Instant Search**: Fuzzy search through all open windows
- **Keyboard-Driven**: Full keyboard navigation
- **Vim-Style Navigation**: Use `Ctrl+J`/`Ctrl+K` (or arrow keys) to move up/down
- **Customizable Hotkeys**: Configure your own activation hotkey
- **Background Refresh**: Automatically keeps window list up-to-date
- **Menu Bar App**: Runs quietly in the menu bar, no Dock icon

## Installation

### Option 1: DMG (Recommended)
1. Download `QuickWindowSelector.dmg`
2. Open the DMG
3. Drag `QuickWindowSelector.app` to `/Applications`
4. Run the app

### Option 2: Build from Source
```bash
# Clone the repository
git clone <repository-url>
cd QuickWindowSelector

# Build the DMG
./build_dmg.sh

# The DMG will be created at QuickWindowSelector/QuickWindowSelector.dmg
```

## Usage

1. **Launch the app** - It runs in the menu bar (no Dock icon)
2. **Press the hotkey** (default: `Ctrl+Space`) to open the window picker
3. **Type to search** - Fuzzy search matches window titles and app names
4. **Select a window** - Press `Enter` to switch, `Escape` to cancel
5. **Navigate** - Arrow keys or `Ctrl+K` (up) / `Ctrl+J` (down)

## Configuration

Click the menu bar icon → **Settings** to configure:

| Setting | Description | Default |
|---------|-------------|---------|
| Show Window | Hotkey to activate the picker | `Ctrl+Space` |
| Move Up/Down | Navigation hotkeys | `Ctrl+K` / `Ctrl+J` |
| Cache Refresh | How often to refresh window list | 5 seconds |
| Hide Small Windows | Filter tiny windows (width in px) | 50px |
| Excluded Apps | Apps to hide from the list | WindowManager, self |
| Excluded Owners | Window owners to hide | borders |

### Hotkey Recording

1. Click **Record** next to the hotkey you want to change
2. Press your desired key combination (must include a modifier like Ctrl, Option, Cmd, or Shift)
3. Click **Save**

### Config File

Settings are saved to:
```
~/Library/Application Support/QuickWindowSelector/config.plist
```

You can also edit this file directly, then click **Settings** → the app will reload.

### Restore Defaults

Click **Restore Defaults** in the Settings window to reset all options.

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open picker | `Ctrl+Space` (configurable) |
| Move up | `↑` or `Ctrl+K` |
| Move down | `↓` or `Ctrl+J` |
| Select | `Enter` |
| Cancel | `Escape` |

## Troubleshooting

### App doesn't appear after installation
```bash
# If Gatekeeper blocks the app:
xattr -cr /Applications/QuickWindowSelector.app
```

### Hotkey not working
- Make sure no other app is using the same hotkey
- Check System Settings → Privacy & Security → Accessibility to grant access

### Windows not showing
- Some apps require Accessibility permissions to read window titles
- Go to **System Settings → Privacy & Security → Accessibility** and enable for QuickWindowSelector

### Min window width not working
- This filters based on actual window pixel width
- Increase the value to see more windows, decrease to see only main windows

## Building from Source

### Requirements
- macOS 13.0 or later
- Xcode 15+ or Swift 5.9+

### Build Commands

```bash
# Build debug
cd QuickWindowSelector
swift build

# Build release
swift build -c release

# Run tests
swift test

# Build DMG
../build_dmg.sh
```

### Code Signing

The build script uses ad-hoc signing for local development. For distribution:
```bash
# With Apple Developer certificate
codesign --force --deep --sign "Developer ID Application: Your Name" QuickWindowSelector.app
```

## Architecture

```
QuickWindowSelector/
├── Sources/
│   ├── App/
│   │   ├── AppDelegate.swift      # App lifecycle, menu bar
│   │   └── main.swift             # Entry point
│   ├── Core/
│   │   ├── ConfigManager.swift    # Settings management
│   │   ├── FuzzySearch.swift      # Fuzzy matching algorithm
│   │   ├── WindowInfo.swift       # Window data model
│   │   └── WindowManager.swift    # Window fetching & caching
│   ├── UI/
│   │   ├── ConfigView.swift       # Settings window UI
│   │   ├── ConfigWindowController.swift
│   │   ├── HotkeyRecorderView.swift # Custom hotkey recorder
│   │   ├── SearchView.swift       # Main search UI
│   │   ├── SearchViewModel.swift  # Search logic
│   │   └── SearchWindowController.swift
│   └── Utilities/
│       ├── FloatingPanel.swift     # Floating window panel
│       └── GlobalHotKey.swift     # Global hotkey registration
├── Tests/
│   └── FuzzySearchTests.swift     # Unit tests
└── Resources/
    ├── Assets.xcassets/           # App icons
    └── Info.plist
```

## License

MIT License
