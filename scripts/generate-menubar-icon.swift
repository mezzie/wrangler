import AppKit
import CoreGraphics

func renderMenuBarIcon(scale: CGFloat) -> NSImage {
    let size = NSSize(width: 18 * scale, height: 18 * scale)
    let image = NSImage(size: size)

    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    ctx.scaleBy(x: scale, y: scale)

    let strokeColor = NSColor.black.cgColor
    ctx.setStrokeColor(strokeColor)
    ctx.setFillColor(strokeColor)

    // Window 1 (Left): x: 1.5, y: 3.5, w: 6.5, h: 9.5
    let w1Rect = CGRect(x: 1.5, y: 3.5, width: 6.5, height: 9.5)
    let w1Path = CGPath(roundedRect: w1Rect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil)
    ctx.setLineWidth(1.2)
    ctx.addPath(w1Path)
    ctx.strokePath()
    // Window 1 titlebar
    ctx.fill(CGRect(x: 2.2, y: 10.2, width: 5.1, height: 1.5))

    // Window 2 (Right): x: 10.0, y: 3.5, w: 6.5, h: 9.5
    let w2Rect = CGRect(x: 10.0, y: 3.5, width: 6.5, height: 9.5)
    let w2Path = CGPath(roundedRect: w2Rect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil)
    ctx.addPath(w2Path)
    ctx.strokePath()
    // Window 2 titlebar
    ctx.fill(CGRect(x: 10.7, y: 10.2, width: 5.1, height: 1.5))

    // Lasso loop connecting both windows
    let lassoPath = CGMutablePath()
    lassoPath.addEllipse(in: CGRect(x: 4.5, y: 2.0, width: 9.0, height: 13.5))

    ctx.saveGState()
    ctx.setLineWidth(1.1)
    ctx.addPath(lassoPath)
    ctx.strokePath()
    ctx.restoreGState()

    image.unlockFocus()
    image.isTemplate = true
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

let out1x = "/Users/rngo/workspace/wrangler/Sources/WranglerApp/Resources/MenuBarIcon.png"
let out2x = "/Users/rngo/workspace/wrangler/Sources/WranglerApp/Resources/MenuBarIcon@2x.png"

savePNG(image: renderMenuBarIcon(scale: 1.0), path: out1x)
savePNG(image: renderMenuBarIcon(scale: 2.0), path: out2x)

print("Saved MenuBarIcon to Resources.")
