# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.8.0] - 2026-11-01

### Added
- **Spatial Focus Navigation**: Focus adjacent windows without touching the mouse (`⌃ ⌥ H` left, `⌃ ⌥ L` right, `⌃ ⌥ K` up, `⌃ ⌥ J` down).
- **Same-App Window Cycling**: Cycle through open windows of the active application with `⌃ ⌥ ` `.
- **Smooth Window Animations**: Toggleable 60fps ease-out window gliding in Preferences.
- **Coding & Golden Ratio Templates**: Added 65% | 35% Coding Split and 61.8% | 38.2% Golden Ratio Snap Zone templates.
- **Raycast Extension**: Official Raycast extension package in `extensions/raycast-wrangler/`.

### Fixed
- **Dock Click False Positives**: Snap Zones strictly exclude the macOS Dock and require the window to move at least 15 pixels, preventing accidental preview boxes when clicking Dock icons.
- **37 Automated Unit Tests**: Added regression guard `testDockCursorReturnsNil`.

---

## [1.7.0] - 2026-10-31

### Added
- **Workspaces (Profiles)**: Save and restore entire multi-window desktop setups using the deterministic Rectangle Pro App-to-Slot model with occlusion culling.
- **Window Swap**: Instant reciprocal position swap for frontmost windows (`⌃ ⌥ S`).
- **Numpad Spatial Snapping**: Direct keypad bindings (`⌃ ⌥ 1` to `⌃ ⌥ 9`).
- **Shake to Summon**: Fast cursor shake gesture to summon grid HUD.
- **Modifier-Hold Snap**: Hold `Control` or `fn` while dragging to reveal snap blueprints anywhere.
- **Dedicated Menu Bar Icon**: Retina dual-pane lasso template icon (`isTemplate = true`).
- **34 Automated Unit Tests**: Comprehensive regression test suite.

---

## [1.6.0] - 2026-10-31

### Added
- **Official App Icon**: Brand-new flat cobalt & lasso macOS squircle icon (`AppIcon.icns`) with full Retina support. Included on DMG installer.
- **Launch at Login**: 1-click native macOS 13+ `SMAppService` toggle in Preferences.
- **Ignored Applications**: Blacklist utility apps (Calculator, 1Password, floating panels) with an interactive "+ Add Running App" selector.
- **Professional README**: Clean, emoji-free developer documentation modeled after leading open-source projects.

---

## [1.5.0] - 2026-10-31

### Added
- **In-App Language Picker**: Switch between System Default, English, 日本語 (Japanese), 简体中文 (Simplified Chinese), Deutsch (German), and Español (Spanish) directly inside Preferences.
- **Embedded Localizations**: Full `.lproj` string catalogs for English, Japanese, Chinese, German, and Spanish.
- **Interactive Shortcut Recorder**: Click any shortcut badge in Preferences to type and bind custom key combinations.
- **Restore Defaults Per Tab**: Dedicated button at the bottom-right of each Preferences tab to reset only that tab's settings without wiping others.

### Changed
- Refined Preferences window layout with clean left-sidebar navigation (Docker Desktop style).

---

## [1.4.0] - 2026-10-31

### Added
- **In-App Auto-Updater**: Checks for updates against GitHub Releases and performs seamless one-click in-place update and restart (Docker Desktop style).
- **Left-Sidebar Preferences Navigation**: Replaced vertical scrollview with a clean multi-section left sidebar.

---

## [1.3.0] - 2026-10-31

### Added
- **Snap Zones (Drag-to-Snap)**: Drag windows by their title bar to screen edges or corners to snap into templates.
- **Ultrawide Templates**: Added support for 50/50 Split, 33/33/33 Three Columns, and 25|50|25 Center Focus.
- **Edge Sensitivity Slider**: Configurable trigger threshold in Preferences.

---

## [1.2.2] - 2026-10-31

### Fixed
- **Apple Apps Window Resizing**: Fixed issue where Apple Messages, Safari, and Notes resisted resizing by checking `isWindowResizable` to skip non-resizable popovers and bypassing `AXEnhancedUserInterface`.
- **Ghost Preview Lag**: Removed animation throttling for instant 60fps frame updates during mouse dragging.

---

## [1.2.1] - 2026-10-31

### Added
- **Dedicated Maximize Shortcuts**: Added `⌃ ⌥ ↵` (Control + Option + Return) and `⌃ ⌥ M`.

### Fixed
- **Hardware Z-Order Detection**: Switched to CoreGraphics window list (`CGWindowListCopyWindowInfo`) to reliably capture the topmost user window even after focus shifts.

---

## [1.2.0] - 2026-10-31

### Added
- **AeroSpace-Style Auto-Tiling**: Instant one-key desktop organization using recursive Binary Space Partitioning (`⌃ ⌥ T`).
- **Auto-Tile HUD Button**: Added quick-tile button directly into the `⌥ Space` overlay.

---

## [1.0.0] - 2026-10-31

### Added
- **Initial Public Release**:
  - Interactive grid HUD (`⌥ Space`) with live mouse drag selection.
  - Multi-display hopping (`⌃ ⌥ →` and `⌃ ⌥ ←`).
  - Window size cycling (½ → ⅔ → ⅓ → ½).
  - macOS Stage Manager margin avoidance.
  - Undo history stack (`⌥ ⌘ Z`).
  - Automated `.dmg` packaging script and GitHub Actions release workflow.
