import AppKit
import Combine
import ServiceManagement
import Darwin

final class HippocampusModel: ObservableObject {
    @Published var captures: [Capture] = []
    @Published var message: String?
    @Published var problem: String?
    @Published var folderDescription = "桌面"
    @Published var clipboardEnabled: Bool = UserDefaults.standard.object(forKey: "clipboardEnabled") as? Bool ?? true
    @Published var paused = false
    @Published var loginEnabled = SMAppService.mainApp.status == .enabled
    @Published var selected: Capture?
    let root: URL
    private let queue = DispatchQueue(label: "local.hippocampus.library", qos: .utility, autoreleaseFrequency: .workItem)
    private var library: CaptureLibrary?
    private var timer: DispatchSourceTimer?
    private var clipboardTimer: Timer?
    private var seen: [String: String] = [:]
    private var pasteboardCount = NSPasteboard.general.changeCount
    private var scanNumber = 0
    private let launched = Date()
    private let demoMode: Bool
    var openWindow: (() -> Void)?
    var closePopover: (() -> Void)?
    var openSettings: (() -> Void)?

    init() {
        let environment = ProcessInfo.processInfo.environment
        root = environment["HIPPOCAMPUS_DATA_DIR"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Hippocampus/Captures")
        demoMode = environment["HIPPOCAMPUS_TEST_MODE"] == "1"
        queue.async { [self] in
            do {
                let loaded = try CaptureLibrary(root: root)
                library = loaded
                publish()
                if !demoMode {
                    scan(initial: true)
                    let timer = DispatchSource.makeTimerSource(queue: queue)
                    timer.schedule(deadline: .now() + 0.8, repeating: 0.8, leeway: .milliseconds(100))
                    timer.setEventHandler { [weak self] in self?.scan(initial: false) }
                    timer.resume(); self.timer = timer
                }
            } catch { showProblem(error.localizedDescription) }
        }
        if !demoMode {
            clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in self?.checkClipboard() }
        }
    }

    func url(for capture: Capture) -> URL { root.appendingPathComponent(capture.filename) }

    private func publish() {
        let value = library?.captures ?? []
        DispatchQueue.main.async { [weak self] in self?.captures = value }
    }

