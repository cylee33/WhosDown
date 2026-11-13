// Draws the WhosDown app icon: a line-art soccer ball on the brandSoft background,
// matching the Welcome screen. Original geometry (SF Symbols may not be used in app icons).
import AppKit

let size: CGFloat = 1024
// Run: swiftc scripts/make_app_icon.swift -o /tmp/make_icon && /tmp/make_icon app/WhosDown/Assets.xcassets/AppIcon.appiconset/AppIcon.png
let out = CommandLine.arguments[1]

let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

// brandSoft background, full bleed (iOS rounds the corners).
ctx.setFillColor(CGColor(red: 0.89, green: 0.97, blue: 0.91, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let c = CGPoint(x: size / 2, y: size / 2)
let R: CGFloat = 330          // ball radius
let r: CGFloat = 105          // centre pentagon radius
let d: CGFloat = 0.70 * R     // where the seams split
func pt(_ radius: CGFloat, _ degrees: CGFloat) -> CGPoint {
    let a = degrees * .pi / 180
    return CGPoint(x: c.x + radius * cos(a), y: c.y + radius * sin(a))
}

// Ball: white fill, textPrimary line.
ctx.setFillColor(.white)
ctx.fillEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R))
let ink = CGColor(red: 0.07, green: 0.09, blue: 0.15, alpha: 1)
ctx.setStrokeColor(ink)
ctx.setLineWidth(30)
ctx.setLineJoin(.round)
ctx.setLineCap(.round)

// Centre pentagon, point up, filled.
let angles = (0..<5).map { 90 + CGFloat($0) * 72 }
ctx.beginPath()
for (i, a) in angles.enumerated() { i == 0 ? ctx.move(to: pt(r, a)) : ctx.addLine(to: pt(r, a)) }
ctx.closePath()
ctx.setFillColor(ink)
ctx.drawPath(using: .fillStroke)

// Seams: from each pentagon corner out, then splitting toward the rim.
for a in angles {
    ctx.move(to: pt(r, a)); ctx.addLine(to: pt(d, a))
    for side: CGFloat in [-1, 1] {
        ctx.move(to: pt(d, a)); ctx.addLine(to: pt(R, a + side * 22))
    }
}
ctx.strokePath()

// Rim.
ctx.strokeEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R))

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
