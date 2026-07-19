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
            NSColor(red: 0.09, green: 0.38, blue: 1.0, alpha: 1),
            NSColor(red: 0.12, green: 0.68, blue: 1.0, alpha: 1)
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

    NSColor.white.withAlphaComponent(0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: 244, y: 244, width: 536, height: 536)).fill()

    drawOriginalStandbyMark()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw IconError.cannotEncodePNG
    }
    return data
}

func drawOriginalStandbyMark() {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowBlurRadius = 22
    shadow.shadowOffset = NSSize(width: 0, height: -12)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()

    let leftLid = NSBezierPath()
    leftLid.move(to: NSPoint(x: 292, y: 558))
    leftLid.line(to: NSPoint(x: 420, y: 710))
    leftLid.line(to: NSPoint(x: 516, y: 640))
    leftLid.line(to: NSPoint(x: 398, y: 500))
    leftLid.close()
    NSColor(red: 0.86, green: 0.95, blue: 1.0, alpha: 1).setFill()
    leftLid.fill()

    let rightLid = NSBezierPath()
    rightLid.move(to: NSPoint(x: 732, y: 558))
    rightLid.line(to: NSPoint(x: 604, y: 710))
    rightLid.line(to: NSPoint(x: 508, y: 640))
    rightLid.line(to: NSPoint(x: 626, y: 500))
    rightLid.close()
    NSColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1).setFill()
    rightLid.fill()

    let leftFace = NSBezierPath()
    leftFace.move(to: NSPoint(x: 298, y: 516))
    leftFace.line(to: NSPoint(x: 512, y: 392))
    leftFace.line(to: NSPoint(x: 512, y: 238))
    leftFace.line(to: NSPoint(x: 334, y: 324))
    leftFace.close()
    NSColor(red: 0.78, green: 0.91, blue: 1.0, alpha: 1).setFill()
    leftFace.fill()

    let rightFace = NSBezierPath()
    rightFace.move(to: NSPoint(x: 726, y: 516))
    rightFace.line(to: NSPoint(x: 512, y: 392))
    rightFace.line(to: NSPoint(x: 512, y: 238))
    rightFace.line(to: NSPoint(x: 690, y: 324))
    rightFace.close()
    NSColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 1).setFill()
    rightFace.fill()

    let inside = NSBezierPath()
    inside.move(to: NSPoint(x: 298, y: 516))
    inside.line(to: NSPoint(x: 512, y: 634))
    inside.line(to: NSPoint(x: 726, y: 516))
    inside.line(to: NSPoint(x: 512, y: 392))
    inside.close()
    NSColor(red: 0.17, green: 0.48, blue: 0.96, alpha: 1).setFill()
    inside.fill()

    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.85).setStroke()
    let rim = NSBezierPath()
    rim.lineWidth = 24
    rim.lineCapStyle = .round
    rim.lineJoinStyle = .round
    rim.move(to: NSPoint(x: 304, y: 516))
    rim.line(to: NSPoint(x: 512, y: 392))
    rim.line(to: NSPoint(x: 720, y: 516))
    rim.stroke()

    NSColor(red: 1.0, green: 0.72, blue: 0.24, alpha: 1).setStroke()
    let transferBand = NSBezierPath()
    transferBand.lineWidth = 40
    transferBand.lineCapStyle = .round
    transferBand.move(to: NSPoint(x: 382, y: 356))
    transferBand.line(to: NSPoint(x: 472, y: 312))
    transferBand.stroke()

    let bandTip = NSBezierPath()
    bandTip.move(to: NSPoint(x: 488, y: 300))
    bandTip.line(to: NSPoint(x: 432, y: 286))
    bandTip.line(to: NSPoint(x: 458, y: 338))
    bandTip.close()
    NSColor(red: 1.0, green: 0.72, blue: 0.24, alpha: 1).setFill()
    bandTip.fill()

    NSColor(red: 1.0, green: 0.72, blue: 0.24, alpha: 1).setStroke()
    let returnBand = NSBezierPath()
    returnBand.lineWidth = 40
    returnBand.lineCapStyle = .round
    returnBand.move(to: NSPoint(x: 642, y: 356))
    returnBand.line(to: NSPoint(x: 552, y: 312))
    returnBand.stroke()

    let returnTip = NSBezierPath()
    returnTip.move(to: NSPoint(x: 536, y: 300))
    returnTip.line(to: NSPoint(x: 592, y: 286))
    returnTip.line(to: NSPoint(x: 566, y: 338))
    returnTip.close()
    NSColor(red: 1.0, green: 0.72, blue: 0.24, alpha: 1).setFill()
    returnTip.fill()
}

enum IconError: Error {
    case cannotCreateBitmap
    case cannotEncodePNG
}
