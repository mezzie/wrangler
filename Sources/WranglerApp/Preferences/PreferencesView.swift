import SwiftUI
import WranglerCore

public struct PreferencesView: View {
    @State private var settings = AppSettings.load()

    public init() {}

    public var body: some View {
        Form {
            Section(header: Text("Grid & Spacing").font(.headline)) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Columns:")
                            .frame(width: 100, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(settings.columns) },
                            set: { settings.columns = Int($0); saveSettings() }
                        ), in: 2...12, step: 1)
                        Text("\(settings.columns)")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 30)
                    }

                    HStack {
                        Text("Rows:")
                            .frame(width: 100, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(settings.rows) },
                            set: { settings.rows = Int($0); saveSettings() }
                        ), in: 1...8, step: 1)
                        Text("\(settings.rows)")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 30)
                    }

                    HStack {
                        Text("Inner Gap:")
                            .frame(width: 100, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(settings.gap) },
                            set: { settings.gap = CGFloat($0); saveSettings() }
                        ), in: 0...32, step: 2)
                        Text("\(Int(settings.gap)) px")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 50)
                    }

                    HStack {
                        Text("Outer Margin:")
                            .frame(width: 100, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(settings.outerMargin) },
                            set: { settings.outerMargin = CGFloat($0); saveSettings() }
                        ), in: 0...40, step: 2)
                        Text("\(Int(settings.outerMargin)) px")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 50)
                    }
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Behavior").font(.headline)) {
                Toggle("Avoid macOS Stage Manager strip", isOn: Binding(
                    get: { settings.avoidStageManager },
                    set: { settings.avoidStageManager = $0; saveSettings() }
                ))
                .help("Leaves room on the left/right screen edge when Stage Manager thumbnails are visible")

                Toggle("Cycle window sizes on repeated press (½ → ⅔ → ⅓)", isOn: Binding(
                    get: { settings.cycleRepeatedSnaps },
                    set: { settings.cycleRepeatedSnaps = $0; saveSettings() }
                ))
                .help("Pressing Left or Right Half again within 1.5s cycles through halves and thirds")
            }

            Section(header: Text("Keyboard Shortcuts").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    ShortcutRow(label: "Show Grid Overlay", shortcut: "⌥ Space")
                    ShortcutRow(label: "Move to Next Display", shortcut: "⌃ ⌥ →")
                    ShortcutRow(label: "Move to Previous Display", shortcut: "⌃ ⌥ ←")
                    ShortcutRow(label: "Undo Last Snap", shortcut: "⌥ ⌘ Z")
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(width: 440, height: 420)
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
                .foregroundColor(.primary)
            Spacer()
            Text(shortcut)
                .font(.system(.subheadline, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(4)
        }
    }
}
