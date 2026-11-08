import AppKit

// Vector contour of the selected two-notch concept, shared at every icon size.
enum HippocampusIcon {
    static let green = NSColor(srgbRed: 22.0 / 255, green: 77.0 / 255, blue: 67.0 / 255, alpha: 1)
    static let ivory = NSColor(srgbRed: 245.0 / 255, green: 241.0 / 255, blue: 232.0 / 255, alpha: 1)
    // Traced and simplified from the user-selected 03-fold.png; normalized to 100 points.
    static let outline: [NSPoint] = [
        NSPoint(x: 56.37959, y: 80.06380),
        NSPoint(x: 60.36683, y: 79.98405),
        NSPoint(x: 64.03509, y: 79.26635),
        NSPoint(x: 67.78309, y: 77.67145),
        NSPoint(x: 70.97289, y: 75.35885),
        NSPoint(x: 73.12600, y: 72.88676),
        NSPoint(x: 74.64115, y: 70.09569),
        NSPoint(x: 75.27911, y: 68.02233),
        NSPoint(x: 75.51834, y: 66.26794),
        NSPoint(x: 75.27911, y: 63.15789),
        NSPoint(x: 74.48166, y: 61.24402),
        NSPoint(x: 73.76396, y: 60.20734),
        NSPoint(x: 72.72727, y: 59.17065),
        NSPoint(x: 70.89314, y: 58.05423),
        NSPoint(x: 69.37799, y: 57.57576),
        NSPoint(x: 68.10207, y: 57.41627),
        NSPoint(x: 64.27432, y: 57.81499),
        NSPoint(x: 61.96172, y: 57.81499),
        NSPoint(x: 59.17065, y: 57.41627),
        NSPoint(x: 55.82137, y: 56.29984),
        NSPoint(x: 53.58852, y: 55.10367),
        NSPoint(x: 51.43541, y: 53.58852),
        NSPoint(x: 48.32536, y: 50.39872),
        NSPoint(x: 47.04944, y: 48.48485),
        NSPoint(x: 46.17225, y: 46.73046),
        NSPoint(x: 45.53429, y: 44.89633),
        NSPoint(x: 45.05582, y: 42.34450),
        NSPoint(x: 45.21531, y: 38.59649),
        NSPoint(x: 45.77352, y: 36.52313),
        NSPoint(x: 46.88995, y: 34.29027),
        NSPoint(x: 47.76715, y: 33.09410),
        NSPoint(x: 49.68102, y: 31.25997),
        NSPoint(x: 51.11643, y: 30.30303),
        NSPoint(x: 54.30622, y: 28.94737),
        NSPoint(x: 57.49601, y: 28.30941),
        NSPoint(x: 59.56938, y: 28.30941),
        NSPoint(x: 62.36045, y: 28.94737),
        NSPoint(x: 64.19458, y: 29.98405),
        NSPoint(x: 65.47049, y: 31.33971),
        NSPoint(x: 66.10845, y: 32.85486),
        NSPoint(x: 66.10845, y: 34.05104),
        NSPoint(x: 65.62998, y: 35.08772),
        NSPoint(x: 64.83254, y: 35.80542),
        NSPoint(x: 62.75917, y: 36.76236),
        NSPoint(x: 61.96172, y: 37.63955),
        NSPoint(x: 61.80223, y: 38.67624),
        NSPoint(x: 62.36045, y: 39.63317),
        NSPoint(x: 62.99841, y: 40.11164),
        NSPoint(x: 64.03509, y: 40.51037),
        NSPoint(x: 66.50718, y: 40.66986),
        NSPoint(x: 68.89952, y: 40.03190),
        NSPoint(x: 70.97289, y: 38.75598),
        NSPoint(x: 72.56778, y: 37.08134),
        NSPoint(x: 73.84370, y: 34.44976),
        NSPoint(x: 74.16268, y: 32.85486),
        NSPoint(x: 74.16268, y: 30.78150),
        NSPoint(x: 73.84370, y: 29.10686),
        NSPoint(x: 72.80702, y: 26.63477),
        NSPoint(x: 70.81340, y: 24.00319),
        NSPoint(x: 68.50080, y: 22.08931),
        NSPoint(x: 66.26794, y: 20.81340),
        NSPoint(x: 62.83892, y: 19.45774),
        NSPoint(x: 59.56938, y: 18.66029),
        NSPoint(x: 55.50239, y: 18.18182),
        NSPoint(x: 51.99362, y: 18.18182),
        NSPoint(x: 49.52153, y: 18.42105),
        NSPoint(x: 46.01276, y: 19.13876),
        NSPoint(x: 43.14195, y: 20.09569),
        NSPoint(x: 40.98884, y: 21.05263),
        NSPoint(x: 38.59649, y: 22.40829),
        NSPoint(x: 35.24721, y: 24.88038),
        NSPoint(x: 32.93461, y: 27.03349),
        NSPoint(x: 30.62201, y: 29.74482),
        NSPoint(x: 28.38915, y: 33.01435),
        NSPoint(x: 26.71451, y: 36.20415),
        NSPoint(x: 25.59809, y: 39.07496),
        NSPoint(x: 24.80064, y: 42.26475),
        NSPoint(x: 24.40191, y: 46.25199),
        NSPoint(x: 24.72089, y: 50.95694),
        NSPoint(x: 25.67783, y: 55.18341),
        NSPoint(x: 26.39553, y: 57.25678),
        NSPoint(x: 27.19298, y: 58.45295),
        NSPoint(x: 27.91069, y: 58.85167),
        NSPoint(x: 29.82456, y: 58.61244),
        NSPoint(x: 32.05742, y: 57.73525),
        NSPoint(x: 34.13078, y: 56.29984),
        NSPoint(x: 35.08772, y: 55.90112),
        NSPoint(x: 35.88517, y: 55.90112),
        NSPoint(x: 36.52313, y: 56.14035),
        NSPoint(x: 37.24083, y: 56.77831),
        NSPoint(x: 37.55981, y: 57.49601),
        NSPoint(x: 37.63955, y: 58.37321),
        NSPoint(x: 37.32057, y: 59.33014),
        NSPoint(x: 35.88517, y: 60.76555),
        NSPoint(x: 32.69537, y: 62.51994),
        NSPoint(x: 29.58533, y: 63.39713),
        NSPoint(x: 32.37640, y: 67.14514),
        NSPoint(x: 33.81180, y: 68.58054),
        NSPoint(x: 35.08772, y: 68.74003),
        NSPoint(x: 36.84211, y: 68.18182),
        NSPoint(x: 38.43700, y: 67.38437),
        NSPoint(x: 41.70654, y: 65.07177),
        NSPoint(x: 42.90271, y: 64.99203),
        NSPoint(x: 43.54067, y: 65.23126),
        NSPoint(x: 44.33812, y: 65.94896),
        NSPoint(x: 44.65710, y: 66.66667),
        NSPoint(x: 44.73684, y: 67.38437),
        NSPoint(x: 44.25837, y: 68.66029),
        NSPoint(x: 43.06220, y: 69.85646),
        NSPoint(x: 41.54705, y: 70.97289),
        NSPoint(x: 38.19777, y: 72.64753),
        NSPoint(x: 42.02552, y: 75.43860),
        NSPoint(x: 46.57097, y: 77.75120),
        NSPoint(x: 51.51515, y: 79.34609),
    ]

