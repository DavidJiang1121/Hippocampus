import SwiftUI
import AppKit

private let ink = Color(red: 0.12, green: 0.19, blue: 0.19)
private let muted = Color(red: 0.44, green: 0.49, blue: 0.48)
private let mint = Color(red: 0.18, green: 0.54, blue: 0.44)
private let paper = Color(red: 0.965, green: 0.966, blue: 0.95)

// Both gallery surfaces are export-only drop destinations, including their empty areas.
final class ExportOnlyHostingView<Content: View>: NSHostingView<Content> {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { [] }
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { [] }
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { false }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool { false }
}

func galleryController(model: HippocampusModel, compact: Bool) -> NSViewController {
    let controller = NSViewController()
    controller.view = ExportOnlyHostingView(rootView: GalleryView(model: model, compact: compact))
    return controller
}

struct GalleryView: View {
    @ObservedObject var model: HippocampusModel
    let compact: Bool
    var body: some View {
        HStack(spacing: 0) {
            if !compact { sidebar.frame(width: 198) }
            VStack(spacing: 0) {
                header.padding(compact ? 18 : 28)
                if let problem = model.problem {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(problem).font(.system(size: 12))
                        Spacer()
                        Button { model.problem = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
                    }.padding(12).background(Color.orange.opacity(0.12)).padding(.horizontal, 18)
                }
                if model.captures.isEmpty { emptyState }
                else {
                    ScrollView {
                        LazyVGrid(columns: compact ? Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                            : [GridItem(.adaptive(minimum: 215, maximum: 350), spacing: 18)], spacing: compact ? 12 : 21) {
                            ForEach(Array(model.captures.enumerated()), id: \.element.id) { index, capture in
                                captureCard(capture, index: index)
                            }
                        }.padding(.horizontal, compact ? 18 : 28).padding(.top, 4).padding(.bottom, 24)
                    }
                }
                footer
            }
        }
        .foregroundStyle(ink)
        .background(paper)
        .preferredColorScheme(.light)
        .tint(mint)
        .overlay(alignment: .bottom) {
            if let message = model.message {
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(ink, in: Capsule()).padding(.bottom, 54)
                    .transition(.opacity)
            }
        }
        .sheet(item: $model.selected) { capture in PreviewView(model: model, capture: capture) }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(nsImage: HippocampusIcon.appIcon(size: 128)).resizable().frame(width: 54, height: 54)
            Text("Hippocampus").font(.system(size: 21, weight: .semibold, design: .rounded)).padding(.top, 16)
            Text("让截图，有迹可循。").font(.system(size: 12)).foregroundStyle(muted).padding(.top, 7)
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up")
                Text("近期截图").fontWeight(.medium)
                Spacer()
                Text("\(model.captures.count)").monospacedDigit().font(.system(size: 11))
            }.font(.system(size: 13)).padding(12).background(mint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10)).padding(.top, 36)
            Button { model.importImages() } label: { Label("收纳图片", systemImage: "plus") }.buttonStyle(.plain).font(.system(size: 13)).padding(12).padding(.top, 8)
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                HStack { Text("短期记忆"); Spacer(); Text("\(model.captures.count) / 30").monospacedDigit() }.font(.system(size: 11)).foregroundStyle(muted)
                GeometryReader { proxy in
                    Capsule().fill(mint.opacity(0.12))
                        .overlay(alignment: .leading) { Capsule().fill(mint.opacity(0.65)).frame(width: proxy.size.width * CGFloat(model.captures.count) / 30) }
                }.frame(height: 4)
                Text("存满后，最早的一张会自动\n从记忆中淡出。").font(.system(size: 11)).foregroundStyle(muted).lineSpacing(5)
            }
            Divider().padding(.vertical, 22)
            VStack(alignment: .leading, spacing: 12) {
                shortcut("⌃ 点击", "复制图片")
                shortcut("拖动", "带到别处")
                shortcut("双击", "放大预览")
            }
            Button { model.openSettings?() } label: { Label("设置", systemImage: "slider.horizontal.3") }
                .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(muted).padding(.top, 28)
        }.padding(24).frame(maxHeight: .infinity).background(Color.white.opacity(0.64))
    }

    private func shortcut(_ key: String, _ description: String) -> some View {
        HStack { Text(key).font(.system(size: 10, weight: .medium)).frame(width: 53, alignment: .leading); Text(description).font(.system(size: 11)) }.foregroundStyle(muted)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: compact ? 14 : 18) {
            HStack(alignment: .center) {
                if compact {
                    Image(nsImage: HippocampusIcon.glyph(size: 28)).frame(width: 28, height: 28)
                    Text("Hippocampus").font(.system(size: 18, weight: .semibold, design: .rounded))
                } else {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("最近的截图").font(.system(size: 28, weight: .semibold))
                        Text("灵感、线索，和来不及留住的瞬间。").font(.system(size: 13)).foregroundStyle(muted)
                    }
                }
                Spacer()
                Text("\(model.captures.count) / 30").font(.system(size: 12, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 10).padding(.vertical, 6).background(mint.opacity(0.1), in: Capsule())
                if !compact {
                    Button { model.importImages() } label: { Label("收纳", systemImage: "plus") }
                        .buttonStyle(.bordered).controlSize(.regular)
                }
            }
            HStack(spacing: 6) {
                Circle().fill(model.paused ? Color.orange : mint).frame(width: 6, height: 6)
                Text(model.paused ? "已暂停收纳" : "自动收纳中")
                if compact { Spacer(); Text("⌃ 点击复制 · 拖动带走") }
                else { Text("· 最新在前"); Spacer(); Text("仅保存在这台 Mac") }
            }.font(.system(size: 11)).foregroundStyle(muted)
        }
    }

    private func captureCard(_ capture: Capture, index: Int) -> some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 9) {
            CaptureThumbnail(capture: capture, url: model.url(for: capture),
                onCopy: { model.copy(capture) }, onPreview: { model.selected = capture },
                onExport: { model.export(capture) }, onDelete: { model.delete(capture) })
                .aspectRatio(compact ? 1.35 : 1.6, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: compact ? 7 : 10))
                .overlay(RoundedRectangle(cornerRadius: compact ? 7 : 10).stroke(ink.opacity(0.07), lineWidth: 1))
            HStack {
                Text(String(format: "%02d", index + 1)).font(.system(size: compact ? 9 : 10, weight: .medium, design: .monospaced)).foregroundStyle(muted)
                Text(capture.capturedAt, format: .dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
                    .font(.system(size: compact ? 9 : 11)).lineLimit(1)
                Spacer(minLength: 0)
                if !compact {
                    Button { model.copy(capture) } label: { Image(systemName: "doc.on.doc") }
                        .buttonStyle(.plain).help("复制图片")
                }
            }
            if !compact { Text("\(capture.width) × \(capture.height)  ·  \(capture.source)").font(.system(size: 10)).foregroundStyle(muted) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(nsImage: HippocampusIcon.glyph(size: 80)).opacity(0.65)
            Text("下一张截图，从这里记住。").font(.system(size: compact ? 16 : 23, weight: .medium))
            Text("照常使用 ⌘⇧3 或 ⌘⇧4 截图。\n浮窗消失后，它仍会留在这里。")
                .font(.system(size: compact ? 12 : 14)).foregroundStyle(muted).multilineTextAlignment(.center).lineSpacing(7)
            Button("收纳已有图片") { model.importImages() }.buttonStyle(.bordered).padding(.top, 5)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(24)
    }

    private var footer: some View {
        HStack {
            if compact {
                Button { model.openWindow?() } label: { Label("打开图库", systemImage: "arrow.up.left.and.arrow.down.right") }.buttonStyle(.plain)
                Spacer()
                Button { model.openSettings?() } label: { Image(systemName: "slider.horizontal.3") }.buttonStyle(.plain).help("设置")
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }.buttonStyle(.plain).help("退出 Hippocampus")
            } else {
                Image(systemName: "externaldrive")
                Text("图库中的图片为独立副本 · 桌面原图不受影响")
                Spacer()
                Text("Hippocampus 1.1")
            }
        }.font(.system(size: 11)).foregroundStyle(muted).padding(.horizontal, compact ? 18 : 28).padding(.vertical, 14)
            .background(Color.white.opacity(0.48))
    }
}

