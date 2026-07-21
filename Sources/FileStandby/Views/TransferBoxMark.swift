import AppKit
import SwiftUI

enum TransferBoxMarkStyle {
    case color
    case outline
    case receiver
}

/// Shared brand artwork. The color version mirrors the layered reference logo;
/// the outline version stays legible in the menu bar and edge receiver.
enum TransferBoxMarkImage {
    static func image(size: CGFloat, style: TransferBoxMarkStyle) -> NSImage {
        if case .color = style,
           let iconURL = Bundle.main.url(forResource: "FileStandby", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            icon.size = NSSize(width: size, height: size)
            return icon
        }

        let scale: CGFloat = 4
        let image = NSImage(size: NSSize(width: size * scale, height: size * scale))
        image.lockFocus()
        draw(in: NSRect(origin: .zero, size: image.size), style: style)
        image.unlockFocus()
        image.size = NSSize(width: size, height: size)
        return image
    }

    static func draw(in rect: NSRect, style: TransferBoxMarkStyle) {
        guard rect.width > 0, rect.height > 0,
              let context = NSGraphicsContext.current?.cgContext
        else { return }

        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: rect.width / 100, y: rect.height / 100)
        context.translateBy(x: 0, y: 100)
        context.scaleBy(x: 1, y: -1)
        defer { context.restoreGState() }

