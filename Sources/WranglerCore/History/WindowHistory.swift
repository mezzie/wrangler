import Foundation

public struct WindowHistoryEntry: Equatable, Sendable {
    public let pid: pid_t
    public let frame: CGRect
    public let timestamp: Date

    public init(pid: pid_t, frame: CGRect, timestamp: Date = Date()) {
        self.pid = pid
        self.frame = frame
        self.timestamp = timestamp
    }
}

public final class WindowHistory: @unchecked Sendable {
    private let lock = NSLock()
    private var historyByPID: [pid_t: [WindowHistoryEntry]] = [:]
    public let maxEntriesPerWindow: Int

    public init(maxEntriesPerWindow: Int = 10) {
        self.maxEntriesPerWindow = max(1, maxEntriesPerWindow)
    }

    /// Records current frame before applying new layout
    public func push(pid: pid_t, frame: CGRect) {
        lock.lock()
        defer { lock.unlock() }

        var list = historyByPID[pid] ?? []
        // Don't duplicate if unchanged from top
        if let top = list.last, top.frame == frame {
            return
        }
        list.append(WindowHistoryEntry(pid: pid, frame: frame))
        if list.count > maxEntriesPerWindow {
            list.removeFirst(list.count - maxEntriesPerWindow)
        }
        historyByPID[pid] = list
    }

    /// Retrieves and removes the most recent previous frame for a window
    public func pop(pid: pid_t) -> CGRect? {
        lock.lock()
        defer { lock.unlock() }

        guard var list = historyByPID[pid], !list.isEmpty else {
            return nil
        }
        let last = list.removeLast()
        historyByPID[pid] = list
        return last.frame
    }

    /// Peeks at prior frame without popping
    public func peek(pid: pid_t) -> CGRect? {
        lock.lock()
        defer { lock.unlock() }
        return historyByPID[pid]?.last?.frame
    }

    /// Clears history for a specific process (e.g. on app terminate)
    public func clear(pid: pid_t) {
        lock.lock()
        defer { lock.unlock() }
        historyByPID.removeValue(forKey: pid)
    }

    /// Clears all stored histories
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        historyByPID.removeAll()
    }
}
