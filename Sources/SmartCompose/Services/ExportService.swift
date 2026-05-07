import UIKit

/// Exports documents to various formats: PDF, Plain Text, and Rich Text.
final class ExportService {

    static let shared = ExportService()

    private init() {}

    // MARK: - PDF Export

    /// Generates a PDF from the given text content.
    func generatePDF(title: String, content: String) -> Data? {
        let pageWidth: CGFloat = 612  // US Letter width in points
        let pageHeight: CGFloat = 792 // US Letter height in points
        let margin: CGFloat = 72      // 1-inch margins

        let textRect = CGRect(
            x: margin,
            y: margin,
            width: pageWidth - (margin * 2),
            height: pageHeight - (margin * 2)
        )

        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = pdfRenderer.pdfData { context in
            // Title attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            // Body attributes
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            // Date attributes
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.gray
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let dateString = "Generated on \(dateFormatter.string(from: Date()))"

            // Calculate content layout
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            let dateAttrString = NSAttributedString(string: dateString, attributes: dateAttributes)
            let bodyString = NSAttributedString(string: content, attributes: bodyAttributes)

            // Render title page / first page
            context.beginPage()

            // Draw title
            let titleRect = CGRect(
                x: margin,
                y: margin,
                width: textRect.width,
                height: 40
            )
            titleString.draw(in: titleRect)

            // Draw date
            let dateRect = CGRect(
                x: margin,
                y: margin + 45,
                width: textRect.width,
                height: 20
            )
            dateAttrString.draw(in: dateRect)

            // Draw separator line
            let lineY = margin + 70
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(0.5)
            context.cgContext.move(to: CGPoint(x: margin, y: lineY))
            context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: lineY))
            context.cgContext.strokePath()

            // Draw body text with pagination
            let bodyStartY = margin + 85
            let availableHeight = pageHeight - margin - bodyStartY
            let bodyRect = CGRect(
                x: margin,
                y: bodyStartY,
                width: textRect.width,
                height: availableHeight
            )

            // Use NSString for drawing with text container
            let framesetter = CTFramesetterCreateWithAttributedString(bodyString)
            var currentRange = CFRange(location: 0, length: 0)
            var currentY = bodyStartY
            var isFirstPage = true

            while currentRange.location < bodyString.length {
                if !isFirstPage {
                    context.beginPage()
                    currentY = margin
                }

                let frameHeight = isFirstPage ? availableHeight : (pageHeight - margin * 2)
                let framePath = CGPath(
                    rect: CGRect(x: margin, y: 0, width: textRect.width, height: frameHeight),
                    transform: nil
                )

                let frame = CTFramesetterCreateFrame(
                    framesetter,
                    currentRange,
                    framePath,
                    nil
                )

                // Draw the frame
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: currentY + frameHeight)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                CTFrameDraw(frame, context.cgContext)
                context.cgContext.restoreGState()

                // Get the range that was drawn
                let visibleRange = CTFrameGetVisibleStringRange(frame)
                currentRange = CFRange(
                    location: visibleRange.location + visibleRange.length,
                    length: 0
                )

                isFirstPage = false
            }
        }

        return data
    }

    // MARK: - Plain Text Export

    /// Returns the plain text content ready for sharing.
    func generatePlainText(title: String, content: String) -> String {
        return """
        \(title)
        \(String(repeating: "=", count: title.count))

        \(content)

        ---
        Created with SmartCompose
        """
    }

    // MARK: - Rich Text Export

    /// Generates RTF data from the content.
    func generateRTF(title: String, content: String) -> Data? {
        let fullText = "\(title)\n\n\(content)"

        let attributed = NSMutableAttributedString(string: fullText)

        // Style the title
        let titleRange = NSRange(location: 0, length: title.count)
        attributed.addAttributes([
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ], range: titleRange)

        // Style the body
        let bodyRange = NSRange(location: title.count + 2, length: content.count)
        if bodyRange.location + bodyRange.length <= attributed.length {
            attributed.addAttributes([
                .font: UIFont.systemFont(ofSize: 14, weight: .regular)
            ], range: bodyRange)
        }

        return try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    // MARK: - Share Activity Items

    /// Creates the share items for the given export format.
    func shareItems(
        title: String,
        content: String,
        format: ExportFormat
    ) -> [Any] {
        switch format {
        case .pdf:
            if let pdfData = generatePDF(title: title, content: content) {
                return [pdfData]
            }
            return [content]

        case .plainText:
            return [generatePlainText(title: title, content: content)]

        case .richText:
            if let rtfData = generateRTF(title: title, content: content) {
                return [rtfData]
            }
            return [content]
        }
    }
}

/// Export format options.
enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case plainText = "Plain Text"
    case richText = "Rich Text"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .plainText: return "doc.plaintext"
        case .richText: return "doc.richtext"
        }
    }

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .plainText: return "txt"
        case .richText: return "rtf"
        }
    }
}
