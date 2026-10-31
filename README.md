# Wrangler

> Open-source macOS window organizer and grid manager.

Wrangler gives you instant, keyboard- and mouse-driven grid layouts for your macOS desktop. Snaps windows cleanly into halves, thirds, quarters, or custom $M \times N$ cell selections without requiring System Integrity Protection (SIP) to be disabled.

---

## Architecture Overview

Wrangler is divided into a headless engine (`WranglerCore`) and application/UI targets.

```
wrangler/
├── Package.swift
├── Sources/
│   ├── WranglerCore/
│   │   ├── Accessibility/     # AXUIElement window inspection, move, and resize
│   │   ├── Display/           # NSScreen geometry & Cocoa <-> AX coordinate translation
│   │   ├── Geometry/          # Grid math, multi-cell spans, gap & margin resolution
│   │   ├── History/           # Window undo/restore history stack
│   │   └── Layout/            # Preset and user-defined grid layouts (JSON serializable)
│   └── WranglerCLI/           # CLI tool to test, script, and trigger window snapping
└── Tests/
    └── WranglerCoreTests/     # Comprehensive unit tests for math and state stores
```

---

## Features

- **Interactive Grid Overlay**: Hit **`Option + Space`** to summon a floating glass HUD at your mouse position. Click and drag across cells to resize and position any window.
- **Dynamic Grid Sizes**: Switch instantly between **`2×2`**, **`3×3`**, **`4×4`**, **`6×4`**, or fine-tune columns with the stepper (`-` / `+`).
- **Multi-Display Hopping**: Throw windows to the next screen instantly with **`Control + Option + Right Arrow`** (or `display.2` button on the HUD).
- **Shortcut Cycling**: Pressing Left Half or Right Half repeatedly cycles window width: **`½ → ⅔ → ⅓ → ½`**.
- **Stage Manager Aware**: Automatically avoids the macOS Stage Manager thumbnail strip on screen margins.
- **Custom Spacing & Gaps**: Adjust inner window gaps and outer screen margins in Preferences.
- **Extended Snap Presets**: Halves, Thirds (⅓, ⅔), Quarters (Top-Left, Top-Right, Bottom-Left, Bottom-Right), Maximize, and Center.
- **Ghost Target Preview**: Real-time translucent overlay outlines where the window will snap before releasing mouse.
- **Undo / Restore**: Restore any window to its previous position with **`Option + Command + Z`**.
- **Preferences Window**: Open with **`Command + ,`** from menu bar to configure grid dimensions, margins, gaps, and behaviors.

---

## Default Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`⌥ Space`** | Show Grid Overlay |
| **`⌃ ⌥ →`** | Move to Next Display |
| **`⌃ ⌥ ←`** | Move to Previous Display |
| **`⌥ ⌘ Z`** | Undo Last Snap |
| **`⌘ ,`** | Open Preferences Window |
| **`ESC`** | Dismiss Overlay without changes |

---

## Quickstart (GUI App)

### 1. Build and Package `.app`
```bash
./scripts/build-app.sh
```

### 2. Launch
```bash
open build/Wrangler.app
```
- App runs in the menu bar with icon `square.grid.3x3.square`.
- Global hotkey: **`Option + Space`** triggers the floating interactive grid overlay.
- Drag mouse across grid cells to select target size/position, or click preset buttons.
- Translucent ghost preview shows exactly where the window will snap.
- Release mouse to snap focused window into position.
- Press **`ESC`** or click outside to dismiss without changes.
- Undo: **`Option + Command + Z`** or select "Undo Last Snap" from menu bar.

---

## Quickstart (CLI)

### 1. Build
```bash
swift build
```

### 2. Check Permissions
macOS Accessibility permissions are required to move windows:
```bash
swift run wrangler check-perm --prompt
```

### 3. Detect Displays
```bash
swift run wrangler screens
```

### 4. Snap Frontmost Window
```bash
swift run wrangler snap left-half
swift run wrangler snap right-half
swift run wrangler snap full
swift run wrangler snap center
```

### 5. Custom Grid Selection
Snap focused window into cells spanning from (col 0, row 0) to (col 1, row 2) on a 4x4 grid:
```bash
swift run wrangler custom 4 4 0 0 1 2
```

---

## Test Suite

Run unit tests:
```bash
swift test
```

---

## License

MIT
