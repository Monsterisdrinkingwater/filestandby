#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("用法：generate-app-icon.swift <输出PNG路径>\n".utf8))
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
let png = try renderIcon(pixels: 1_024)
try png.write(to: outputURL, options: .atomic)

func renderIcon(pixels: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw IconError.cannotCreateBitmap
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }

    context.cgContext.clear(CGRect(x: 0, y: 0, width: pixels, height: pixels))
    let scale = CGFloat(pixels) / 1_024
    context.cgContext.scaleBy(x: scale, y: scale)

    let iconRect = NSRect(x: 64, y: 64, width: 896, height: 896)
    let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 224, yRadius: 224)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -16)
    shadow.set()
    NSGradient(
        colors: [
            NSColor(red: 0.07, green: 0.11, blue: 0.20, alpha: 1),
            NSColor(red: 0.15, green: 0.22, blue: 0.37, alpha: 1)
        ]
    )?.draw(in: iconPath, angle: -55)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.14).setStroke()
    let highlight = NSBezierPath(
        roundedRect: iconRect.insetBy(dx: 4, dy: 4),
        xRadius: 220,
        yRadius: 220
    )
    highlight.lineWidth = 8
    highlight.stroke()

    NSColor(red: 0.28, green: 0.42, blue: 0.66, alpha: 0.20).setFill()
    NSBezierPath(ovalIn: NSRect(x: 210, y: 182, width: 604, height: 604)).fill()

    drawOriginalStandbyMark()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw IconError.cannotEncodePNG
    }
    return data
}

func drawOriginalStandbyMark() {
    let cavity = NSBezierPath()
    cavity.move(to: NSPoint(x: 270, y: 492))
    cavity.line(to: NSPoint(x: 322, y: 650))
    cavity.curve(to: NSPoint(x: 374, y: 686), controlPoint1: NSPoint(x: 331, y: 676), controlPoint2: NSPoint(x: 350, y: 686))
    cavity.line(to: NSPoint(x: 650, y: 686))
    cavity.curve(to: NSPoint(x: 702, y: 650), controlPoint1: NSPoint(x: 674, y: 686), controlPoint2: NSPoint(x: 693, y: 676))
    cavity.line(to: NSPoint(x: 754, y: 492))
    cavity.line(to: NSPoint(x: 710, y: 348))
    cavity.line(to: NSPoint(x: 314, y: 348))
    cavity.close()
    fillPath(cavity, colors: [
        NSColor(red: 0.12, green: 0.18, blue: 0.29, alpha: 1),
        NSColor(red: 0.025, green: 0.045, blue: 0.085, alpha: 1)
    ], angle: 90)

    fillRoundedRectGradient(NSRect(x: 407, y: 604, width: 210, height: 190), radius: 48, colors: [
        NSColor(red: 0.75, green: 0.52, blue: 0.96, alpha: 1),
        NSColor(red: 0.60, green: 0.32, blue: 0.86, alpha: 1)
    ])
    fillRoundedRectGradient(NSRect(x: 366, y: 548, width: 292, height: 207), radius: 50, colors: [
        NSColor(red: 1.0, green: 0.87, blue: 0.49, alpha: 1),
        NSColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 1)
    ])
    fillRoundedRectGradient(NSRect(x: 337, y: 487, width: 350, height: 222), radius: 52, colors: [
        NSColor(red: 0.42, green: 0.92, blue: 0.86, alpha: 1),
        NSColor(red: 0.12, green: 0.72, blue: 0.66, alpha: 1)
    ])
    fillRoundedRectGradient(NSRect(x: 402, y: 402, width: 220, height: 227), radius: 48, colors: [
        .white,
        NSColor(red: 0.88, green: 0.92, blue: 0.98, alpha: 1)
    ])
    fillRoundedRect(NSRect(x: 444, y: 541, width: 136, height: 17), radius: 8.5, color: NSColor(red: 0.76, green: 0.80, blue: 0.88, alpha: 1))
    fillRoundedRect(NSRect(x: 444, y: 496, width: 108, height: 17), radius: 8.5, color: NSColor(red: 0.81, green: 0.84, blue: 0.91, alpha: 1))
    fillRoundedRect(NSRect(x: 444, y: 451, width: 74, height: 17), radius: 8.5, color: NSColor(red: 0.85, green: 0.88, blue: 0.94, alpha: 1))

    let leftRail = polygon([.init(x: 270, y: 505), .init(x: 316, y: 643), .init(x: 350, y: 663), .init(x: 382, y: 491), .init(x: 350, y: 477)])
    fillPath(leftRail, colors: [
        NSColor(red: 0.32, green: 0.42, blue: 0.60, alpha: 1),
        NSColor(red: 0.15, green: 0.22, blue: 0.36, alpha: 1)
    ], angle: 25)
    let rightRail = polygon([.init(x: 754, y: 505), .init(x: 708, y: 643), .init(x: 674, y: 663), .init(x: 642, y: 491), .init(x: 674, y: 477)])
    fillPath(rightRail, colors: [
        NSColor(red: 0.18, green: 0.26, blue: 0.40, alpha: 1),
        NSColor(red: 0.07, green: 0.11, blue: 0.19, alpha: 1)
    ], angle: 155)

    let front = trayFrontPath()
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.38)
    shadow.shadowBlurRadius = 30
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.set()
    fillPath(front, colors: [
        NSColor(red: 0.20, green: 0.28, blue: 0.43, alpha: 1),
        NSColor(red: 0.11, green: 0.16, blue: 0.27, alpha: 1)
    ], angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    let rim = trayRimPath()
    rim.lineWidth = 16
    rim.lineCapStyle = .round
    rim.lineJoinStyle = .round
    NSColor(red: 0.31, green: 0.40, blue: 0.57, alpha: 1).setStroke()
    rim.stroke()

    NSGraphicsContext.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = NSColor(red: 0.20, green: 0.95, blue: 0.92, alpha: 0.72)
    glow.shadowBlurRadius = 18
    glow.shadowOffset = .zero
    glow.set()
    fillRoundedRect(NSRect(x: 455, y: 268, width: 114, height: 22), radius: 11, color: NSColor(red: 0.28, green: 0.98, blue: 0.94, alpha: 1))
    NSGraphicsContext.restoreGraphicsState()

}