struct PreviewView: View {
    @ObservedObject var model: HippocampusModel
    let capture: Capture
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("截图预览").font(.headline)
                    Text("\(capture.width) × \(capture.height)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            if let image = thumbnail(at: model.url(for: capture), pixels: 2400) {
                Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            HStack {
                Text(capture.capturedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("导出 PNG") { model.export(capture) }
                Button("复制图片") { model.copy(capture) }.buttonStyle(.borderedProminent).keyboardShortcut("c", modifiers: .command)
            }
            if let message = model.message { Text(message).font(.caption).foregroundStyle(mint) }
        }.padding(24).frame(width: 760, height: 560).background(paper).preferredColorScheme(.light)
    }
}

struct SettingsView: View {
    @ObservedObject var model: HippocampusModel
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                Image(nsImage: HippocampusIcon.appIcon(size: 80)).resizable().frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hippocampus").font(.system(size: 23, weight: .semibold, design: .rounded))
                    Text("给最近的截图，一个落脚处。").font(.system(size: 12)).foregroundStyle(muted)
                }
            }
            Divider()
            Toggle("同时收纳剪贴板图片", isOn: Binding(get: { model.clipboardEnabled }, set: model.setClipboard))
            Text("包括复制到剪贴板的截图和其他图片。只保存图片，不读取文字；复制图库里的图片不会重复收纳。")
                .font(.system(size: 12)).foregroundStyle(muted).lineSpacing(4).padding(.top, -12)
            Toggle("暂停自动收纳", isOn: Binding(get: { model.paused }, set: model.setPaused))
            Toggle("登录时启动", isOn: Binding(get: { model.loginEnabled }, set: model.setLogin))
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("截图来源").font(.system(size: 13, weight: .semibold))
                Text("自动监测桌面、系统设定的截图位置，以及可读取的系统截图浮窗缓存。当前文件夹：\(model.folderDescription)")
                    .font(.system(size: 12)).foregroundStyle(muted).lineSpacing(4)
                Button("选择额外截图文件夹…") { model.chooseFolder() }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("30 张短期记忆").font(.system(size: 13, weight: .semibold))
                Text("新截图进入后自动淘汰最旧的一张。图片以 PNG 独立保存在本机，退出或重启后仍然保留。没有云端上传。")
                    .font(.system(size: 12)).foregroundStyle(muted).lineSpacing(4)
                Button("在 Finder 中打开图库") { model.revealLibrary() }
            }
            if let problem = model.problem { Text(problem).font(.caption).foregroundStyle(.orange) }
            if let message = model.message { Text(message).font(.caption).foregroundStyle(mint) }
            Spacer(minLength: 0)
            HStack { Text("版本 1.1 · macOS 13+").font(.caption).foregroundStyle(muted); Spacer(); Button("退出 Hippocampus") { NSApp.terminate(nil) } }
        }.padding(28).frame(width: 440, height: 570).background(paper).foregroundStyle(ink).preferredColorScheme(.light).tint(mint)
    }
}

