import SwiftUI
import WranglerCore

public enum PrefsSection: String, CaseIterable, Identifiable {
    case snapZones = "Snap Zones"
    case grid = "Grid & Gaps"
    case workspaces = "Workspaces"
    case behavior = "Behavior"
    case shortcuts = "Shortcuts"
    case about = "About & Updates"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .snapZones: return "rectangle.split.2x1"
        case .grid: return "square.grid.3x3"
        case .workspaces: return "macwindow.on.rectangle"
        case .behavior: return "gearshape"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }
}

public struct PreferencesView: View {
    @State private var settings = AppSettings.load()
    @State private var selectedSection: PrefsSection = .snapZones
    @State private var recordingKey: String? = nil
    @State private var keyMonitor: Any? = nil
    @State private var launchAtLogin: Bool = false
    @State private var newWorkspaceName: String = ""

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Navigation Sidebar
            VStack(alignment: .leading, spacing: 4) {
                ForEach(PrefsSection.allCases) { section in
                    Button(action: {
                        stopRecording()
                        selectedSection = section
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedSection == section ? .accentColor : .secondary)
                                .frame(width: 18, alignment: .center)

                            Text(section.rawValue)
                                .font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))
                                .foregroundColor(selectedSection == section ? .primary : .secondary)

                            Spacer()
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(
                            selectedSection == section
                                ? Color.accentColor.opacity(0.12)
                                : Color.clear
                        )
                        .cornerRadius(7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
            .frame(width: 175)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.35))

            // Vertical separator
            Divider()

