import AppKit
import CoreGraphics

func renderIcon(size: Int) -> NSImage {
    let dim = CGFloat(size)
    let image = NSImage(size: NSSize(width: dim, height: dim))

    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    ctx.saveGState()

    let scale = dim / 1024.0

    // 1. Squircle background (Apple standard bounds: inset by 80px at 1024x1024)
    let inset: CGFloat = 82.0 * scale
    let squircleRect = CGRect(x: inset, y: inset, width: dim - (inset * 2), height: dim - (inset * 2))
    let cornerRadius: CGFloat = 185.0 * scale
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Squircle shadow
    ctx.setShadow(
        offset: CGSize(width: 0, height: -12.0 * scale),
        blur: 24.0 * scale,
        color: NSColor.black.withAlphaComponent(0.45).cgColor
    )

    // Base dark gradient
    ctx.addPath(squirclePath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 1.0).cgColor,
        NSColor(red: 0.06, green: 0.08, blue: 0.13, alpha: 1.0).cgColor
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: dim), end: CGPoint(x: 0, y: 0), options: [])

    // Inner subtle glow/border
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    ctx.setLineWidth(2.0 * scale)
    ctx.strokePath()

    // 2. Draw 3x3 Grid inside the squircle
    let gridCenter = CGPoint(x: dim / 2, y: dim / 2)
    let gridTotalSize: CGFloat = 460.0 * scale
    let gridOrigin = CGPoint(x: gridCenter.x - gridTotalSize / 2, y: gridCenter.y - gridTotalSize / 2)
    let cellGap: CGFloat = 20.0 * scale
    let cellSize = (gridTotalSize - cellGap * 2) / 3.0
    let cellRadius: CGFloat = 20.0 * scale

    for r in 0..<3 {
        for c in 0..<3 {
            let x = gridOrigin.x + CGFloat(c) * (cellSize + cellGap)
            let y = gridOrigin.y + CGFloat(2 - r) * (cellSize + cellGap)
            let cellRect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
            let cellPath = CGPath(roundedRect: cellRect, cornerWidth: cellRadius, cornerHeight: cellRadius, transform: nil)

            // Highlight the active snapped tile (e.g. left two thirds or center)
            let isActive = (c == 0 && r < 2) || (c == 1 && r == 0) // Snapped grouping

            if isActive {
                // Vibrant active cell gradient (Cyan to Blue)
                let cellColors = [
                    NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0).cgColor,
                    NSColor(red: 0.08, green: 0.44, blue: 0.92, alpha: 1.0).cgColor
                ] as CFArray
                let cellGradient = CGGradient(colorsSpace: colorSpace, colors: cellColors, locations: [0.0, 1.0])!
                ctx.saveGState()
                ctx.addPath(cellPath)
                ctx.clip()
                ctx.drawLinearGradient(cellGradient, start: CGPoint(x: x, y: y + cellSize), end: CGPoint(x: x, y: y), options: [])
                ctx.restoreGState()

                // Cell glow border
                ctx.addPath(cellPath)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.6).cgColor)
                ctx.setLineWidth(2.5 * scale)
                ctx.strokePath()
            } else {
                // Translucent passive cell
                ctx.addPath(cellPath)
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.08).cgColor)
                ctx.fillPath()

                ctx.addPath(cellPath)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.12).cgColor)
                ctx.setLineWidth(1.5 * scale)
                ctx.strokePath()
            }
        }
    }

    // 3. Golden Lasso Curve around grid
    let lassoPath = CGMutablePath()
    let arcCenter = CGPoint(x: gridCenter.x + 80.0 * scale, y: gridCenter.y - 60.0 * scale)
    lassoPath.addEllipse(in: CGRect(
        x: arcCenter.x - 220.0 * scale,
        y: arcCenter.y - 140.0 * scale,
        width: 440.0 * scale,
        height: 280.0 * scale
    ))

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -4.0 * scale),
        blur: 12.0 * scale,
        color: NSColor(red: 0.96, green: 0.75, blue: 0.26, alpha: 0.5).cgColor
    )
    ctx.addPath(lassoPath)
    ctx.setStrokeColor(NSColor(red: 0.98, green: 0.78, blue: 0.32, alpha: 0.85).cgColor)
    ctx.setLineWidth(8.0 * scale)
    ctx.setLineDash(phase: 0, lengths: [24.0 * scale, 12.0 * scale])
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState()
    image.unlockFocus()

    return image
}

func savePNG(image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        return
    }
    try? png.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
let iconsetDir = "/tmp/AppIcon.iconset"
try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

print("Rendering iconset...")
for (name, s) in sizes {
    let img = renderIcon(size: s)
    savePNG(image: img, path: "\(iconsetDir)/\(name)")
}

let outputPath = "/Users/rngo/workspace/wrangler/Sources/WranglerApp/Resources/AppIcon.icns"
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir, "-o", outputPath]
try process.run()
process.waitUntilExit()

try? fm.removeItem(atPath: iconsetDir)
print("Created AppIcon.icns at \(outputPath) with exit status \(process.terminationStatus)")
