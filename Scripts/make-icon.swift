import AppKit

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppIcon.png")
let size = NSSize(width: 1024, height: 1024)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 1024,
    pixelsHigh: 1024,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else { fatalError("Não foi possível criar o ícone") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let outer = NSBezierPath(roundedRect: NSRect(x: 52, y: 52, width: 920, height: 920), xRadius: 210, yRadius: 210)
NSGradient(
    starting: NSColor(red: 0.145, green: 0.405, blue: 0.78, alpha: 1),
    ending: NSColor(red: 0.086, green: 0.225, blue: 0.525, alpha: 1)
)?.draw(in: outer, angle: -45)

NSColor.white.setStroke()
let monitor = NSBezierPath(roundedRect: NSRect(x: 220, y: 355, width: 584, height: 394), xRadius: 44, yRadius: 44)
monitor.lineWidth = 42
monitor.stroke()

func line(from start: NSPoint, to end: NSPoint, width: CGFloat, alpha: CGFloat = 1) {
    NSColor.white.withAlphaComponent(alpha).setStroke()
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    path.lineWidth = width
    path.lineCapStyle = .round
    path.stroke()
}

line(from: NSPoint(x: 322, y: 269), to: NSPoint(x: 702, y: 269), width: 42)
line(from: NSPoint(x: 512, y: 355), to: NSPoint(x: 512, y: 269), width: 42)
line(from: NSPoint(x: 365, y: 552), to: NSPoint(x: 659, y: 552), width: 32, alpha: 0.96)
line(from: NSPoint(x: 431, y: 633), to: NSPoint(x: 593, y: 633), width: 32, alpha: 0.62)
line(from: NSPoint(x: 431, y: 471), to: NSPoint(x: 593, y: 471), width: 32, alpha: 0.62)
NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG inválido") }
try data.write(to: outputURL)