            // MARK: - Main Content Area (Right)
            VStack(alignment: .leading, spacing: 18) {
                // Section Title & Top Controls
                HStack {
                    Text(selectedSection.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }

                // Section Body
                Group {
                    switch selectedSection {
                    case .snapZones:
                        snapZonesContent
                    case .grid:
                        gridContent
                    case .workspaces:
                        workspacesContent
                    case .behavior:
                        behaviorContent
                    case .shortcuts:
                        shortcutsContent
                    case .about:
                        aboutContent
                    }
                }

                Spacer(minLength: 0)

                // Footer Bar with Restore Defaults per Tab
                Divider()
                HStack {
                    Text("Wrangler v\(UpdateManager.currentVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if selectedSection != .about && selectedSection != .workspaces {
                        Button("Restore Defaults") {
                            restoreCurrentTabDefaults()
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 710, height: 490)
        .onAppear {
            launchAtLogin = LaunchAtLogin.isEnabled
        }
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - Tab 1: Snap Zones Content
    @ViewBuilder
    private var snapZonesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: Binding(
                get: { settings.enableSnapZones },
                set: { settings.enableSnapZones = $0; saveSettings() }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable Drag-to-Snap Zones")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Drag a window by its title bar to screen edges or corners to snap into template tiles.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

            if settings.enableSnapZones {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ultrawide Template Layout:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("", selection: Binding(
                        get: { settings.snapZoneTemplate },
                        set: { settings.snapZoneTemplate = $0; saveSettings() }
                    )) {
                        ForEach(SnapZoneTemplate.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 320, alignment: .leading)
                }

                HStack {
                    Text("Edge Trigger:")
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)

                    Slider(value: Binding(
                        get: { Double(settings.snapTriggerThreshold) },
                        set: { settings.snapTriggerThreshold = CGFloat($0); saveSettings() }
                    ), in: 15...60, step: 5)
                    .frame(maxWidth: 240)

                    Text("\(Int(settings.snapTriggerThreshold)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50, alignment: .leading)
                }

                Toggle(isOn: Binding(
                    get: { settings.modifierHoldSnap },
                    set: { settings.modifierHoldSnap = $0; saveSettings() }
                )) {
                    Text("Hold Control or fn key while dragging window to reveal zones anywhere")
                        .font(.callout)
                }
            }
        }
    }

    // MARK: - Tab 2: Grid Content
    @ViewBuilder
    private var gridContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Configure default grid dimensions and spacing for overlay snaps.")
                .font(.callout)
                .foregroundColor(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("Columns:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.columns) },
                        set: { settings.columns = Int($0); saveSettings() }
                    ), in: 2...12, step: 1)
                    .frame(maxWidth: 240)

                    Text("\(settings.columns)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Rows:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.rows) },
                        set: { settings.rows = Int($0); saveSettings() }
                    ), in: 1...8, step: 1)
                    .frame(maxWidth: 240)

                    Text("\(settings.rows)")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Inner Gap:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.gap) },
                        set: { settings.gap = CGFloat($0); saveSettings() }
                    ), in: 0...32, step: 2)
                    .frame(maxWidth: 240)

                    Text("\(Int(settings.gap)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }

                GridRow {
                    Text("Outer Margin:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 95, alignment: .trailing)

                    Slider(value: Binding(
                        get: { Double(settings.outerMargin) },
                        set: { settings.outerMargin = CGFloat($0); saveSettings() }
                    ), in: 0...40, step: 2)
                    .frame(maxWidth: 240)

                    Text("\(Int(settings.outerMargin)) px")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 45, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Tab 3: Workspaces (Profiles) Content
    @ViewBuilder
    private var workspacesContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Save your current desktop window layout as a profile and restore it anytime.")
                .font(.callout)
                .foregroundColor(.secondary)

            HStack {
                TextField("Workspace Name (e.g. Coding, Research)", text: $newWorkspaceName)
                    .textFieldStyle(.roundedBorder)

                Button("Save Current Setup") {
                    let name = newWorkspaceName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalName = name.isEmpty ? "Workspace \(settings.savedWorkspaces.count + 1)" : name
                    WindowManagerCoordinator.shared.saveCurrentWorkspace(name: finalName)
                    settings = AppSettings.load()
                    newWorkspaceName = ""
                }
                .buttonStyle(.borderedProminent)
            }

            // Live detected windows badge preview
            let detected = WindowManagerCoordinator.shared.getDetectedOnScreenWindows()
            if !detected.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently Visible on Display (\(detected.count)):")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(0..<detected.count, id: \.self) { i in
                                let target = detected[i].target
                                Text(target.appName ?? "App")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.12))
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
            }

            Divider()

            if settings.savedWorkspaces.isEmpty {
                Text("No saved workspaces yet. Arrange your windows on screen and click 'Save Current Setup'.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(settings.savedWorkspaces) { ws in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ws.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(ws.slots.map(\.appName).joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button("Restore") {
                                    WindowManagerCoordinator.shared.restoreWorkspace(id: ws.id)
                                }
                                .buttonStyle(.bordered)

                                Button(action: {
                                    settings.savedWorkspaces.removeAll { $0.id == ws.id }
                                    saveSettings()
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
    }

    // MARK: - Tab 4: Behavior Content
    @ViewBuilder
    private var behaviorContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $launchAtLogin) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Launch Wrangler at login")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Starts Wrangler automatically in the background when you log in.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: launchAtLogin) { newValue in
                LaunchAtLogin.setEnabled(newValue)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    launchAtLogin = LaunchAtLogin.isEnabled
                }
            }

            Divider()

            Toggle(isOn: Binding(
                get: { settings.avoidStageManager },
                set: { settings.avoidStageManager = $0; saveSettings() }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avoid macOS Stage Manager strip")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Automatically leaves room on screen edges when Stage Manager thumbnails are visible.")
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
                    Text("Cycle window sizes on repeated shortcut")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Pressing Left or Right Half repeatedly cycles: ½ → ⅔ → ⅓ → ½.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Toggle(isOn: Binding(
                get: { settings.animateWindowSnapping },
                set: { settings.animateWindowSnapping = $0; saveSettings() }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smooth window animation")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Glides windows into position with smooth 60fps ease-out animation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Toggle(isOn: Binding(
                get: { settings.shakeToSummon },
                set: { settings.shakeToSummon = $0; saveSettings() }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shake cursor to summon grid HUD")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Quickly shaking your mouse cursor activates the grid overlay at cursor location.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("App Language:")
                    .font(.body)
                    .fontWeight(.medium)

                HStack {
                    Picker("", selection: Binding(
                        get: { settings.appLanguage },
                        set: {
                            settings.appLanguage = $0
                            saveSettings()
                            applyLanguagePreference($0)
                        }
                    )) {
                        Text("System Default").tag("system")
                        Text("English").tag("en")
                        Text("日本語 (Japanese)").tag("ja")
                        Text("简体中文 (Simplified Chinese)").tag("zh-Hans")
                        Text("Deutsch (German)").tag("de")
                        Text("Español (Spanish)").tag("es")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 220, alignment: .leading)

                    Text("Takes effect on restart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Ignored Applications:")
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                    Menu {
                        let running = NSWorkspace.shared.runningApplications
                            .filter { $0.activationPolicy == .regular && !settings.ignoredBundleIDs.contains($0.bundleIdentifier ?? "") }
                        ForEach(running, id: \.processIdentifier) { app in
                            if let bid = app.bundleIdentifier, let name = app.localizedName {
                                Button(name) {
                                    settings.ignoredBundleIDs.append(bid)
                                    saveSettings()
                                }
                            }
                        }
                    } label: {
                        Text("+ Add Running App")
                            .font(.caption)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 130)
                }

                Text("Auto-Tile and Snap will ignore these applications.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(settings.ignoredBundleIDs, id: \.self) { bid in
                            HStack(spacing: 4) {
                                Text(bid.components(separatedBy: ".").last?.capitalized ?? bid)
                                    .font(.system(.caption, design: .monospaced))
                                Button(action: {
                                    settings.ignoredBundleIDs.removeAll { $0 == bid }
                                    saveSettings()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.08))
                            .cornerRadius(5)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tab 5: Shortcuts Content with Interactive Recording
    @ViewBuilder
    private var shortcutsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Click any shortcut badge to record your own custom keys. Press ESC to cancel.")
                .font(.callout)
                .foregroundColor(.secondary)

            VStack(spacing: 7) {
                recorderRow(id: "overlay", label: "Show Grid Overlay", shortcut: settings.overlayShortcut)
                recorderRow(id: "maximize", label: "Maximize Window", shortcut: settings.maximizeShortcut)
                recorderRow(id: "autoTile", label: "Auto-Tile Active Display", shortcut: settings.autoTileShortcut)
                recorderRow(id: "swap", label: "Swap Front Windows", shortcut: settings.swapShortcut)
                recorderRow(id: "nextDisplay", label: "Move to Next Display", shortcut: settings.nextDisplayShortcut)
                recorderRow(id: "prevDisplay", label: "Move to Previous Display", shortcut: settings.prevDisplayShortcut)
                recorderRow(id: "undo", label: "Undo Last Snap", shortcut: settings.undoShortcut)

                staticShortcutRow(label: "Focus Window Left / Right", shortcut: "⌃ ⌥ H  /  ⌃ ⌥ L")
                staticShortcutRow(label: "Focus Window Up / Down", shortcut: "⌃ ⌥ K  /  ⌃ ⌥ J")
                staticShortcutRow(label: "Cycle Same-App Windows", shortcut: "⌃ ⌥ `")
            }

            Divider()

            Toggle(isOn: Binding(
                get: { settings.enableNumpadHotkeys },
                set: {
                    settings.enableNumpadHotkeys = $0
                    saveSettings()
                    GlobalHotKeyManager.shared.registerFromSettings(settings)
                }
            )) {
                Text("Enable Numpad 1–9 shortcuts (⌃ ⌥ Numpad 1..9 for spatial snapping)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func staticShortcutRow(label: String, shortcut: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(shortcut)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(5)
        }
    }

    @ViewBuilder
    private func recorderRow(id: String, label: String, shortcut: CustomShortcut) -> some View {
        let isRecording = (recordingKey == id)

        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording(id)
                }
            }) {
                HStack(spacing: 4) {
                    if isRecording {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("Type keys...")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    } else {
                        Text(shortcut.displayString)
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isRecording
                        ? Color.accentColor.opacity(0.18)
                        : Color.primary.opacity(0.08)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tab 6: About Content
    @ViewBuilder
    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wrangler")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("The open-source window grid manager for macOS")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack(spacing: 12) {
                Button("Check for Updates...") {
                    Task {
                        await UpdateManager.shared.checkForUpdates(silent: false)
                    }
                }

                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/mezzie/wrangler") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Text("Free and open-source under the MIT License.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Logic & Key Recording

    private func saveSettings() {
        settings.save()
    }

    private func applyLanguagePreference(_ lang: String) {
        if lang == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        }
    }

    private func restoreCurrentTabDefaults() {
        switch selectedSection {
        case .snapZones:
            settings.resetSnapZones()
        case .grid:
            settings.resetGridAndGaps()
        case .behavior:
            settings.resetBehavior()
        case .shortcuts:
            settings.resetShortcuts()
            GlobalHotKeyManager.shared.registerFromSettings(settings)
        case .workspaces, .about:
            break
        }
        saveSettings()
    }

    private func startRecording(_ key: String) {
        stopRecording()
        recordingKey = key

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // ESC key cancels recording
            if event.keyCode == 53 {
                self.stopRecording()
                return nil
            }

            if let shortcut = CustomShortcut.from(event: event) {
                switch key {
                case "overlay":
                    self.settings.overlayShortcut = shortcut
                case "maximize":
                    self.settings.maximizeShortcut = shortcut
                case "autoTile":
                    self.settings.autoTileShortcut = shortcut
                case "swap":
                    self.settings.swapShortcut = shortcut
                case "nextDisplay":
                    self.settings.nextDisplayShortcut = shortcut
                case "prevDisplay":
                    self.settings.prevDisplayShortcut = shortcut
                case "undo":
                    self.settings.undoShortcut = shortcut
                default:
                    break
                }
                self.saveSettings()
                GlobalHotKeyManager.shared.registerFromSettings(self.settings)
                self.stopRecording()
                return nil
            }
            return event
        }
    }

    private func stopRecording() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        recordingKey = nil
    }
}
