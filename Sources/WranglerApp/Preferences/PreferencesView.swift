import SwiftUI
import WranglerCore

public struct PreferencesView: View {
    @State private var settings = AppSettings.load()

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                gridSection
                behaviorSection
                shortcutsSection
            }
            .padding(20)
        }
        .frame(width: 480, height: 530)
    }

    // MARK: - Grid & Spacing Card
    @ViewBuilder
    private var gridSection: some View {
        GroupBox(label: Label("Grid & Spacing", systemImage: "square.grid.3x3")) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("Columns:")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .gridColumnAlignment(.trailing)
                        .frame(width: 90, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.columns) },
                        set: { settings.columns = Int($0); saveSettings() }
                    ), in: 2...12, step: 1)

                    Text("\(settings.columns)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Rows:")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.rows) },
                        set: { settings.rows = Int($0); saveSettings() }
                    ), in: 1...8, step: 1)

                    Text("\(settings.rows)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Inner Gap:")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.gap) },
                        set: { settings.gap = CGFloat($0); saveSettings() }
                    ), in: 0...32, step: 2)

                    Text("\(Int(settings.gap)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Outer Margin:")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.outerMargin) },
                        set: { settings.outerMargin = CGFloat($0); saveSettings() }
                    ), in: 0...40, step: 2)

                    Text("\(Int(settings.outerMargin)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
        }
    }

    // MARK: - Behavior Card
    @ViewBuilder
    private var behaviorSection: some View {
        GroupBox(label: Label("Window Behavior", systemImage: "gearshape")) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: Binding(
                    get: { settings.avoidStageManager },
                    set: { settings.avoidStageManager = $0; saveSettings() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avoid Stage Manager strip")
                            .font(.body)
                        Text("Leaves space on screen edges when Stage Manager thumbnails are visible")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                Toggle(isOn: Binding(
                    get: { settings.cycleRepeatedSnaps },
                    set: { settings.cycleRepeatedSnaps = $0; saveSettings() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cycle window sizes on repeat")
                            .font(.body)
                        Text("Pressing Left or Right Half repeatedly cycles: ½ → ⅔ → ⅓ → ½")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
        }
    }

    // MARK: - Shortcuts Card
    @ViewBuilder
    private var shortcutsSection: some View {
        GroupBox(label: Label("Keyboard Shortcuts", systemImage: "keyboard")) {
            VStack(spacing: 8) {
                ShortcutRow(label: "Show Grid Overlay", shortcut: "⌥ Space")
                ShortcutRow(label: "Maximize Window", shortcut: "⌃ ⌥ ↵  or  ⌃ ⌥ M")
                ShortcutRow(label: "Auto-Tile Active Display", shortcut: "⌃ ⌥ T")
                ShortcutRow(label: "Move to Next Display", shortcut: "⌃ ⌥ →")
                ShortcutRow(label: "Move to Previous Display", shortcut: "⌃ ⌥ ←")
                ShortcutRow(label: "Undo Last Snap", shortcut: "⌥ ⌘ Z")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
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
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(5)
        }
    }
}
