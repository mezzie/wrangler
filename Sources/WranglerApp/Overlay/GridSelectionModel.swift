import Foundation
import SwiftUI
import WranglerCore

public final class GridSelectionModel: ObservableObject {
    @Published public var config: GridConfig
    @Published public var dragStart: GridCellIndex?
    @Published public var currentHover: GridCellIndex?
    @Published public var selectedPreset: String?

    public var onSelectionChanged: ((GridSelection) -> Void)?
    public var onSelectionCommitted: ((GridSelection) -> Void)?
    public var onCancel: (() -> Void)?

    public init(config: GridConfig = .default4x4) {
        self.config = config
    }

    public var currentSelection: GridSelection? {
        if let start = dragStart, let hover = currentHover {
            return GridSelection(start: start, end: hover)
        } else if let hover = currentHover {
            return GridSelection(single: hover)
        }
        return nil
    }

    public func cellHovered(col: Int, row: Int) {
        let cell = GridCellIndex(col: col, row: row)
        currentHover = cell
        if let selection = currentSelection {
            onSelectionChanged?(selection)
        }
    }

    public func dragBegan(col: Int, row: Int) {
        let cell = GridCellIndex(col: col, row: row)
        dragStart = cell
        currentHover = cell
        if let selection = currentSelection {
            onSelectionChanged?(selection)
        }
    }

    public func dragEnded() {
        if let selection = currentSelection {
            onSelectionCommitted?(selection)
        }
        reset()
    }

    public func commitPreset(_ layout: NamedLayout) {
        self.config = layout.config
        self.selectedPreset = layout.id
        onSelectionChanged?(layout.selection)
        onSelectionCommitted?(layout.selection)
        reset()
    }

    public func isCellSelected(col: Int, row: Int) -> Bool {
        guard let selection = currentSelection else { return false }
        return col >= selection.minCol && col <= selection.maxCol &&
               row >= selection.minRow && row <= selection.maxRow
    }

    public func reset() {
        dragStart = nil
        currentHover = nil
    }
}