    static func ribbon() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: outline[0])
        let count = outline.count
        func tangent(_ index: Int) -> NSPoint {
            let previous = outline[(index + count - 1) % count]
            let point = outline[index]
            let next = outline[(index + 1) % count]
            let ax = point.x - previous.x, ay = point.y - previous.y
            let bx = next.x - point.x, by = next.y - point.y
            let denominator = hypot(ax, ay) * hypot(bx, by)
            // Keep the two deliberate fold corners crisp; smooth the organic arcs.
            if denominator == 0 || (ax * bx + ay * by) / denominator < 0.25 { return .zero }
            return NSPoint(x: (next.x - previous.x) / 6, y: (next.y - previous.y) / 6)
        }
        for index in 0..<count {
            let next = (index + 1) % count
            let a = outline[index], b = outline[next]
            let ta = tangent(index), tb = tangent(next)
            path.curve(to: b, controlPoint1: NSPoint(x: a.x + ta.x, y: a.y + ta.y),
                       controlPoint2: NSPoint(x: b.x - tb.x, y: b.y - tb.y))
        }
        path.close()
        return path
    }

    static func glyph(size: CGFloat, template: Bool = false) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            let path = ribbon()
            let bounds = path.bounds
            let scale = size * 0.88 / max(bounds.width, bounds.height)
            let transform = AffineTransform(m11: scale, m12: 0, m21: 0, m22: scale,
                tX: (size - bounds.width * scale) / 2 - bounds.minX * scale,
                tY: (size - bounds.height * scale) / 2 - bounds.minY * scale)
            path.transform(using: transform)
            (template ? NSColor.black : green).setFill()
            path.fill()
            return true
        }
        image.isTemplate = template
        return image
    }

    static func appIcon(size: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let background = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.065, dy: size * 0.065),
                xRadius: size * 0.18, yRadius: size * 0.18)
            ivory.setFill()
            background.fill()
            let path = ribbon()
            path.transform(using: AffineTransform(scale: size / 100))
            green.setFill()
            path.fill()
            return true
        }
    }
}
