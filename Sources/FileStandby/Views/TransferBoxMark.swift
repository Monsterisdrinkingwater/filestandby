import AppKit
import SwiftUI

/// The shared visual mark: a dark standby tray holding layered files.
enum TransferBoxMarkImage {
    static func image(size: CGFloat) -> NSImage {
        let scale: CGFloat = 3
        let image = NSImage(size: NSSize(width: size * scale, height: size * scale))
        image.lockFocus()
        draw(in: NSRect(origin: .zero, size: image.size))
        image.unlockFocus()
        image.size = NSSize(width: size, height: size)
        return image
    }

    static func draw(in rect: NSRect) {
        guard rect.width > 0, rect.height > 0,
              let context = NSGraphicsContext.current?.cgContext
        else { return }

        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: rect.width / 100, y: rect.height / 100)
        // Use a top-left origin so the same mark has the same orientation in
        // SwiftUI images and the AppKit edge receiver.
        context.translateBy(x: 0, y: 100)
        context.scaleBy(x: 1, y: -1)
        defer { context.restoreGState() }

        // The layered documents from the supplied logo reference.
        roundedRect(x: 33, y: 9, width: 34, height: 45, radius: 8)
            .fill(with: NSColor(red: 0.67, green: 0.42, blue: 0.93, alpha: 1))
        roundedRect(x: 27, y: 18, width: 46, height: 46, radius: 8)
            .fill(with: NSColor(red: 1.0, green: 0.78, blue: 0.30, alpha: 1))
        roundedRect(x: 21, y: 27, width: 58, height: 48, radius: 9)
            .fill(with: NSColor(red: 0.20, green: 0.82, blue: 0.75, alpha: 1))
        roundedRect(x: 28, y: 37, width: 44, height: 40, radius: 9)
            .fill(with: .white)

        roundedRect(x: 36, y: 48, width: 28, height: 4, radius: 2)
            .fill(with: NSColor(red: 0.76, green: 0.80, blue: 0.88, alpha: 1))
        roundedRect(x: 36, y: 57, width: 21, height: 4, radius: 2)
            .fill(with: NSColor(red: 0.80, green: 0.84, blue: 0.91, alpha: 1))

        // Rear walls give the tray depth before its notched front wall covers
        // the lower portion of the files.
        path([
            .init(x: 10, y: 47), .init(x: 18, y: 30), .init(x: 82, y: 30),
            .init(x: 90, y: 47), .init(x: 90, y: 78), .init(x: 78, y: 91),
            .init(x: 22, y: 91), .init(x: 10, y: 78)
        ]).fill(with: NSColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 1))

        let trayFront = NSBezierPath()
        trayFront.move(to: NSPoint(x: 10, y: 49))
        trayFront.line(to: NSPoint(x: 29, y: 61))
        trayFront.line(to: NSPoint(x: 39, y: 61))
        trayFront.curve(to: NSPoint(x: 50, y: 70), controlPoint1: NSPoint(x: 40, y: 61), controlPoint2: NSPoint(x: 40, y: 70))
        trayFront.curve(to: NSPoint(x: 61, y: 61), controlPoint1: NSPoint(x: 60, y: 70), controlPoint2: NSPoint(x: 60, y: 61))
        trayFront.line(to: NSPoint(x: 71, y: 61))
        trayFront.line(to: NSPoint(x: 90, y: 49))
        trayFront.line(to: NSPoint(x: 90, y: 78))
        trayFront.curve(to: NSPoint(x: 77, y: 91), controlPoint1: NSPoint(x: 90, y: 85), controlPoint2: NSPoint(x: 84, y: 91))
        trayFront.line(to: NSPoint(x: 23, y: 91))
        trayFront.curve(to: NSPoint(x: 10, y: 78), controlPoint1: NSPoint(x: 16, y: 91), controlPoint2: NSPoint(x: 10, y: 85))
        trayFront.close()
        trayFront.fill(with: NSColor(red: 0.13, green: 0.19, blue: 0.31, alpha: 1))

        roundedRect(x: 42, y: 82, width: 16, height: 4, radius: 2)
            .fill(with: NSColor(red: 0.20, green: 0.95, blue: 0.92, alpha: 1))
    }

    private static func path(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        points.dropFirst().forEach(path.line(to:))
        path.close()
        return path
    }

    private static func roundedRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat) -> NSBezierPath {
        NSBezierPath(roundedRect: NSRect(x: x, y: y, width: width, height: height), xRadius: radius, yRadius: radius)
    }
}

private extension NSBezierPath {
    func fill(with color: NSColor) {
        color.setFill()
        fill()
    }
}

struct TransferBoxMark: View {
    let size: CGFloat

    init(size: CGFloat) {
        self.size = size
    }

    var body: some View {
        Image(nsImage: TransferBoxMarkImage.image(size: size))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
