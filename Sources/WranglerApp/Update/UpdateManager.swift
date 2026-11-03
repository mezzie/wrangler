import AppKit
import Foundation

public struct GitHubRelease: Codable, Sendable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case assets
    }
}

public struct GitHubAsset: Codable, Sendable {
    public let name: String
    public let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

@MainActor
public final class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()

    public static let currentVersion = "1.9.1"

    @Published public var availableUpdate: GitHubRelease?
    @Published public var isChecking = false
    @Published public var isDownloading = false

    private init() {}

    /// Compares two semantic version strings (e.g. "1.3.1" vs "1.3.0")
    public static func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        let clean1 = v1.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let clean2 = v2.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

        let parts1 = clean1.split(separator: ".").compactMap { Int($0) }
        let parts2 = clean2.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }

    /// Checks GitHub API for newer releases
    public func checkForUpdates(silent: Bool = false) async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        guard let url = URL(string: "https://api.github.com/repos/mezzie/wrangler/releases/latest") else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Wrangler-UpdateChecker", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if !silent {
                    showErrorAlert("Unable to check for updates. GitHub API returned error.")
                }
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            if Self.isVersion(release.tagName, newerThan: Self.currentVersion) {
                self.availableUpdate = release
                promptUpdateAvailable(release)
            } else if !silent {
                showUpToDateAlert()
            }
        } catch {
            if !silent {
                showErrorAlert("Failed to check for updates: \(error.localizedDescription)")
            }
        }
    }

    private func promptUpdateAvailable(_ release: GitHubRelease) {
        let alert = NSAlert()
        alert.messageText = "Wrangler Update Available"
        alert.informativeText = "A new version of Wrangler (\(release.tagName)) is available!\n(Currently running: v\(Self.currentVersion))\n\nWould you like to update and restart now?"
        alert.alertStyle = .informational

        alert.addButton(withTitle: "Update and Restart")
        alert.addButton(withTitle: "Release Notes")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            if let dmgAsset = release.assets.first(where: { $0.name.hasSuffix(".dmg") }) {
                startDownloadAndInstall(asset: dmgAsset, version: release.tagName)
            } else if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        case .alertSecondButtonReturn:
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        default:
            break
        }
    }

    private func startDownloadAndInstall(asset: GitHubAsset, version: String) {
        guard let downloadUrl = URL(string: asset.browserDownloadUrl) else { return }

        isDownloading = true

        let progressAlert = NSAlert()
        progressAlert.messageText = "Updating Wrangler..."
        progressAlert.informativeText = "Downloading Wrangler \(version). The app will restart automatically in a few seconds."
        progressAlert.addButton(withTitle: "Cancel")

        Task {
            do {
                let (tempUrl, _) = try await URLSession.shared.download(from: downloadUrl)
                let destinationPath = "/tmp/Wrangler-Update.dmg"
                try? FileManager.default.removeItem(atPath: destinationPath)
                try FileManager.default.moveItem(at: tempUrl, to: URL(fileURLWithPath: destinationPath))

                executeInstallerScript(dmgPath: destinationPath)
            } catch {
                isDownloading = false
                showErrorAlert("Download failed: \(error.localizedDescription)")
            }
        }
    }

    private func executeInstallerScript(dmgPath: String) {
        let script = """
        #!/usr/bin/env bash
        sleep 1
        MOUNT_DIR="/tmp/Wrangler_Update_Mount"
        rm -rf "${MOUNT_DIR}"
        mkdir -p "${MOUNT_DIR}"
        hdiutil attach -nobrowse -readonly "\(dmgPath)" -mountpoint "${MOUNT_DIR}"
        if [ -d "${MOUNT_DIR}/Wrangler.app" ]; then
            rm -rf /Applications/Wrangler.app
            cp -R "${MOUNT_DIR}/Wrangler.app" /Applications/Wrangler.app
        fi
        hdiutil detach "${MOUNT_DIR}" || true
        rm -rf "${MOUNT_DIR}" "\(dmgPath)" "/tmp/wrangler_installer.sh"
        open -n /Applications/Wrangler.app
        """

        let scriptPath = "/tmp/wrangler_installer.sh"
        do {
            try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath]
            try process.run()

            // Quit current running version so updated app can take over
            NSApplication.shared.terminate(nil)
        } catch {
            showErrorAlert("Could not start installer process: \(error.localizedDescription)")
        }
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date!"
        alert.informativeText = "Wrangler v\(Self.currentVersion) is currently the newest version available."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
