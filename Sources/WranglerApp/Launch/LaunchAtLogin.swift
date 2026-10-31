import Foundation
import ServiceManagement

@MainActor
public enum LaunchAtLogin {
    public static var isEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }

    public static func setEnabled(_ enable: Bool) {
        do {
            if enable {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to update Launch at Login status: \(error.localizedDescription)")
        }
    }
}