        switch style {
        case .color:
            drawColorMark()
        case .outline:
            drawOutlineMark()
        case .receiver:
            drawReceiverMark()
        }
    }

    private static func drawColorMark() {
        // Dark interior cavity, visible around the layered documents.
        roundedRect(x: 14, y: 29, width: 72, height: 55, radius: 14)
            .fill(with: NSColor(red: 0.045, green: 0.075, blue: 0.13, alpha: 1))

        roundedRect(x: 36, y: 5, width: 28, height: 48, radius: 7)
            .fill(with: NSColor(red: 0.69, green: 0.43, blue: 0.93, alpha: 1))
        roundedRect(x: 30, y: 14, width: 40, height: 48, radius: 8)
            .fill(with: NSColor(red: 1.0, green: 0.79, blue: 0.32, alpha: 1))
        roundedRect(x: 24, y: 23, width: 52, height: 49, radius: 9)
            .fill(with: NSColor(red: 0.22, green: 0.82, blue: 0.75, alpha: 1))
        roundedRect(x: 31, y: 34, width: 38, height: 42, radius: 9)
            .fill(with: NSColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1))

        roundedRect(x: 38, y: 45, width: 24, height: 3.5, radius: 1.75)
            .fill(with: NSColor(red: 0.76, green: 0.80, blue: 0.88, alpha: 1))
        roundedRect(x: 38, y: 53, width: 19, height: 3.5, radius: 1.75)
            .fill(with: NSColor(red: 0.81, green: 0.84, blue: 0.91, alpha: 1))

        // Raised side rails hold the documents inside the tray.
        sideRail(left: true).fill(with: NSColor(red: 0.23, green: 0.31, blue: 0.47, alpha: 1))
        sideRail(left: false).fill(with: NSColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 1))

        let front = trayFrontPath()
        front.fill(with: NSColor(red: 0.15, green: 0.21, blue: 0.34, alpha: 1))

        // A subtle upper rim makes the notch read as part of the tray.
        let rim = trayRimPath()
        rim.lineWidth = 3
        rim.lineCapStyle = .round
        rim.lineJoinStyle = .round
        NSColor(red: 0.30, green: 0.38, blue: 0.54, alpha: 1).setStroke()
        rim.stroke()

        roundedRect(x: 42, y: 85, width: 16, height: 3.5, radius: 1.75)
            .fill(with: NSColor(red: 0.23, green: 0.94, blue: 0.90, alpha: 1))
    }

    private static func drawOutlineMark() {
        let stroke = NSColor.white

        for (x, y, width) in [(34.0, 8.0, 32.0), (28.0, 17.0, 44.0), (22.0, 26.0, 56.0)] {
            let card = NSBezierPath()
            card.move(to: NSPoint(x: x, y: 51))
            card.line(to: NSPoint(x: x, y: y + 8))
            card.curve(to: NSPoint(x: x + 8, y: y), controlPoint1: NSPoint(x: x, y: y + 3.5), controlPoint2: NSPoint(x: x + 3.5, y: y))
            card.line(to: NSPoint(x: x + width - 8, y: y))
            card.curve(to: NSPoint(x: x + width, y: y + 8), controlPoint1: NSPoint(x: x + width - 3.5, y: y), controlPoint2: NSPoint(x: x + width, y: y + 3.5))
            card.line(to: NSPoint(x: x + width, y: 51))
            card.lineWidth = 5
            card.lineCapStyle = .round
            card.lineJoinStyle = .round
            stroke.setStroke()
            card.stroke()
        }

        let tray = NSBezierPath()
        tray.move(to: NSPoint(x: 13, y: 48))
        tray.line(to: NSPoint(x: 24, y: 87))
        tray.curve(to: NSPoint(x: 31, y: 93), controlPoint1: NSPoint(x: 25, y: 91), controlPoint2: NSPoint(x: 28, y: 93))
        tray.line(to: NSPoint(x: 69, y: 93))
        tray.curve(to: NSPoint(x: 76, y: 87), controlPoint1: NSPoint(x: 72, y: 93), controlPoint2: NSPoint(x: 75, y: 91))
        tray.line(to: NSPoint(x: 87, y: 48))
        tray.line(to: NSPoint(x: 66, y: 48))
        tray.line(to: NSPoint(x: 61, y: 62))
        tray.line(to: NSPoint(x: 39, y: 62))
        tray.line(to: NSPoint(x: 34, y: 48))
        tray.close()
        tray.lineWidth = 5
        tray.lineJoinStyle = .round
        stroke.setStroke()
        tray.stroke()
    }

    /// A transparent blue-and-white variant sized for the edge receiver.
    private static func drawReceiverMark() {
        let blue = NSColor(red: 0.38, green: 0.76, blue: 1.0, alpha: 0.72)
        let white = NSColor.white.withAlphaComponent(0.94)

        roundedRect(x: 34, y: 13, width: 32, height: 41, radius: 7)
            .fill(with: blue)
        roundedRect(x: 29, y: 23, width: 40, height: 43, radius: 8)
            .fill(with: NSColor.white.withAlphaComponent(0.42))
        roundedRect(x: 35, y: 34, width: 30, height: 36, radius: 8)
            .fill(with: NSColor.white.withAlphaComponent(0.86))

        let front = trayFrontPath()
        front.fill(with: NSColor(red: 0.42, green: 0.80, blue: 1.0, alpha: 0.30))
        front.lineWidth = 4.5
        front.lineJoinStyle = .round
        white.setStroke()
        front.stroke()

        let rim = trayRimPath()
        rim.lineWidth = 5
        rim.lineCapStyle = .round
        rim.lineJoinStyle = .round
        white.setStroke()
        rim.stroke()

        roundedRect(x: 42, y: 84, width: 16, height: 3, radius: 1.5)
            .fill(with: NSColor.white.withAlphaComponent(0.92))
    }

    private static func trayFrontPath() -> NSBezierPath {
        let path = trayRimPath()
        path.line(to: NSPoint(x: 89, y: 78))
        path.curve(to: NSPoint(x: 77, y: 92), controlPoint1: NSPoint(x: 89, y: 86), controlPoint2: NSPoint(x: 84, y: 92))
        path.line(to: NSPoint(x: 23, y: 92))
        path.curve(to: NSPoint(x: 11, y: 78), controlPoint1: NSPoint(x: 16, y: 92), controlPoint2: NSPoint(x: 11, y: 86))
        path.close()
        return path
    }

    private static func trayRimPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 11, y: 52))
        path.curve(to: NSPoint(x: 31, y: 49), controlPoint1: NSPoint(x: 18, y: 50), controlPoint2: NSPoint(x: 24, y: 49))
        path.line(to: NSPoint(x: 39, y: 49))
        path.curve(to: NSPoint(x: 46, y: 62), controlPoint1: NSPoint(x: 41, y: 49), controlPoint2: NSPoint(x: 41, y: 62))
        path.line(to: NSPoint(x: 54, y: 62))
        path.curve(to: NSPoint(x: 61, y: 49), controlPoint1: NSPoint(x: 59, y: 62), controlPoint2: NSPoint(x: 59, y: 49))
        path.line(to: NSPoint(x: 69, y: 49))
        path.curve(to: NSPoint(x: 89, y: 52), controlPoint1: NSPoint(x: 76, y: 49), controlPoint2: NSPoint(x: 82, y: 50))
        return path
    }

    private static func sideRail(left: Bool) -> NSBezierPath {
        let path = NSBezierPath()
        if left {
            path.move(to: NSPoint(x: 11, y: 52))
            path.line(to: NSPoint(x: 19, y: 31))
            path.curve(to: NSPoint(x: 25, y: 27), controlPoint1: NSPoint(x: 20, y: 28), controlPoint2: NSPoint(x: 22, y: 27))
            path.line(to: NSPoint(x: 30, y: 27))
            path.line(to: NSPoint(x: 31, y: 49))
        } else {
            path.move(to: NSPoint(x: 89, y: 52))
            path.line(to: NSPoint(x: 81, y: 31))
            path.curve(to: NSPoint(x: 75, y: 27), controlPoint1: NSPoint(x: 80, y: 28), controlPoint2: NSPoint(x: 78, y: 27))
            path.line(to: NSPoint(x: 70, y: 27))
            path.line(to: NSPoint(x: 69, y: 49))
        }
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
    let style: TransferBoxMarkStyle

    init(size: CGFloat, style: TransferBoxMarkStyle = .color) {
        self.size = size
        self.style = style
    }

    var body: some View {
        Image(nsImage: TransferBoxMarkImage.image(size: size, style: style))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
