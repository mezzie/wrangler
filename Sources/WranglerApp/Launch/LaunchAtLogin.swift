import Foundation
import ServiceManagement

@MainActor
public enum LaunchAtLogin {
    public static var isEnabled: Bool {
        let status = SMAppService.mainApp.status
        return status == .enabled || status == .requiresApproval
    }

    public static func setEnabled(_ enable: Bool) {
        do {
            if enable {
                let status = SMAppService.mainApp.status
                if status != .enabled && status != .requiresApproval {
                    try SMAppService.mainApp.register()
                }
            } else {
                let status = SMAppService.mainApp.status
                if status == .enabled || status == .requiresApproval {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to update Launch at Login status: \(error.localizedDescription)")
        }
    }
}