func trayRimPath() -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 270, y: 505))
    path.curve(to: NSPoint(x: 384, y: 486), controlPoint1: NSPoint(x: 310, y: 492), controlPoint2: NSPoint(x: 346, y: 486))
    path.line(to: NSPoint(x: 420, y: 486))
    path.curve(to: NSPoint(x: 460, y: 430), controlPoint1: NSPoint(x: 443, y: 486), controlPoint2: NSPoint(x: 442, y: 430))
    path.line(to: NSPoint(x: 564, y: 430))
    path.curve(to: NSPoint(x: 604, y: 486), controlPoint1: NSPoint(x: 582, y: 430), controlPoint2: NSPoint(x: 581, y: 486))
    path.line(to: NSPoint(x: 640, y: 486))
    path.curve(to: NSPoint(x: 754, y: 505), controlPoint1: NSPoint(x: 678, y: 486), controlPoint2: NSPoint(x: 714, y: 492))
    return path
}

func trayFrontPath() -> NSBezierPath {
    let path = trayRimPath()
    path.line(to: NSPoint(x: 754, y: 292))
    path.curve(to: NSPoint(x: 688, y: 222), controlPoint1: NSPoint(x: 754, y: 252), controlPoint2: NSPoint(x: 727, y: 222))
    path.line(to: NSPoint(x: 336, y: 222))
    path.curve(to: NSPoint(x: 270, y: 292), controlPoint1: NSPoint(x: 297, y: 222), controlPoint2: NSPoint(x: 270, y: 252))
    path.close()
    return path
}

func fillRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func fillRoundedRectGradient(_ rect: NSRect, radius: CGFloat, colors: [NSColor]) {
    fillPath(NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius), colors: colors, angle: 90)
}

func fillPath(_ path: NSBezierPath, colors: [NSColor], angle: CGFloat) {
    NSGradient(colors: colors)?.draw(in: path, angle: angle)
}

func polygon(_ points: [NSPoint]) -> NSBezierPath {
    let path = NSBezierPath()
    guard let first = points.first else { return path }
    path.move(to: first)
    points.dropFirst().forEach(path.line(to:))
    path.close()
    return path
}

private extension NSBezierPath {
    func fill(with color: NSColor) {
        color.setFill()
        fill()
    }
}

enum IconError: Error {
    case cannotCreateBitmap
    case cannotEncodePNG
}
