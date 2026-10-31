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
        GeometryReader { geo in
            let cols = CGFloat(model.config.columns)
            let rows = CGFloat(model.config.rows)
            let cellWidth = max(8, (geo.size.width - (cols - 1) * 4) / cols)
            let cellHeight = max(8, (geo.size.height - (rows - 1) * 4) / rows)

            VStack(spacing: 4) {
                ForEach(0..<model.config.rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<model.config.columns, id: \.self) { col in
                            cellView(col: col, row: row, width: cellWidth, height: cellHeight)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(size: geo.size))
        }
        .frame(height: 160)
    }

    @ViewBuilder
    private func cellView(col: Int, row: Int, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = model.isCellSelected(col: col, row: row)
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isSelected ? Color.white.opacity(0.4) : Color.primary.opacity(0.12), lineWidth: 1)
            )
            .frame(width: width, height: height)
    }

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let loc = value.location
                guard size.width > 0, size.height > 0 else { return }

                let col = max(0, min(model.config.columns - 1, Int(loc.x / (size.width / CGFloat(model.config.columns)))))
                let row = max(0, min(model.config.rows - 1, Int(loc.y / (size.height / CGFloat(model.config.rows)))))

                if model.dragStart == nil {
                    model.dragBegan(col: col, row: row)
                } else {
                    model.cellHovered(col: col, row: row)
                }
            }
            .onEnded { _ in
                model.dragEnded()
            }
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
