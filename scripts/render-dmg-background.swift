#!/usr/bin/env swift

// Development-only script. Renders the DMG installer window background.
// Usage:
//   swift scripts/render-dmg-background.swift <output.png> <scale>
// <scale> is 1 or 2 (2 = @2x retina). Layout must match
// scripts/dmg-layout.applescript: a 640x400 window with the app icon at
// {170,175} and Applications at {470,175} (Finder/top-left point coordinates).
// The window shows only the app icon, an arrow, and the Applications folder;
// Finder draws the item labels, so this background carries just the arrow.

import AppKit

let args = CommandLine.arguments
guard args.count == 3, let scale = Int(args[2]), scale >= 1 else {
    fputs("Usage: render-dmg-background.swift <output.png> <scale:1|2>\n", stderr)
    exit(1)
}
let outputPath = args[1]

// Window content size in points (must match the AppleScript window bounds).
let W: CGFloat = 640
let H: CGFloat = 400

// Icon centre height, Finder/top-left coordinates (must match the AppleScript).
let iconCenterTopY: CGFloat = 175

// CoreGraphics uses a bottom-left origin.
let midY = H - iconCenterTopY

let pxW = Int(W * CGFloat(scale))
let pxH = Int(H * CGFloat(scale))
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pxW, pixelsHigh: pxH,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else {
    fputs("Failed to create bitmap rep\n", stderr)
    exit(1)
}
rep.size = NSSize(width: W, height: H) // draw in points; context scales to pixels

guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
    fputs("Failed to create graphics context\n", stderr)
    exit(1)
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx

// --- Background: flat warm off-white (matches the neutral installer look) ---
NSColor(calibratedRed: 0.925, green: 0.918, blue: 0.894, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()

// --- A single clean arrow from the app toward the Applications folder ---
// Icon size is 160, so edges sit ~80pt from each centre (x=170 and x=470),
// leaving a gap around x=250..390. Keep the arrow inside that gap.
let arrowColor = NSColor(calibratedWhite: 0.28, alpha: 1)
let shaftLeft: CGFloat = 285
let shaftRight: CGFloat = 342
let tipX: CGFloat = 372
let shaftHalf: CGFloat = 7
let headHalf: CGFloat = 21

let arrow = NSBezierPath()
arrow.move(to: CGPoint(x: shaftLeft, y: midY - shaftHalf))
arrow.line(to: CGPoint(x: shaftRight, y: midY - shaftHalf))
arrow.line(to: CGPoint(x: shaftRight, y: midY - headHalf))
arrow.line(to: CGPoint(x: tipX, y: midY))
arrow.line(to: CGPoint(x: shaftRight, y: midY + headHalf))
arrow.line(to: CGPoint(x: shaftRight, y: midY + shaftHalf))
arrow.line(to: CGPoint(x: shaftLeft, y: midY + shaftHalf))
arrow.close()
arrow.lineJoinStyle = .round
arrowColor.setFill()
arrow.fill()

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}
do {
    try data.write(to: URL(fileURLWithPath: outputPath))
    print("DMG background written to \(outputPath) (\(pxW)x\(pxH))")
} catch {
    fputs("Error writing \(outputPath): \(error)\n", stderr)
    exit(1)
}
