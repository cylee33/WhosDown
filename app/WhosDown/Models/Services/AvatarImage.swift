import UIKit

/// Turns a picked photo into the avatar we upload: a centered 512 × 512 square JPEG (1.4 rule 4).
nonisolated enum AvatarImage {
    static let side: CGFloat = 512

    static func jpegData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let shortest = min(image.size.width, image.size.height)
        guard shortest > 0 else { return nil }
        let scale = side / shortest
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (side - drawSize.width) / 2, y: (side - drawSize.height) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.jpegData(withCompressionQuality: 0.8) { _ in
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }
}
