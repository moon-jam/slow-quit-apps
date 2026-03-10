#!/usr/bin/env swift
// SlowQuitApps icon generation script
// Generates a simple icon with the letter Q and a circular progress bar

import Cocoa
import Foundation

// Icon size list (all sizes required for macOS icns)
let sizes: [(size: Int, scale: Int, suffix: String)] = [
    (16, 1, "16x16"),
    (16, 2, "16x16@2x"),
    (32, 1, "32x32"),
    (32, 2, "32x32@2x"),
    (128, 1, "128x128"),
    (128, 2, "128x128@2x"),
    (256, 1, "256x256"),
    (256, 2, "256x256@2x"),
    (512, 1, "512x512"),
    (512, 2, "512x512@2x")
]

/// Generates an icon of a single size
/// Design philosophy: Apple style - simple, flat, high recognition
func generateIcon(size: Int, scale: Int) -> NSImage {
    let pixelSize = size * scale
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    
    image.lockFocus()
    
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    let rect = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let padding = CGFloat(pixelSize) * 0.08
    let mainRect = rect.insetBy(dx: padding, dy: padding)
    
    // Background - rounded rectangle, macOS system blue
    let cornerRadius = CGFloat(pixelSize) * 0.22
    let bgPath = NSBezierPath(roundedRect: mainRect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Pure system blue background (Apple standard blue)
    let systemBlue = NSColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    systemBlue.setFill()
    bgPath.fill()
    
    // Center ring background
    let center = CGPoint(x: CGFloat(pixelSize) / 2, y: CGFloat(pixelSize) / 2)
    let ringRadius = CGFloat(pixelSize) * 0.28
    let ringWidth = CGFloat(pixelSize) * 0.05
    
    // Ring background (translucent white track)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
    context.setLineWidth(ringWidth)
    context.addArc(center: center, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    context.strokePath()
    
    // Progress arc (75% white)
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(ringWidth)
    context.setLineCap(.round)
    let startAngle = CGFloat.pi / 2  // Start from top
    let endAngle = startAngle - CGFloat.pi * 1.5  // Clockwise 75%
    context.addArc(center: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    context.strokePath()
    
    // Center letter Q (SF Pro style)
    let fontSize = CGFloat(pixelSize) * 0.30
    let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
    let qText = "Q" as NSString
    
    let textAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    
    let textSize = qText.size(withAttributes: textAttributes)
    let textRect = CGRect(
        x: center.x - textSize.width / 2,
        y: center.y - textSize.height / 2,
        width: textSize.width,
        height: textSize.height
    )
    qText.draw(in: textRect, withAttributes: textAttributes)
    
    image.unlockFocus()
    return image
}

/// Saves NSImage as PNG
func savePNG(image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("❌ Failed to generate PNG: \(path)")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
    } catch {
        print("❌ Failed to save: \(error)")
    }
}

// Main program
print("🎨 Starting generation of SlowQuitApps icon...")

// Create temporary iconset directory
let iconsetDir = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Generate icons of all sizes
for (size, scale, suffix) in sizes {
    let image = generateIcon(size: size, scale: scale)
    let filename = "\(iconsetDir)/icon_\(suffix).png"
    savePNG(image: image, to: filename)
    print("✓ Generated \(suffix)")
}

// Convert to icns using iconutil
print("📦 Converting to icns format...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir, "-o", "BuildAssets/AppIcon.icns"]

do {
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ Icon generated: BuildAssets/AppIcon.icns")
    } else {
        print("❌ iconutil failed")
    }
} catch {
    print("❌ Execution failed: \(error)")
}

// Clean temporary files
try? FileManager.default.removeItem(atPath: iconsetDir)
print("🧹 Temporary files cleaned")
