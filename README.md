<p align="center">
  <h1 align="center">🤠 Wrangler</h1>
  <p align="center"><strong>The open-source window grid manager for macOS.</strong></p>
  <p align="center">
    <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue.svg" alt="Platform: macOS 13+">
    <img src="https://img.shields.io/badge/Swift-5.9%2B-orange.svg" alt="Swift: 5.9+">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
    <img src="https://img.shields.io/badge/SIP%20Status-Not%20Required-brightgreen.svg" alt="SIP Not Required">
  </p>
</p>

---

Wrangler gives you instant, mouse- and keyboard-driven window organization on macOS. Summon an interactive glass HUD at your cursor, drag across grid cells, and watch your windows snap cleanly into position.

No background daemons requiring SIP to be disabled. 100% native Swift, AppKit, and Accessibility APIs.

---

## ✨ Features

- 🎯 **Interactive Grid Overlay**: Hit **`Option + Space`** to summon a floating glass grid at your mouse cursor. Click and drag across cells to resize and position any window.
- 📐 **Dynamic Grid Sizes**: Switch instantly between **`2×2`**, **`3×3`**, **`4×4`**, **`6×4`**, or fine-tune rows and columns with live steppers (`-` / `+`).
- 🖥️ **Multi-Display Hopping**: Throw windows to your next or previous screen instantly with **`⌃ ⌥ →`** or **`⌃ ⌥ ←`**, automatically scaling to the target display's dimensions.
- 🔁 **Window Size Cycling**: Pressing Left Half or Right Half repeatedly cycles window widths: **`½ → ⅔ → ⅓ → ½`** (Rectangle / Lasso pattern).
- 🧩 **Stage Manager Aware**: Automatically detects macOS Stage Manager and reserves margin space so windows never overlap your stage thumbnails.
- 🎨 **Ghost Destination Preview**: A real-time translucent blueprint outlines exactly where the window will land before you release the mouse.
- ⏪ **Undo / Restore**: Changed your mind? Press **`Option + Command + Z`** to instantly restore any window to its prior frame.
- ⚙️ **Preferences Window**: Press **`Command + ,`** from the menu bar to customize inner window gaps (0–32px), outer screen margins (0–40px), and behavior toggles.

---

## ⌨️ Default Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`⌥ Space`** | **Show Grid HUD** | Opens floating grid overlay at current cursor position |
| **`⌃ ⌥ →`** | **Next Display** | Throws focused window to the next monitor |
| **`⌃ ⌥ ←`** | **Prev Display** | Throws focused window to the previous monitor |
| **`⌥ ⌘ Z`** | **Undo Snap** | Restores focused window to its prior size and position |
| **`⌘ ,`** | **Preferences** | Opens spacing, gap, and grid configuration window |
| **`ESC`** | **Dismiss** | Closes overlay without modifying windows |

---

## 🚀 Quickstart & Installation

### Requirements
- macOS 13.0 (Ventura) or later (Apple Silicon & Intel)
- Xcode Command Line Tools (`xcode-select --install`)

### Build & Run from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mezzie/wrangler.git
   cd wrangler
   ```

2. **Build and assemble the native `.app` bundle:**
   ```bash
   ./scripts/build-app.sh
   ```
   *Note: The build script automatically detects your local Apple Development certificate in Keychain for code-signing, avoiding permission invalidations.*

3. **Launch Wrangler:**
   ```bash
   open build/Wrangler.app
   ```
   *(Optional) Copy to `/Applications` for Spotlight / Raycast launch:*
   ```bash
   cp -R build/Wrangler.app /Applications/
   ```

4. **Grant Accessibility Permission:**
   - Go to **System Settings → Privacy & Security → Accessibility**.
   - Toggle **Wrangler** to **ON**.

---

## 🛠️ CLI Mode

Wrangler also includes a headless command-line tool (`wrangler-cli`) for scripting, automation, or keyboard maestro integration:

```bash
# Check accessibility permission
swift run wrangler-cli check-perm

# List connected displays and coordinate frames
swift run wrangler-cli screens

# Inspect frontmost focused window
swift run wrangler-cli target

# Snap active window to a preset
swift run wrangler-cli snap left-half
swift run wrangler-cli snap right-half
swift run wrangler-cli snap full
swift run wrangler-cli snap center

# Snap to arbitrary custom grid coordinates: <cols> <rows> <startCol> <startRow> <endCol> <endRow>
swift run wrangler-cli custom 4 4 0 0 1 2
```

---

## 🏗️ Architecture

```
wrangler/
├── Package.swift
├── Sources/
│   ├── WranglerCore/              # Headless Core Engine
│   │   ├── Accessibility/         # AXUIElement wrappers (move, resize, focus detection)
│   │   ├── Display/               # NSScreen geometry, Stage Manager clearance, multi-display map
│   │   ├── Geometry/              # Grid math, multi-cell span calculations, gap offsets
│   │   ├── History/               # Thread-safe undo/restore stack
│   │   └── Layout/                # AppSettings and NamedLayout presets
│   │
│   ├── WranglerApp/               # Native macOS Application
│   │   ├── Overlay/               # Glass HUD NSPanel & AppKit GridCanvasView
│   │   ├── Preview/               # Floating ghost preview window
│   │   ├── MenuBar/               # NSStatusItem menu bar controller
│   │   ├── Hotkey/                # Carbon global event hotkeys
│   │   └── Preferences/           # SwiftUI Preferences configuration window
│   │
│   └── WranglerCLI/               # Command-line automation tool
└── Tests/
    └── WranglerCoreTests/         # Comprehensive unit tests
```

---

## 🧪 Running Tests

```bash
swift test
```

All 12 unit tests verify geometry calculations, gap/margin offsets, multi-cell selection bounds, undo stack limits, and multi-display coordinate mappings.

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for more information.
