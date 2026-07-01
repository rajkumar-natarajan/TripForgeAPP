import UIKit

/// Renders a Trip into a paginated, print-ready PDF (US Letter) and returns
/// the file URL for the share/print sheet.
enum PDFExport {

    // Page geometry (US Letter @ 72 dpi).
    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin: CGFloat = 48

    // Brand colors (mirror Theme.Brand, in UIKit).
    private static let teal = UIColor(red: 0x0F/255, green: 0x76/255, blue: 0x6E/255, alpha: 1)
    private static let orange = UIColor(red: 0xF9/255, green: 0x73/255, blue: 0x16/255, alpha: 1)
    private static let ink = UIColor(red: 0x0D/255, green: 0x14/255, blue: 0x1B/255, alpha: 1)
    private static let subtle = UIColor(white: 0.42, alpha: 1)

    /// Writes the itinerary PDF to a temp file and returns its URL.
    static func write(for trip: Trip) -> URL? {
        let data = render(trip)
        let name = slug(trip.title)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: Rendering

    private static func render(_ trip: Trip) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: trip.title,
            kCGPDFContextCreator as String: "TripForge"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        return renderer.pdfData { ctx in
            var page = PageCursor(renderer: ctx, contentWidth: pageWidth - margin * 2,
                                  top: margin, bottom: pageHeight - margin, left: margin)
            page.begin()

            drawCoverHeader(trip, on: &page)

            for (i, day) in trip.days.enumerated() {
                page.ensureSpace(64)
                drawDayHeader(day, index: i, on: &page)
                if day.activities.isEmpty {
                    page.drawParagraph("No activities planned.", font: .italicSystemFont(ofSize: 11),
                                       color: subtle)
                }
                for act in day.activities {
                    drawActivity(act, currency: trip.currency, on: &page)
                }
                page.advance(10)
            }

            if !trip.packingList.isEmpty {
                page.ensureSpace(60)
                page.advance(6)
                page.drawSectionTitle("Packing list")
                drawPackingList(trip.packingList, on: &page)
            }
        }
    }

    private static func drawCoverHeader(_ trip: Trip, on page: inout PageCursor) {
        // Brand wordmark.
        page.drawRuns([
            ("Trip", uiFont(20, .bold), UIColor.black),
            ("Forge", uiFont(20, .bold), teal)
        ])
        page.advance(6)

        // Title.
        page.drawParagraph(trip.title, font: uiFont(26, .heavy), color: ink)
        page.advance(2)

        // Destination + meta line.
        page.drawParagraph(trip.destination.uppercased(), font: uiFont(12, .semibold), color: teal)
        page.advance(4)

        let meta = [
            DateUtils.rangeLabel(trip.startDate, trip.endDate),
            "\(trip.travelers) traveler\(trip.travelers == 1 ? "" : "s")",
            "\(trip.days.count) day\(trip.days.count == 1 ? "" : "s")",
            "Budget \(Money.format(trip.budget, trip.currency))",
            "Est. spend \(Money.format(trip.totalCost, trip.currency))"
        ].joined(separator: "   •   ")
        page.drawParagraph(meta, font: uiFont(11, .regular), color: subtle)

        if !trip.interests.isEmpty {
            page.advance(2)
            page.drawParagraph("Interests: " + trip.interests.joined(separator: ", "),
                               font: uiFont(10, .regular), color: subtle)
        }
        page.advance(10)
        page.drawDivider(color: teal, weight: 2)
        page.advance(12)
    }

    private static func drawDayHeader(_ day: Day, index: Int, on page: inout PageCursor) {
        let title = "Day \(index + 1) — \(DateUtils.dayLabel(day.date))"
        page.drawRuns([(title, uiFont(15, .bold), ink)])
        if let w = day.weather {
            page.appendRight("\(w.emoji)  \(w.high)° / \(w.low)°", font: uiFont(11, .regular), color: subtle)
        }
        page.advance(2)
        if !day.title.isEmpty || !day.summary.isEmpty {
            let sub = [day.title, day.summary].filter { !$0.isEmpty }.joined(separator: " · ")
            page.drawParagraph(sub, font: uiFont(10.5, .regular), color: subtle)
        }
        page.advance(6)
    }

    private static func drawActivity(_ act: Activity, currency: String, on page: inout PageCursor) {
        // Estimate height needed for this block, keep it together where possible.
        page.ensureSpace(44)

        let time = "\(DateUtils.time12(act.startTime))–\(DateUtils.time12(DateUtils.addMinutes(to: act.startTime, act.durationMin)))"
        let cost = act.cost > 0 ? Money.format(act.cost, currency) : ""

        // Row 1: emoji + title (left), cost (right)
        let headline = "\(act.type.emoji)  \(act.title)"
        page.drawRuns([(headline, uiFont(12, .semibold), ink)], indent: 6)
        if !cost.isEmpty {
            page.appendRight(cost, font: uiFont(12, .semibold), color: orange)
        }
        page.advance(1)

        // Row 2: time + location
        var line2 = time
        if !act.location.isEmpty { line2 += "   ·   \(act.location)" }
        page.drawParagraph(line2, font: uiFont(10, .regular), color: subtle, indent: 6)

        // Row 3: description
        if !act.description.isEmpty {
            page.advance(1)
            page.drawParagraph(act.description, font: uiFont(10.5, .regular),
                               color: UIColor(white: 0.25, alpha: 1), indent: 6)
        }
        page.advance(8)
    }

