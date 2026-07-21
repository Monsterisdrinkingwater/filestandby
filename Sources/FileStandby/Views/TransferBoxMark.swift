import AppKit
import SwiftUI

enum TransferBoxMarkStyle {
    case color
    case receiver
}

/// Uses the shipped application icon everywhere except the blue edge receiver,
/// which needs a transparent high-contrast variant at a much smaller size.
enum TransferBoxMarkImage {
    static func image(size: CGFloat, style: TransferBoxMarkStyle) -> NSImage {
        switch style {
        case .color:
            if let iconURL = Bundle.main.url(forResource: "FileStandby", withExtension: "icns"),
               let icon = NSImage(contentsOf: iconURL) {
                icon.size = NSSize(width: size, height: size)
                return icon
            }

            let fallback = NSImage(systemSymbolName: "tray.full.fill", accessibilityDescription: "File Standby") ?? NSImage()
            fallback.size = NSSize(width: size, height: size)
            return fallback

        case .receiver:
            let scale: CGFloat = 4
            let image = NSImage(size: NSSize(width: size * scale, height: size * scale))
            image.lockFocus()
            draw(in: NSRect(origin: .zero, size: image.size), style: .receiver)
            image.unlockFocus()
            image.size = NSSize(width: size, height: size)
            return image
        }
    }

    static func draw(in rect: NSRect, style: TransferBoxMarkStyle) {
        switch style {
        case .color:
            image(size: min(rect.width, rect.height), style: .color).draw(in: rect)

        case .receiver:
            guard rect.width > 0, rect.height > 0,
                  let context = NSGraphicsContext.current?.cgContext
            else { return }

            context.saveGState()
            context.translateBy(x: rect.minX, y: rect.minY)
            context.scaleBy(x: rect.width / 100, y: rect.height / 100)
            context.translateBy(x: 0, y: 100)
            context.scaleBy(x: 1, y: -1)
            defer { context.restoreGState() }

            drawReceiverMark()
        }
    }

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
