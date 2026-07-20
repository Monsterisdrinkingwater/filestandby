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
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.set()

    fillRoundedRect(NSRect(x: 408, y: 565, width: 208, height: 224), radius: 48, color: NSColor(red: 0.68, green: 0.43, blue: 0.93, alpha: 1))
    fillRoundedRect(NSRect(x: 355, y: 498, width: 314, height: 248), radius: 54, color: NSColor(red: 1.0, green: 0.78, blue: 0.30, alpha: 1))
    fillRoundedRect(NSRect(x: 312, y: 430, width: 400, height: 260), radius: 56, color: NSColor(red: 0.20, green: 0.82, blue: 0.75, alpha: 1))
    fillRoundedRect(NSRect(x: 384, y: 354, width: 256, height: 218), radius: 52, color: .white)
    fillRoundedRect(NSRect(x: 434, y: 484, width: 156, height: 18), radius: 9, color: NSColor(red: 0.78, green: 0.82, blue: 0.89, alpha: 1))
    fillRoundedRect(NSRect(x: 434, y: 442, width: 118, height: 18), radius: 9, color: NSColor(red: 0.82, green: 0.85, blue: 0.91, alpha: 1))
    fillRoundedRect(NSRect(x: 434, y: 400, width: 82, height: 18), radius: 9, color: NSColor(red: 0.86, green: 0.89, blue: 0.94, alpha: 1))

    polygon([.init(x: 250, y: 465), .init(x: 310, y: 570), .init(x: 370, y: 570), .init(x: 338, y: 420)])
        .fill(with: NSColor(red: 0.18, green: 0.25, blue: 0.40, alpha: 1))
    polygon([.init(x: 774, y: 465), .init(x: 714, y: 570), .init(x: 654, y: 570), .init(x: 686, y: 420)])
        .fill(with: NSColor(red: 0.08, green: 0.12, blue: 0.21, alpha: 1))

    let front = NSBezierPath()
    front.move(to: NSPoint(x: 250, y: 465))
    front.line(to: NSPoint(x: 370, y: 405))
    front.line(to: NSPoint(x: 452, y: 405))
    front.curve(to: NSPoint(x: 512, y: 350), controlPoint1: NSPoint(x: 458, y: 405), controlPoint2: NSPoint(x: 458, y: 350))
    front.curve(to: NSPoint(x: 572, y: 405), controlPoint1: NSPoint(x: 566, y: 350), controlPoint2: NSPoint(x: 566, y: 405))
    front.line(to: NSPoint(x: 654, y: 405))
    front.line(to: NSPoint(x: 774, y: 465))
    front.line(to: NSPoint(x: 774, y: 280))
    front.curve(to: NSPoint(x: 698, y: 204), controlPoint1: NSPoint(x: 774, y: 236), controlPoint2: NSPoint(x: 740, y: 204))
    front.line(to: NSPoint(x: 326, y: 204))
    front.curve(to: NSPoint(x: 250, y: 280), controlPoint1: NSPoint(x: 284, y: 204), controlPoint2: NSPoint(x: 250, y: 236))
    front.close()
    front.fill(with: NSColor(red: 0.12, green: 0.18, blue: 0.30, alpha: 1))
    fillRoundedRect(NSRect(x: 455, y: 262, width: 114, height: 22), radius: 11, color: NSColor(red: 0.20, green: 0.95, blue: 0.92, alpha: 1))

}

func fillRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
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
