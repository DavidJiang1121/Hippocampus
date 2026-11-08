import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var model: HippocampusModel!
    private var status: NSStatusItem!
    private let popover = NSPopover()
    private var gallery: NSWindow?
    private var settings: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model = HippocampusModel()
        NSApp.applicationIconImage = HippocampusIcon.appIcon(size: 1024)
        installMainMenu()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = HippocampusIcon.glyph(size: 21, template: true)
        status.button?.toolTip = "Hippocampus · 最近 30 张截图"
        status.button?.setAccessibilityLabel("Hippocampus")
        status.button?.target = self
        status.button?.action = #selector(togglePopover)
        status.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 412, height: 550)
        popover.contentViewController = galleryController(model: model, compact: true)
        model.openWindow = { [weak self] in self?.showGallery() }
        model.closePopover = { [weak self] in self?.popover.performClose(nil) }
        model.openSettings = { [weak self] in self?.showSettings() }
        cleanOldDragFiles()
        if !CommandLine.arguments.contains("--background") { showGallery() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showGallery(); return true }

    private func installMainMenu() {
        let main = NSMenu()
        let app = NSMenuItem(); main.addItem(app)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "打开 Hippocampus", action: #selector(showGallery), keyEquivalent: "1").target = self
        let quick = appMenu.addItem(withTitle: "打开菜单栏面板", action: #selector(togglePopover), keyEquivalent: "1")
        quick.keyEquivalentModifierMask = [.command, .shift]; quick.target = self
        appMenu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: ",").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "隐藏 Hippocampus", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "退出 Hippocampus", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        app.submenu = appMenu
        let edit = NSMenuItem(title: "编辑", action: nil, keyEquivalent: ""); main.addItem(edit)
        let editing = NSMenu(title: "编辑")
        editing.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editing.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editing.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        edit.submenu = editing
        NSApp.mainMenu = main
    }

    @objc private func togglePopover() {
        guard let button = status.button else { return }
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "打开图库", action: #selector(showGallery), keyEquivalent: "").target = self
            menu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: "").target = self
            menu.addItem(.separator())
            menu.addItem(withTitle: "退出 Hippocampus", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
            status.menu = menu; button.performClick(nil); status.menu = nil
        } else if popover.isShown { popover.performClose(nil) }
        else { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
    }

    @objc func showGallery() {
        popover.performClose(nil)
        if gallery == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1060, height: 720),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
            window.title = "Hippocampus"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.contentView = ExportOnlyHostingView(rootView: GalleryView(model: model, compact: false).padding(.top, 28).background(Color(red: 0.965, green: 0.966, blue: 0.95)))
            window.minSize = NSSize(width: 760, height: 520)
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.setFrameAutosaveName("HippocampusGallery")
            window.center()
            gallery = window
        }
        NSApp.setActivationPolicy(.regular)
        gallery?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showSettings() {
        popover.performClose(nil)
        if settings == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 570),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Hippocampus 设置"
            window.contentView = NSHostingView(rootView: SettingsView(model: model))
            window.isReleasedWhenClosed = false; window.delegate = self
            window.center(); settings = window
        }
        NSApp.setActivationPolicy(.regular)
        settings?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.gallery?.isVisible != true && self.settings?.isVisible != true { NSApp.setActivationPolicy(.accessory) }
        }
    }

    private func cleanOldDragFiles() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("Hippocampus-Drag")
        for url in (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.creationDateKey])) ?? [] {
            if let date = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate, date < Date().addingTimeInterval(-86400) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
