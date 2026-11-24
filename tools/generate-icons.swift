// Generates the app icon and launch logo from code so they are reproducible.
// Usage: swift tools/generate-icons.swift
import AppKit

let assets = "Catalogy/Catalogy/Assets.xcassets"
let coralTop = NSColor(srgbRed: 0.98, green: 0.45, blue: 0.47, alpha: 1)
let coralBottom = NSColor(srgbRed: 0.85, green: 0.22, blue: 0.36, alpha: 1)

func render(size: CGFloat, background: Bool, glyphColor: NSColor, glyphScale: CGFloat, to path: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)

    if background {
        NSGradient(starting: coralTop, ending: coralBottom)!.draw(in: rect, angle: -90)
        // Soft highlight for depth
        NSColor.white.withAlphaComponent(0.10).setFill()
        NSBezierPath(ovalIn: NSRect(x: -size * 0.2, y: size * 0.45, width: size * 1.4, height: size)).fill()
    }

    let config = NSImage.SymbolConfiguration(pointSize: size * glyphScale, weight: .semibold)
        .applying(.init(paletteColors: [glyphColor]))
    if let symbol = NSImage(systemSymbolName: "bag.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let s = symbol.size
        symbol.draw(in: NSRect(x: (size - s.width) / 2, y: (size - s.height) / 2 - size * 0.02,
                               width: s.width, height: s.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

// App icon: light, dark, tinted
render(size: 1024, background: true, glyphColor: .white, glyphScale: 0.46, to: "\(assets)/AppIcon.appiconset/AppIcon.png")
render(size: 1024, background: false, glyphColor: coralTop, glyphScale: 0.46, to: "\(assets)/AppIcon.appiconset/AppIcon-Dark.png")
render(size: 1024, background: false, glyphColor: .white, glyphScale: 0.46, to: "\(assets)/AppIcon.appiconset/AppIcon-Tinted.png")
// Launch / splash logo (transparent, white glyph)
render(size: 360, background: false, glyphColor: .white, glyphScale: 0.6, to: "\(assets)/LaunchLogo.imageset/LaunchLogo.png")
print("Icons generated")
