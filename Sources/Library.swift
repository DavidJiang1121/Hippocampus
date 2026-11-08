import Foundation
import AppKit
import ImageIO
import CryptoKit

struct Capture: Codable, Identifiable, Equatable {
    let id: UUID
    let filename: String
    let capturedAt: Date
    let width: Int
    let height: Int
    let fingerprint: String
    let origin: String
    let source: String
}

enum LibraryError: LocalizedError {
    case invalidImage, invalidManifest
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "这张图片无法读取。"
        case .invalidManifest: return "图库索引损坏，原图片已保留。请在 Finder 中检查图库。"
        }
    }
}

// All mutations run on one serial queue. Commit the index before pruning images.
final class CaptureLibrary {
    static let capacity = 30
    let root: URL
    private(set) var captures: [Capture] = []
    private var index: URL { root.appendingPathComponent("history.json") }

    init(root: URL) throws {
        self.root = root
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: index.path) {
            guard let decoded = try? JSONDecoder().decode([Capture].self, from: Data(contentsOf: index)),
                  decoded.allSatisfy({ $0.filename == URL(fileURLWithPath: $0.filename).lastPathComponent && $0.filename.hasSuffix(".png") }) else {
                throw LibraryError.invalidManifest
            }
            captures = Array(decoded.filter { FileManager.default.fileExists(atPath: url(for: $0).path) }
                .sorted { $0.capturedAt > $1.capturedAt }.prefix(Self.capacity))
            try commit(captures)
            prune()
        }
    }

    func url(for capture: Capture) -> URL { root.appendingPathComponent(capture.filename) }

    @discardableResult
    func insert(data: Data, date: Date = Date(), origin: String, source: String) throws -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateImageAtIndex(imageSource, 0, [kCGImageSourceShouldCache: false] as CFDictionary),
              let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { throw LibraryError.invalidImage }
        let fingerprint = Self.fingerprint(cg)
        // Merge the same capture arriving through the floating thumbnail, file, and clipboard.
        // Separate captures from the same origin remain separate, even with identical pixels.
        for stored in captures where stored.fingerprint == fingerprint {
            let interval = abs(stored.capturedAt.timeIntervalSince(date))
            // Folder discovery repeats after relaunch; the exact source file is not a new capture.
            if stored.origin == origin && interval < 0.001 { return false }
            if stored.source != source && stored.origin != origin && interval < 1.5 { return false }
        }
        let id = UUID()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH.mm.ss"
        let capture = Capture(id: id, filename: "Hippocampus_\(formatter.string(from: date))_\(id.uuidString.prefix(6)).png", capturedAt: date,
                              width: cg.width, height: cg.height, fingerprint: fingerprint, origin: origin, source: source)
        let file = url(for: capture)
        try png.write(to: file, options: .atomic)
        let next = Array((captures + [capture]).sorted { $0.capturedAt > $1.capturedAt }.prefix(Self.capacity))
        do { try commit(next) } catch { try? FileManager.default.removeItem(at: file); throw error }
        captures = next
        prune()
        return true
    }

    func remove(id: UUID) throws {
        let next = captures.filter { $0.id != id }
        try commit(next)
        captures = next
        prune()
    }

    private func commit(_ value: [Capture]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: index, options: .atomic)
    }

    private func prune() {
        let live = Set(captures.map(\.filename))
        let files = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("Hippocampus_") && file.pathExtension == "png" && !live.contains(file.lastPathComponent) {
            do { try FileManager.default.removeItem(at: file) }
            catch { NSLog("Hippocampus: could not prune %@: %@", file.path, error.localizedDescription) }
        }
    }

    private static func fingerprint(_ image: CGImage) -> String {
        // Canonical pixels coalesce TIFF clipboard and PNG file versions of the same shot.
        var pixels = [UInt8](repeating: 0, count: 96 * 96 * 4)
        pixels.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: 96, height: 96, bitsPerComponent: 8, bytesPerRow: 96 * 4,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: 96, height: 96))
        }
        return "\(image.width)x\(image.height):" + SHA256.hash(data: Data(pixels)).map { String(format: "%02x", $0) }.joined()
    }
}

func thumbnail(at url: URL, pixels: Int = 700) -> NSImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceThumbnailMaxPixelSize: pixels, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { return nil }
    return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
}
