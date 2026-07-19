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
        defer { context.restoreGState() }

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.set()

        path([.init(x: 12, y: 56), .init(x: 35, y: 91), .init(x: 50, y: 77), .init(x: 30, y: 47)])
            .fill(with: color.blended(withFraction: 0.18, of: .white) ?? color)
        path([.init(x: 88, y: 56), .init(x: 65, y: 91), .init(x: 50, y: 77), .init(x: 70, y: 47)])
            .fill(with: color)

        path([.init(x: 12, y: 56), .init(x: 50, y: 77), .init(x: 88, y: 56), .init(x: 50, y: 37)])
            .fill(with: color.withAlphaComponent(0.45))

        path([.init(x: 14, y: 59), .init(x: 37, y: 91), .init(x: 50, y: 77), .init(x: 63, y: 91), .init(x: 86, y: 59)])
            .stroke(with: color, lineWidth: 6, lineJoin: .round)

        path([.init(x: 12, y: 56), .init(x: 35, y: 91), .init(x: 50, y: 77), .init(x: 65, y: 91), .init(x: 88, y: 56)])
            .stroke(with: color, lineWidth: 5, lineJoin: .round)

        path([.init(x: 14, y: 57), .init(x: 31, y: 25), .init(x: 50, y: 37), .init(x: 34, y: 62)])
            .fill(with: color.withAlphaComponent(0.86))
        path([.init(x: 86, y: 57), .init(x: 69, y: 25), .init(x: 50, y: 37), .init(x: 66, y: 62)])
            .fill(with: color)
    }

    private static func path(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach(path.line(to:))
        path.close()
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
