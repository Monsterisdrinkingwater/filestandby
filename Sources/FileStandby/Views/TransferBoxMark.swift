import AppKit
import SwiftUI

/// The product mark used everywhere File Standby represents the shelf itself.
/// Keeping the geometry in AppKit lets the edge receiver and SwiftUI share it.
enum TransferBoxMarkImage {
    static func image(size: CGFloat, color: NSColor) -> NSImage {
        let scale: CGFloat = 3
        let image = NSImage(size: NSSize(width: size * scale, height: size * scale))
        image.lockFocus()
        draw(in: NSRect(origin: .zero, size: image.size), color: color)
        image.unlockFocus()
        image.size = NSSize(width: size, height: size)
        return image
    }

    static func draw(in rect: NSRect, color: NSColor) {
        guard rect.width > 0, rect.height > 0 else { return }
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: rect.width / 100, y: rect.height / 100)
        // AppKit's drawing coordinate system differs between an NSImage and a
        // view. Normalize the mark so its open flaps always face upward.
        context.translateBy(x: 0, y: 100)
        context.scaleBy(x: 1, y: -1)
        defer { context.restoreGState() }

        // Use only broad, filled surfaces at small sizes. The previous closed
        // outline drew an unwanted diagonal through the mark when rasterized.
        path([.init(x: 12, y: 56), .init(x: 31, y: 23), .init(x: 50, y: 37), .init(x: 31, y: 61)])
            .fill(with: color.withAlphaComponent(0.84))
        path([.init(x: 88, y: 56), .init(x: 69, y: 23), .init(x: 50, y: 37), .init(x: 69, y: 61)])
            .fill(with: color)

        path([.init(x: 12, y: 56), .init(x: 50, y: 78), .init(x: 50, y: 96), .init(x: 18, y: 78)])
            .fill(with: color.withAlphaComponent(0.74))
        path([.init(x: 88, y: 56), .init(x: 50, y: 78), .init(x: 50, y: 96), .init(x: 82, y: 78)])
            .fill(with: color)

        path([.init(x: 12, y: 56), .init(x: 50, y: 78), .init(x: 88, y: 56), .init(x: 50, y: 37)])
            .fill(with: color.withAlphaComponent(0.43))

        openPath([.init(x: 14, y: 57), .init(x: 50, y: 78), .init(x: 86, y: 57)])
            .stroke(with: color, lineWidth: 5, lineJoin: .round)
    }

    private static func path(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach(path.line(to:))
        path.close()
        return path
    }

    private static func openPath(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach(path.line(to:))
        return path
    }
}

private extension NSBezierPath {
    func fill(with color: NSColor) {
        color.setFill()
        fill()
    }

    func stroke(with color: NSColor, lineWidth: CGFloat, lineJoin: NSBezierPath.LineJoinStyle) {
        color.setStroke()
        self.lineWidth = lineWidth
        lineJoinStyle = lineJoin
        lineCapStyle = .round
        stroke()
    }
}

struct TransferBoxMark: View {
    let size: CGFloat
    let color: NSColor

    init(size: CGFloat, color: NSColor = .white) {
        self.size = size
        self.color = color
    }

    var body: some View {
        Image(nsImage: TransferBoxMarkImage.image(size: size, color: color))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
