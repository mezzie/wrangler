<p align="center">
  <img src="docs/icons/option_flat_minimal.png" width="96" height="96" alt="Wrangler Logo" style="border-radius: 20px;">
</p>

<h1 align="center">Wrangler</h1>

<p align="center">
  <strong>Native macOS window organizer combining interactive grid snapping, edge drop zones, and automated tiling.</strong>
</p>

<p align="center">
  <a href="https://github.com/mezzie/wrangler/releases/latest">Download DMG</a> &bull;
  <a href="#quickstart">Quickstart</a> &bull;
  <a href="#features">Features</a> &bull;
  <a href="#shortcuts">Shortcuts</a> &bull;
  <a href="CHANGELOG.md">Changelog</a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/mezzie/wrangler?color=0969da&label=Release" alt="Latest Release">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-555555" alt="Platform: macOS 13+">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License: MIT">
  <img src="https://img.shields.io/badge/SIP-Not%20Required-success" alt="SIP Not Required">
</p>

---

## Overview

Most macOS window managers force a choice between two extremes:
1. **Manual snappers** that require memorizing dozens of keyboard shortcuts for every quadrant.
2. **Tiling managers** that aggressively take over the desktop and require disabling System Integrity Protection (SIP).

Wrangler bridges this gap. It provides a visual **HUD grid** for fast manual adjustments, **Snap Zones** for drag-and-drop ultrawide workflows, and **one-key Auto-Tiling** using recursive Binary Space Partitioning—all running within standard macOS Accessibility APIs with zero system security compromises.

---

## Quickstart

### Homebrew (Recommended)
```bash
brew install mezzie/tap/wrangler
```

### Direct Download
1. Download **[Wrangler.dmg](https://github.com/mezzie/wrangler/releases/latest)**.
2. Drag **Wrangler** into your `/Applications` directory.
3. Open Wrangler and grant **Accessibility** permissions when prompted in **System Settings → Privacy & Security → Accessibility**.

### Build from Source
```bash
git clone https://github.com/mezzie/wrangler.git
cd wrangler
./scripts/build-app.sh
open build/Wrangler.app
```

---

## Features

### Interactive Grid Overlay (`⌥ Space`)
Summons a floating HUD directly at your cursor location. Click and drag across the cells to draw an exact destination frame. A translucent blueprint previews the snap location in real time before you release the mouse.

### Snap Zones (Drag-to-Snap)
Drag any window by its title bar to screen edges or corners to trigger template layouts tailored for ultrawide displays:
- **50% / 50% Split**: Left and right screen halves.
- **Three Columns**: 33% / 33% / 33% tri-pane layout.
- **Center Focus**: 25% sidebar | 50% center master | 25% sidebar.
- **Four Corners**: Screen quarters.

### Automated Window Tiling (`⌃ ⌥ T`)
Organizes all visible, non-minimized windows on the active display into a balanced Binary Space Partitioning (BSP) tree. Automatically scales windows to eliminate overlap while keeping the active application focused.

### Multi-Display Hopping
Transfer windows across monitors instantly while preserving proportional dimensions:
- `⌃ ⌥ →` moves focused window to the next display.
- `⌃ ⌥ ←` moves focused window to the previous display.

### Width Cycling
Directional presets cycle width ratios on repeated presses (e.g., Left Half cycles between 1/2, 2/3, and 1/3 widths).

### Stage Manager Clearance
Detects whether macOS Stage Manager thumbnails are visible and dynamically adjusts margins so windows never cover the stage strip.

### In-App Auto-Updates
Periodically checks GitHub Releases for new updates. Allows one-click in-place upgrading and restarting without Terminal commands.

---

## Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| `⌥ Space` | Grid Overlay | Opens interactive grid HUD at mouse cursor |
| `⌃ ⌥ ↵` or `⌃ ⌥ M` | Maximize | Expands focused window to full visible screen |
| `⌃ ⌥ T` | Auto-Tile | Organizes open windows into a non-overlapping BSP tree |
| `⌃ ⌥ →` | Next Screen | Shifts focused window to the next connected display |
| `⌃ ⌥ ←` | Prev Screen | Shifts focused window to the previous connected display |
| `⌥ ⌘ Z` | Undo | Restores window to its coordinates before the last snap |
| `⌘ ,` | Preferences | Opens settings for grid sizes, margins, templates, and languages |
| `ESC` | Cancel | Closes overlay without moving windows |

*All shortcuts can be customized in **Preferences → Shortcuts** using the interactive key recorder.*

---

## Preferences

Wrangler features a multi-section sidebar settings window (`⌘ ,`):

- **Snap Zones**: Toggle drag-to-snap behavior, select ultrawide templates, and tune edge trigger sensitivity (15–60 px).
- **Grid & Gaps**: Adjust default columns (2–12), rows (1–8), inner window gaps (0–32 px), and outer screen padding (0–40 px).
- **Behavior**: Toggle Stage Manager margin avoidance, width cycling, launch at login (`SMAppService`), and in-app language selection.
- **Ignored Applications**: Blacklist utility apps (Calculator, 1Password, floating panels) so Auto-Tile and Snap ignore them.
- **Shortcuts**: Interactive shortcut recorder to rebind any hotkey by pressing the desired keys.
- **Restore Defaults**: Independent reset buttons per tab to restore original settings without wiping other customizations.

---

## CLI Automation

Wrangler includes a standalone headless CLI (`wrangler-cli`):

```bash
# Authorization check
swift run wrangler-cli check-perm

# List connected displays and geometry
swift run wrangler-cli screens

# Inspect frontmost target window
swift run wrangler-cli target

# Snap focused window to standard presets
swift run wrangler-cli snap left-half
swift run wrangler-cli snap right-half
swift run wrangler-cli snap full
swift run wrangler-cli snap center

# Snap to custom grid coordinates: <cols> <rows> <startCol> <startRow> <endCol> <endRow>
swift run wrangler-cli custom 4 4 0 0 1 2
```

---

## Architecture

```
Sources/
├── WranglerCore/              # Core logic engine
│   ├── Accessibility/         # AXUIElement abstractions and Z-order detection
│   ├── Display/               # NSScreen geometry, Stage Manager offsets, and display mapping
│   ├── Geometry/              # Grid coordinate mathematics and gap resolution
│   ├── History/               # Thread-safe undo and restore stack
│   ├── Hotkey/                # Key code mappings and shortcut data models
│   ├── Layout/                # AppSettings persistence and presets
│   ├── SnapZones/             # Edge-drag hit testing and template resolution
│   └── Tiling/                # Recursive Binary Space Partitioning (BSP) auto-tile engine
│
└── WranglerApp/               # Native macOS Application
    ├── AppDelegate.swift      # Application lifecycle and status item initialization
    ├── Hotkey/                # Carbon global event hotkey manager
    ├── Launch/                # ServiceManagement login item service
    ├── MenuBar/               # Menu bar controller and actions
    ├── Overlay/               # Floating glass HUD panel and AppKit canvas
    ├── Preferences/           # Sidebar preferences window and key recorder
    ├── Preview/               # Real-time ghost target blueprint panel
    ├── SnapZones/             # Global mouse drag monitor and drop handler
    └── Update/                # GitHub Releases checker and auto-installer
```

---

## Development

Run the automated test suite:

```bash
swift test
```

Build the release `.app` bundle:

```bash
./scripts/build-app.sh
```

Package the release `.dmg`:

```bash
./scripts/create-dmg.sh 1.5.0
```

---

## License

Distributed under the [MIT License](LICENSE). See [CHANGELOG.md](CHANGELOG.md) for version release notes.
