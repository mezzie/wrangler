import SwiftUI
import WranglerCore

public struct GridInteractiveView: View {
    @ObservedObject public var model: GridSelectionModel
    public let appName: String?
    public let onUndo: (() -> Void)?
    public let onHopNextScreen: (() -> Void)?
    public let hasMultipleScreens: Bool

    public init(
        model: GridSelectionModel,
        appName: String? = nil,
        onUndo: (() -> Void)? = nil,
        onHopNextScreen: (() -> Void)? = nil,
        hasMultipleScreens: Bool = false
    ) {
        self.model = model
        self.appName = appName
        self.onUndo = onUndo
        self.onHopNextScreen = onHopNextScreen
        self.hasMultipleScreens = hasMultipleScreens
    }

    public var body: some View {
        VStack(spacing: 10) {
            headerBar
            gridControls
            gridMatrix
            presetButtons
        }
        .padding(14)
        .frame(width: 310)
        .background(panelBackground)
    }

    @ViewBuilder
    private var headerBar: some View {
        HStack {
            Image(systemName: "square.grid.3x3.square")
                .foregroundColor(.accentColor)
                .imageScale(.medium)
            Text(appName.map { "Snap: \($0)" } ?? "Wrangler")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            Button(action: { model.onCancel?() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private var gridControls: some View {
        HStack(spacing: 8) {
            // Quick size presets
            HStack(spacing: 4) {
                DimensionPill(title: "2×2", active: model.config.columns == 2 && model.config.rows == 2) {
                    model.setDimensions(cols: 2, rows: 2)
                }
                DimensionPill(title: "3×3", active: model.config.columns == 3 && model.config.rows == 3) {
                    model.setDimensions(cols: 3, rows: 3)
                }
                DimensionPill(title: "4×4", active: model.config.columns == 4 && model.config.rows == 4) {
                    model.setDimensions(cols: 4, rows: 4)
                }
                DimensionPill(title: "6×4", active: model.config.columns == 6 && model.config.rows == 4) {
                    model.setDimensions(cols: 6, rows: 4)
                }
            }

            Spacer()

            // Fine-tune stepper
            HStack(spacing: 3) {
                Text("\(model.config.columns)×\(model.config.rows)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)

                Button(action: { model.adjustColumns(delta: -1) }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(model.config.columns <= 2)

                Button(action: { model.adjustColumns(delta: 1) }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(model.config.columns >= 12)
            }
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private var gridMatrix: some View {
        GridCanvasRepresentable(model: model)
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
    }

    @ViewBuilder
    private var presetButtons: some View {
        HStack(spacing: 5) {
            QuickPresetButton(title: "Left ½", systemImage: "rectangle.leadinghalf.filled") {
                if let layout = NamedLayout.standardPresets.first(where: { $0.id == "left-half" }) {
                    model.commitPreset(layout)
                }
            }

            QuickPresetButton(title: "Right ½", systemImage: "rectangle.trailinghalf.filled") {
                if let layout = NamedLayout.standardPresets.first(where: { $0.id == "right-half" }) {
                    model.commitPreset(layout)
                }
            }

            QuickPresetButton(title: "Max", systemImage: "arrow.up.left.and.arrow.down.right") {
                if let layout = NamedLayout.standardPresets.first(where: { $0.id == "full" }) {
                    model.commitPreset(layout)
                }
            }

            QuickPresetButton(title: "Center", systemImage: "circle.center.radial") {
                if let layout = NamedLayout.standardPresets.first(where: { $0.id == "center" }) {
                    model.commitPreset(layout)
                }
            }

            if hasMultipleScreens, let onHop = onHopNextScreen {
                QuickPresetButton(title: "Next Screen", systemImage: "display.2") {
                    onHop()
                }
            } else if let onUndo = onUndo {
                QuickPresetButton(title: "Undo", systemImage: "arrow.uturn.backward") {
                    onUndo()
                }
            }
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 12)
    }
}

private struct DimensionPill: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: active ? .semibold : .regular))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(active ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
                .foregroundColor(active ? .accentColor : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

private struct QuickPresetButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 9, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
