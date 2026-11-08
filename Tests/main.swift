import AppKit

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError("FAIL: \(message)") }
}
func png(_ number: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 64, pixelsHigh: 48, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 256, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor(calibratedRed: CGFloat(number % 17) / 17, green: CGFloat(number % 11) / 11, blue: 0.4, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 64, height: 48).fill()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
let root = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
let library = try CaptureLibrary(root: root.appendingPathComponent("Library"))
let base = Date(timeIntervalSince1970: 1_800_000_000)
let original = root.appendingPathComponent("original.png")
try png(0).write(to: original)
for i in 0..<35 {
    try library.insert(data: png(i), date: base.addingTimeInterval(Double(i * 10)), origin: "shot-\(i)", source: "test")
}
expect(library.captures.count == 30, "capacity")
expect(library.captures.first?.capturedAt == base.addingTimeInterval(340), "latest first")
expect(library.captures.last?.capturedAt == base.addingTimeInterval(50), "oldest five evicted")
let files = try FileManager.default.contentsOfDirectory(at: library.root, includingPropertiesForKeys: nil)
expect(files.filter { $0.pathExtension == "png" }.count == 30, "disk bounded to 30")
expect(FileManager.default.fileExists(atPath: original.path), "original file preserved")
print("PASS: FIFO capacity, newest first, disk pruning, original preservation")

let reloaded = try CaptureLibrary(root: library.root)
expect(reloaded.captures == library.captures, "restart persistence")
print("PASS: persistence across restart")

let newest = reloaded.captures[0]
let replayed = try reloaded.insert(data: png(34), date: newest.capturedAt, origin: newest.origin, source: newest.source)
expect(!replayed && reloaded.captures == library.captures, "folder rescan after restart is idempotent")
print("PASS: restart folder rescan does not duplicate captures")
let added = try reloaded.insert(data: png(34), date: newest.capturedAt.addingTimeInterval(0.5), origin: "clipboard", source: "clipboard")
expect(!added && reloaded.captures.count == 30, "cross-source dedup")
let sameOrigin = try reloaded.insert(data: png(34), date: newest.capturedAt.addingTimeInterval(0.8), origin: newest.origin, source: "test")
expect(sameOrigin, "repeated intentional shots")
let sameChannel = try reloaded.insert(data: png(34), date: newest.capturedAt.addingTimeInterval(1.1), origin: "second-screenshot", source: "test")
expect(sameChannel, "identical consecutive screenshots are retained")
print("PASS: file and clipboard coalescing, repeated intentional shots")

let before = reloaded.captures
do { try reloaded.insert(data: Data("invalid".utf8), origin: "bad", source: "test"); fatalError("invalid image accepted") }
catch LibraryError.invalidImage { }
expect(reloaded.captures == before, "invalid input did not evict")
try reloaded.remove(id: reloaded.captures[0].id)
expect(reloaded.captures.count == 29, "single deletion")
print("PASS: invalid input preserves history, single deletion")

let transaction = try CaptureLibrary(root: root.appendingPathComponent("Transaction"))
try transaction.insert(data: png(1), origin: "first", source: "test")
let transactionBefore = transaction.captures
let index = transaction.root.appendingPathComponent("history.json")
try FileManager.default.removeItem(at: index)
try FileManager.default.createDirectory(at: index, withIntermediateDirectories: false)
do { try transaction.insert(data: png(2), origin: "second", source: "test"); fatalError("failed index write accepted") }
catch { }
expect(transaction.captures == transactionBefore, "failed index leaves memory intact")
let committedImages = try FileManager.default.contentsOfDirectory(at: transaction.root, includingPropertiesForKeys: nil).filter { $0.pathExtension == "png" }
expect(committedImages.count == 1, "failed image write rolled back")
print("PASS: failed persistence rolls back without evicting")

let corrupt = root.appendingPathComponent("Corrupt")
try FileManager.default.createDirectory(at: corrupt, withIntermediateDirectories: true)
try Data("malformed".utf8).write(to: corrupt.appendingPathComponent("history.json"))
try png(1).write(to: corrupt.appendingPathComponent("Hippocampus_preserve.png"))
do { _ = try CaptureLibrary(root: corrupt); fatalError("corrupt index accepted") }
catch LibraryError.invalidManifest { }
expect(FileManager.default.fileExists(atPath: corrupt.appendingPathComponent("Hippocampus_preserve.png").path), "corrupt manifest preserved images")
print("PASS: corrupt index preserves original library files")
print("All Hippocampus storage tests passed.")
