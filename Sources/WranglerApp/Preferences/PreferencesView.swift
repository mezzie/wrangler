import SwiftUI
import WranglerCore

public enum PrefsSection: String, CaseIterable, Identifiable {
    case snapZones = "Snap Zones"
    case grid = "Grid & Gaps"
    case behavior = "Behavior"
    case shortcuts = "Shortcuts"
    case about = "About & Updates"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .snapZones: return "rectangle.split.2x1"
        case .grid: return "square.grid.3x3"
        case .behavior: return "gearshape"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }
}

public struct PreferencesView: View {
    @State private var settings = AppSettings.load()
    @State private var selectedSection: PrefsSection = .snapZones

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Navigation Sidebar
            VStack(alignment: .leading, spacing: 4) {
                ForEach(PrefsSection.allCases) { section in
                    Button(action: { selectedSection = section }) {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedSection == section ? .accentColor : .secondary)
                                .frame(width: 18, alignment: .center)

                            Text(section.rawValue)
                                .font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))
                                .foregroundColor(selectedSection == section ? .primary : .secondary)

                            Spacer()
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(
                            selectedSection == section
                                ? Color.accentColor.opacity(0.12)
                                : Color.clear
                        )
                        .cornerRadius(7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
            .frame(width: 175)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.35))

            // Vertical separator
            Divider()

            // MARK: - Main Content Area (Right)
            VStack(alignment: .leading, spacing: 18) {
                // Section Title
                HStack {
                    Text(selectedSection.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }

                // Section Body
                Group {
                    switch selectedSection {
                    case .snapZones:
                        snapZonesContent
                    case .grid:
                        gridContent
                    case .behavior:
                        behaviorContent
                    case .shortcuts:
                        shortcutsContent
                    case .about:
                        aboutContent
                    }
                }

                Spacer(minLength: 0)

                // Footer
                Divider()
                HStack {
                    Text("Wrangler v\(UpdateManager.currentVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 680, height: 440)
    }

    // MARK: - Snap Zones Content
    @ViewBuilder
    private var snapZonesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(
                get: { settings.enableSnapZones },
                set: { settings.enableSnapZones = $0; saveSettings() }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable Drag-to-Snap Zones")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Drag a window by its title bar to screen edges or corners to snap into template tiles.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

            if settings.enableSnapZones {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ultrawide Template Layout:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("", selection: Binding(
                        get: { settings.snapZoneTemplate },
                        set: { settings.snapZoneTemplate = $0; saveSettings() }
                    )) {
                        ForEach(SnapZoneTemplate.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 320, alignment: .leading)
                }

                HStack {
                    Text("Edge Trigger:")
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)

                    Slider(value: Binding(
                        get: { Double(settings.snapTriggerThreshold) },
                        set: { settings.snapTriggerThreshold = CGFloat($0); saveSettings() }
                    ), in: 15...60, step: 5)
                    .frame(maxWidth: 240)

                    Text("\(Int(settings.snapTriggerThreshold)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Grid Content
    @ViewBuilder
    private var gridContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Configure default grid dimensions and spacing for overlay snaps.")
                .font(.callout)
                .foregroundColor(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("Columns:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.columns) },
                        set: { settings.columns = Int($0); saveSettings() }
                    ), in: 2...12, step: 1)
                    .frame(maxWidth: 240)

                    Text("\(settings.columns)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Rows:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.rows) },
                        set: { settings.rows = Int($0); saveSettings() }
                    ), in: 1...8, step: 1)
                    .frame(maxWidth: 240)

                    Text("\(settings.rows)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Inner Gap:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.gap) },
                        set: { settings.gap = CGFloat($0); saveSettings() }
                    ), in: 0...32, step: 2)
                    .frame(maxWidth: 240)

                    Text("\(Int(settings.gap)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Outer Margin:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.outerMargin) },
                        set: { settings.outerMargin = CGFloat($0); saveSettings() }
                    ), in: 0...40, step: 2)
                    .frame(maxWidth: 240)

                    Text("\(Int(settings.outerMargin)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Behavior Content
    @ViewBuilder
    private var behaviorContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(
                get: { settings.avoidStageManager },
                set: { settings.avoidStageManager = $0; saveSettings() }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Avoid macOS Stage Manager strip")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Automatically leaves room on screen edges when Stage Manager thumbnails are visible.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Toggle(isOn: Binding(
                get: { settings.cycleRepeatedSnaps },
                set: { settings.cycleRepeatedSnaps = $0; saveSettings() }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Cycle window sizes on repeated shortcut")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Pressing Left or Right Half repeatedly cycles: ½ → ⅔ → ⅓ → ½.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Shortcuts Content
    @ViewBuilder
    private var shortcutsContent: some View {
        VStack(spacing: 8) {
            ShortcutRow(label: "Show Grid Overlay", shortcut: "⌥ Space")
            ShortcutRow(label: "Maximize Window", shortcut: "⌃ ⌥ ↵  or  ⌃ ⌥ M")
            ShortcutRow(label: "Auto-Tile Active Display", shortcut: "⌃ ⌥ T")
            ShortcutRow(label: "Move to Next Display", shortcut: "⌃ ⌥ →")
            ShortcutRow(label: "Move to Previous Display", shortcut: "⌃ ⌥ ←")
            ShortcutRow(label: "Undo Last Snap", shortcut: "⌥ ⌘ Z")
        }
    }

    // MARK: - About Content
    @ViewBuilder
    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "square.grid.3x3.square")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wrangler")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("The open-source window grid manager for macOS")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack(spacing: 12) {
                Button("Check for Updates...") {
                    Task {
                        await UpdateManager.shared.checkForUpdates(silent: false)
                    }
                }

                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/mezzie/wrangler") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Text("Free and open-source under the MIT License.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func saveSettings() {
        settings.save()
    }
}

private struct ShortcutRow: View {
    let label: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(shortcut)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(5)
        }
    }
}
