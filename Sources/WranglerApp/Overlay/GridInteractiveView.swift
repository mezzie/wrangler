import SwiftUI
import WranglerCore

public struct GridInteractiveView: View {
    @ObservedObject public var model: GridSelectionModel
    public let appName: String?
    public let onUndo: (() -> Void)?

    public init(
        model: GridSelectionModel,
        appName: String? = nil,
        onUndo: (() -> Void)? = nil
    ) {
        self.model = model
        self.appName = appName
        self.onUndo = onUndo
    }

    public var body: some View {
        VStack(spacing: 12) {
            headerBar
            gridMatrix
            presetButtons
        }
        .padding(14)
        .frame(width: 290)
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
            Spacer()
            Button(action: { model.onCancel?() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var gridMatrix: some View {
        GridCanvasRepresentable(model: model)
            .frame(height: 160)
    }

    @ViewBuilder
    private var presetButtons: some View {
        HStack(spacing: 6) {
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

            if let onUndo = onUndo {
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
