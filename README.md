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