    private static func drawPackingList(_ items: [PackingItem], on page: inout PageCursor) {
        page.advance(4)
        // Two-column checkbox list.
        let colGap: CGFloat = 18
        let colWidth = (page.contentWidth - colGap) / 2
        let rowHeight: CGFloat = 16
        let rows = Int(ceil(Double(items.count) / 2.0))

        page.ensureSpace(CGFloat(rows) * rowHeight + 8)
        let startY = page.y
        for (i, item) in items.enumerated() {
            let col = i % 2
            let row = i / 2
            let x = page.left + CGFloat(col) * (colWidth + colGap)
            let y = startY + CGFloat(row) * rowHeight
            let text = "☐  \(item.label)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: uiFont(11, .regular),
                .foregroundColor: UIColor(white: 0.2, alpha: 1)
            ]
            (text as NSString).draw(in: CGRect(x: x, y: y, width: colWidth, height: rowHeight),
                                    withAttributes: attrs)
        }
        page.y = startY + CGFloat(rows) * rowHeight
    }

    // MARK: Helpers

    private static func uiFont(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: weight)
    }

    private static func slug(_ s: String) -> String {
        let base = s.lowercased().replacingOccurrences(
            of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        let trimmed = base.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "tripforge-itinerary" : trimmed
    }
}


// MARK: - Pagination cursor

/// Tracks vertical position across pages, starting new pages as needed and
/// drawing a footer (page number) on each.
private struct PageCursor {
    let renderer: UIGraphicsPDFRendererContext
    let contentWidth: CGFloat
    let top: CGFloat
    let bottom: CGFloat
    let left: CGFloat

    var y: CGFloat = 0
    private(set) var pageNumber = 0
    private var lastLineRect: CGRect = .zero

    init(renderer: UIGraphicsPDFRendererContext, contentWidth: CGFloat,
         top: CGFloat, bottom: CGFloat, left: CGFloat) {
        self.renderer = renderer
        self.contentWidth = contentWidth
        self.top = top
        self.bottom = bottom
        self.left = left
        self.y = top
    }

    mutating func begin() { newPage() }

    private mutating func newPage() {
        renderer.beginPage()
        pageNumber += 1
        y = top
        drawFooter()
    }

    mutating func ensureSpace(_ needed: CGFloat) {
        if y + needed > bottom { newPage() }
    }

    mutating func advance(_ dy: CGFloat) { y += dy }

    /// Draws a wrapped paragraph and advances y by its height.
    mutating func drawParagraph(_ text: String, font: UIFont, color: UIColor,
                                indent: CGFloat = 0) {
        let width = contentWidth - indent
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let rect = attributed.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let height = ceil(rect.height)
        ensureSpace(height)
        let draw = CGRect(x: left + indent, y: y, width: width, height: height)
        attributed.draw(with: draw, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        lastLineRect = draw
        y += height
    }

    /// Draws a single line composed of styled runs (no wrapping) at the current y.
    mutating func drawRuns(_ runs: [(String, UIFont, UIColor)], indent: CGFloat = 0) {
        let maxFont = runs.map { $0.1.lineHeight }.max() ?? 14
        let height = ceil(maxFont)
        ensureSpace(height)
        var x = left + indent
        for (text, font, color) in runs {
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            let s = NSAttributedString(string: text, attributes: attrs)
            let size = s.size()
            s.draw(at: CGPoint(x: x, y: y))
            x += size.width
        }
        lastLineRect = CGRect(x: left + indent, y: y, width: contentWidth - indent, height: height)
        y += height
    }

    /// Draws right-aligned text on the *previous* line (used for costs / weather).
    mutating func appendRight(_ text: String, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let s = NSAttributedString(string: text, attributes: attrs)
        let size = s.size()
        let x = left + contentWidth - size.width
        let drawY = lastLineRect.minY
        s.draw(at: CGPoint(x: x, y: drawY))
    }

    mutating func drawSectionTitle(_ text: String) {
        drawRuns([(text, UIFont.systemFont(ofSize: 15, weight: .bold), UIColor.black)])
        advance(4)
        drawDivider(color: UIColor(white: 0.8, alpha: 1), weight: 1)
        advance(6)
    }

    mutating func drawDivider(color: UIColor, weight: CGFloat) {
        ensureSpace(weight + 2)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setStrokeColor(color.cgColor)
        ctx?.setLineWidth(weight)
        ctx?.move(to: CGPoint(x: left, y: y))
        ctx?.addLine(to: CGPoint(x: left + contentWidth, y: y))
        ctx?.strokePath()
        y += weight
    }

    private func drawFooter() {
        let text = "Made with TripForge · Page \(pageNumber)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor(white: 0.6, alpha: 1)
        ]
        let s = NSAttributedString(string: text, attributes: attrs)
        let size = s.size()
        let x = left + (contentWidth - size.width) / 2
        s.draw(at: CGPoint(x: x, y: bottom + 14))
    }
}