    func notify(_ text: String) {
        message = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.message == text { self?.message = nil }
        }
    }

    private func showProblem(_ text: String) { DispatchQueue.main.async { [weak self] in self?.problem = text } }

    func setClipboard(_ value: Bool) {
        clipboardEnabled = value
        UserDefaults.standard.set(value, forKey: "clipboardEnabled")
        pasteboardCount = NSPasteboard.general.changeCount
    }

    func setPaused(_ value: Bool) {
        paused = value
        pasteboardCount = NSPasteboard.general.changeCount
        queue.async { [weak self] in
            // Baseline files on resume, so paused captures are not imported later.
            self?.scan(initial: false, baselineOnly: true)
        }
    }

    func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginEnabled = SMAppService.mainApp.status == .enabled
            if SMAppService.mainApp.status == .requiresApproval { notify("请在系统设置 → 登录项中允许 Hippocampus。") }
        } catch { problem = "开机启动设置失败：\(error.localizedDescription)" }
    }

    func chooseFolder() {
        closePopover?()
        let panel = NSOpenPanel()
        panel.title = "选择额外的截图文件夹"
        panel.message = "Hippocampus 会继续监测系统截图位置，并收纳这个文件夹中的截图。"
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url.path, forKey: "extraFolder")
            queue.async { [weak self] in self?.scan(initial: true) }
        }
    }

    func importImages() {
        closePopover?()
        let panel = NSOpenPanel()
        panel.title = "收纳图片"
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic]
        panel.allowsMultipleSelection = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        ingestURLs(panel.urls)
    }

    func ingestURLs(_ urls: [URL]) {
        queue.async { [self] in
            for url in urls {
                do {
                    let data = try Data(contentsOf: url)
                    guard let library else { throw LibraryError.invalidManifest }
                    try library.insert(data: data, origin: "manual:\(UUID())", source: "手动收纳")
                } catch { showProblem(error.localizedDescription) }
            }
            publish()
        }
    }

    func copy(_ capture: Capture) {
        do {
            let data = try Data(contentsOf: url(for: capture))
            guard let image = NSImage(data: data), let tiff = image.tiffRepresentation else { throw LibraryError.invalidImage }
            let pb = NSPasteboard.general
            let item = NSPasteboardItem()
            item.setData(data, forType: .png); item.setData(tiff, forType: .tiff)
            item.setString("local.hippocampus.app", forType: NSPasteboard.PasteboardType("org.nspasteboard.source"))
            item.setString(capture.id.uuidString, forType: NSPasteboard.PasteboardType("local.hippocampus.internal"))
            pb.clearContents()
            guard pb.writeObjects([item]) else { throw LibraryError.invalidImage }
            pasteboardCount = pb.changeCount
            notify("已复制图片 · 可以直接 ⌘V 粘贴")
        } catch { problem = error.localizedDescription }
    }

    func delete(_ capture: Capture) {
        queue.async { [self] in
            do { try library?.remove(id: capture.id); publish() }
            catch { showProblem(error.localizedDescription) }
        }
        if selected?.id == capture.id { selected = nil }
    }

    func export(_ capture: Capture) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = capture.filename
        panel.allowedContentTypes = [.png]
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let destination = panel.url {
            do { try Data(contentsOf: url(for: capture)).write(to: destination, options: .atomic); notify("已导出") }
            catch { problem = error.localizedDescription }
        }
    }

    func revealLibrary() { NSWorkspace.shared.open(root) }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != pasteboardCount else { return }
        pasteboardCount = pb.changeCount
        guard clipboardEnabled, !paused,
              pb.data(forType: NSPasteboard.PasteboardType("local.hippocampus.internal")) == nil,
              let data = pb.data(forType: .png) ?? pb.data(forType: .tiff) else { return }
        let date = Date()
        let origin = "clipboard:\(pasteboardCount)"
        queue.async { [self] in
            do { try library?.insert(data: data, date: date, origin: origin, source: "剪贴板"); publish() }
            catch { showProblem(error.localizedDescription) }
        }
    }

    private func screenshotFolders() -> [URL] {
        if let testFolder = ProcessInfo.processInfo.environment["HIPPOCAMPUS_SCREENSHOT_DIR"] {
            return [URL(fileURLWithPath: testFolder)]
        }
        CFPreferencesAppSynchronize("com.apple.screencapture" as CFString)
        let configured = (CFPreferencesCopyAppValue("location-screenshot" as CFString, "com.apple.screencapture" as CFString)
            ?? CFPreferencesCopyAppValue("location" as CFString, "com.apple.screencapture" as CFString)) as? String
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        var folders = [desktop]
        if let configured, configured.hasPrefix("/") || configured.hasPrefix("~") {
            folders.append(URL(fileURLWithPath: (configured as NSString).expandingTildeInPath))
        }
        if let extra = UserDefaults.standard.string(forKey: "extraFolder") { folders.append(URL(fileURLWithPath: extra)) }
        DispatchQueue.main.async { [weak self] in
            let description = folders.dropFirst().last?.lastPathComponent ?? "桌面"
            if self?.folderDescription != description { self?.folderDescription = description }
        }
        return Array(Set(folders))
    }

    private func temporaryScreenshotFolders() -> [URL] {
        if ProcessInfo.processInfo.environment["HIPPOCAMPUS_SCREENSHOT_DIR"] != nil { return [] }
        let tmp = FileManager.default.temporaryDirectory
        var folders = [tmp.appendingPathComponent("com.apple.screencaptureui")]
        let items = tmp.appendingPathComponent("TemporaryItems")
        let children = (try? FileManager.default.contentsOfDirectory(at: items, includingPropertiesForKeys: nil)) ?? []
        folders += children.filter { $0.lastPathComponent.hasPrefix("NSIRD_screencaptureui_") }
        return folders
    }

    private func scan(initial: Bool, baselineOnly: Bool = false) {
        guard library != nil else { return }
        let isPaused = DispatchQueue.main.sync { paused }
        let folders = screenshotFolders()
        let temporary = temporaryScreenshotFolders()
        var candidates: [(URL, Date, String, Bool)] = []
        var reachable = false
        for folder in folders + temporary {
            let isTemp = temporary.contains(folder)
            guard let files = try? FileManager.default.contentsOfDirectory(at: folder,
                   includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else { continue }
            if !isTemp { reachable = true }
            for file in files where ["png", "jpg", "jpeg", "heic", "tiff"].contains(file.pathExtension.lowercased()) {
                guard isTemp || Self.isScreenshot(file),
                      let values = try? file.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey, .fileSizeKey]),
                      let size = values.fileSize, size > 0 else { continue }
                let date = values.creationDate ?? values.contentModificationDate ?? Date()
                if isTemp && date < launched.addingTimeInterval(-2) { continue }
                let signature = "\(values.contentModificationDate?.timeIntervalSince1970 ?? 0):\(size)"
                if seen[file.path] != signature { candidates.append((file, date, signature, isTemp)) }
            }
        }
        if !reachable { showProblem("无法读取截图文件夹。请在设置中选择文件夹，或在 macOS 的文件与文件夹权限中允许访问。") }
        candidates.sort { $0.1 < $1.1 }
        // Initial import is limited to the latest 30; never walk unrelated subfolders.
        let incoming = initial ? Array(candidates.suffix(CaptureLibrary.capacity)) : candidates
        if initial {
            for candidate in candidates.dropLast(incoming.count) { seen[candidate.0.path] = candidate.2 }
        }
        for (url, date, signature, isTemp) in incoming {
            if isPaused || baselineOnly { seen[url.path] = signature; continue }
            do {
                let data = try Data(contentsOf: url)
                try library?.insert(data: data, date: date, origin: url.path, source: isTemp ? "截图预览" : "系统截图")
                seen[url.path] = signature
                publish()
            } catch {
                // A file may still be written. Retry on the next tick.
                if !isTemp { NSLog("Hippocampus: waiting for %@: %@", url.lastPathComponent, error.localizedDescription) }
            }
        }
        scanNumber += 1
        if scanNumber % 300 == 0 { seen = seen.filter { FileManager.default.fileExists(atPath: $0.key) } }
    }

    static func isScreenshot(_ url: URL) -> Bool {
        let marked = url.path.withCString { path in
            getxattr(path, "com.apple.metadata:kMDItemIsScreenCapture", nil, 0, 0, 0) > 0
        }
        if marked { return true }
        let name = url.lastPathComponent.lowercased()
        return ["screenshot", "screen shot", "screen_shot", "截屏", "截图", "スクリーンショット"].contains { name.hasPrefix($0) }
    }
}
