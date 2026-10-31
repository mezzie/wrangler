import AppKit
import Foundation
import WranglerCore

@main
struct WranglerCLI {
    static let history = WindowHistory()

    static func printUsage() {
        print("""
        Wrangler - Open Source Mac Window Organizer

        Usage:
          wrangler check-perm [--prompt]   Check / request Accessibility permissions
          wrangler screens                 List connected displays with Cocoa and AX frames
          wrangler target                  Inspect currently focused window
          wrangler snap <preset>           Snap focused window (presets: full, left-half, right-half, top-half, bottom-half, center)
          wrangler custom <cols> <rows> <startCol> <startRow> <endCol> <endRow>
        """)
    }

    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        guard let command = args.first else {
            printUsage()
            return
        }

        let ax = AccessibilityEngine()
        let displays = DisplayManager()

        switch command {
        case "check-perm":
            let prompt = args.contains("--prompt")
            let trusted = AccessibilityEngine.isTrusted(promptIfNeeded: prompt)
            print("Accessibility Trusted: \(trusted)")
            if !trusted && prompt {
                print("Requested permission. Please grant Wrangler access in System Settings.")
            }

        case "screens":
            let screens = displays.getScreens()
            print("Detected \(screens.count) screen(s):")
            for (idx, screen) in screens.enumerated() {
                print("[\(idx)] ID: \(screen.id)")
                print("    Visible Frame (Cocoa): \(screen.visibleFrame)")
                print("    Visible Frame (AX):    \(screen.axVisibleFrame)")
            }

        case "target":
            do {
                let (_, target) = try ax.getWindowTarget()
                print("Focused Window:")
                print("  App:   \(target.appName ?? "Unknown") (PID: \(target.pid))")
                print("  Title: \(target.windowTitle ?? "<Untitled>")")
                print("  Frame: \(target.frame)")
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        case "snap":
            guard args.count > 1 else {
                print("Error: Missing preset name (e.g. left-half, right-half, full)")
                return
            }
            let presetName = args[1]
            let store = LayoutStore()
            guard let layout = store.get(id: presetName) else {
                print("Error: Unknown preset '\(presetName)'. Available: \(store.all().map(\.id).joined(separator: ", "))")
                return
            }

            do {
                guard let screen = displays.currentScreen() else {
                    print("Error: No active screen detected.")
                    return
                }

                let (element, target) = try ax.getWindowTarget()
                let targetRect = GridMath.calculateRect(
                    for: layout.selection,
                    in: screen.axVisibleFrame,
                    config: layout.config
                )

                print("Snapping '\(target.appName ?? "")' to \(presetName) -> \(targetRect)...")
                try ax.setWindowFrame(targetRect, element: element)
                print("Done!")
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        case "custom":
            guard args.count >= 7,
                  let cols = Int(args[1]),
                  let rows = Int(args[2]),
                  let sc = Int(args[3]),
                  let sr = Int(args[4]),
                  let ec = Int(args[5]),
                  let er = Int(args[6]) else {
                print("Usage: wrangler custom <cols> <rows> <startCol> <startRow> <endCol> <endRow>")
                return
            }

            let config = GridConfig(columns: cols, rows: rows, gap: 8, outerMargin: 8)
            let selection = GridSelection(
                start: GridCellIndex(col: sc, row: sr),
                end: GridCellIndex(col: ec, row: er)
            )

            do {
                guard let screen = displays.currentScreen() else {
                    print("Error: No active screen detected.")
                    return
                }
                let (element, target) = try ax.getWindowTarget()
                let targetRect = GridMath.calculateRect(for: selection, in: screen.axVisibleFrame, config: config)
                print("Snapping '\(target.appName ?? "")' to custom grid selection -> \(targetRect)...")
                try ax.setWindowFrame(targetRect, element: element)
                print("Done!")
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        default:
            print("Unknown command: \(command)")
            printUsage()
        }
    }
}