struct CaptureThumbnail: NSViewRepresentable {
    let capture: Capture
    let url: URL
    let onCopy: () -> Void
    let onPreview: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    func makeNSView(context: Context) -> ThumbnailView { ThumbnailView() }
    func updateNSView(_ view: ThumbnailView, context: Context) {
        if view.url != url { view.url = url; view.image = thumbnail(at: url); view.needsDisplay = true }
        view.onCopy = onCopy; view.onPreview = onPreview; view.onExport = onExport; view.onDelete = onDelete
        view.setAccessibilityLabel("截图 \(capture.capturedAt.formatted())，\(capture.width) 乘 \(capture.height)，Control 点击复制，双击预览")
    }
}

final class ThumbnailView: NSView, NSDraggingSource {
    var url: URL?
    var image: NSImage?
    var onCopy: (() -> Void)?
    var onPreview: (() -> Void)?
    var onExport: (() -> Void)?
    var onDelete: (() -> Void)?
    private var start: NSEvent?
    private var dragging = false
    override var acceptsFirstResponder: Bool { true }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true); setAccessibilityRole(.button)
        setAccessibilityHelp("Control 点击复制图片；拖动导出；双击放大。")
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedRed: 0.90, green: 0.92, blue: 0.90, alpha: 1).setFill()
        bounds.fill()
        guard let image else { return }
        let size = image.size
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let w = size.width * scale, h = size.height * scale
        image.draw(in: NSRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h),
                   from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    }
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { onCopy?(); start = nil; return }
        if event.clickCount == 2 { onPreview?(); start = nil; return }
        start = event; dragging = false
        window?.makeFirstResponder(self)
    }
    override func mouseUp(with event: NSEvent) { start = nil; dragging = false }
    override func rightMouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { onCopy?(); return }
        let menu = NSMenu()
        for (title, action) in [("复制图片", #selector(copyImage)), ("放大预览", #selector(previewImage)),
                                ("导出 PNG…", #selector(exportImage)), ("从图库移除", #selector(deleteImage))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; menu.addItem(item)
        }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == "c", event.modifierFlags.contains(.command) { onCopy?() }
        else if event.keyCode == 49 || event.keyCode == 36 { onPreview?() }
        else { super.keyDown(with: event) }
    }
    override func accessibilityPerformPress() -> Bool { onPreview?(); return true }
    @objc private func copyImage() { onCopy?() }
    @objc private func previewImage() { onPreview?() }
    @objc private func exportImage() { onExport?() }
    @objc private func deleteImage() { onDelete?() }
    override func mouseDragged(with event: NSEvent) {
        guard !dragging, let start, let url, let image,
              hypot(event.locationInWindow.x - start.locationInWindow.x, event.locationInWindow.y - start.locationInWindow.y) > 4 else { return }
        do {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Hippocampus-Drag/\(UUID())")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let exported = directory.appendingPathComponent(url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: exported)
            let writer = NSPasteboardItem()
            writer.setString(exported.absoluteString, forType: .fileURL)
            writer.setData(try Data(contentsOf: exported), forType: .png)
            if let tiff = image.tiffRepresentation { writer.setData(tiff, forType: .tiff) }
            let item = NSDraggingItem(pasteboardWriter: writer)
            item.setDraggingFrame(bounds, contents: image)
            dragging = true
            beginDraggingSession(with: [item], event: start, source: self)
        } catch { NSSound.beep() }
    }
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .copy }
    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool { true }
}
