import AppKit
import CodexBarCore

extension MenuBarLayoutRenderer {
    func renderAccountWeeklyRows(
        _ rows: [MenuBarAccountWeeklyRow],
        provider: UsageProvider,
        iconKey: String,
        icon: NSImage?,
        options: MenuBarLayoutRenderOptions) -> MenuBarLayoutRenderedTitle
    {
        var options = options
        options.showWindowLabels = false
        options.monospacedDigits = true
        let renderedRows = rows.map { row in
            self.render(
                layout: MenuBarLayout(lines: [[.icon, .accountLabel, .percent(window: .weekly)]]),
                data: row.renderData(provider: provider, iconKey: iconKey),
                icon: icon,
                options: options)
        }
        let titles = renderedRows.map { NSMutableAttributedString(attributedString: $0.attributedTitle) }
        let labelRanges = zip(titles, rows).map { ($0.string as NSString).range(of: $1.label) }
        let font = titles[0].attribute(.font, at: labelRanges[0].location, effectiveRange: nil) as? NSFont
        let attributes: [NSAttributedString.Key: Any] = font.map { [.font: $0] } ?? [:]
        let labelWidth = max(
            NSAttributedString(string: "000", attributes: attributes).size().width,
            zip(titles, labelRanges).map { $0.attributedSubstring(from: $1).size().width }.max() ?? 0)
        let percentWidth = NSAttributedString(string: "100%", attributes: attributes).size().width
        for (title, labelRange) in zip(titles, labelRanges) {
            let gapIndex = NSMaxRange(labelRange)
            let valueRange = NSRange(location: gapIndex + 1, length: title.length - gapIndex - 1)
            let padding = labelWidth - title.attributedSubstring(from: labelRange).size().width
                + max(0, percentWidth - title.attributedSubstring(from: valueRange).size().width)
            title.addAttribute(.kern, value: padding, range: NSRange(location: gapIndex, length: 1))
        }
        return Self.composeStackedProviderRows(
            top: MenuBarLayoutRenderedTitle(
                attributedTitle: titles[0], accessibilityLabel: renderedRows[0].accessibilityLabel, leadingIcon: nil),
            bottom: MenuBarLayoutRenderedTitle(
                attributedTitle: titles[1], accessibilityLabel: renderedRows[1].accessibilityLabel, leadingIcon: nil),
            topProviderName: rows[0].label,
            bottomProviderName: rows[1].label)
    }
}
