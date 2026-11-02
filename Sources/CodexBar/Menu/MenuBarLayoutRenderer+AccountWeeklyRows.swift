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
        var accessibilityLabels = renderedRows.map(\.accessibilityLabel)
        let labelRanges = zip(titles, rows).map { ($0.string as NSString).range(of: $1.label) }
        let font = titles[0].attribute(.font, at: labelRanges[0].location, effectiveRange: nil) as? NSFont
        let attributes: [NSAttributedString.Key: Any] = font.map { [.font: $0] } ?? [:]
        let labelWidth = max(
            NSAttributedString(string: "000", attributes: attributes).size().width,
            zip(titles, labelRanges).map { $0.attributedSubstring(from: $1).size().width }.max() ?? 0)
        let percentWidth = NSAttributedString(string: "100%", attributes: attributes).size().width
        for (index, pair) in zip(titles, labelRanges).enumerated() {
            let (title, labelRange) = pair
            let gapIndex = NSMaxRange(labelRange)
            let valueRange = NSRange(location: gapIndex + 1, length: title.length - gapIndex - 1)
            let padding = labelWidth - title.attributedSubstring(from: labelRange).size().width
                + max(0, percentWidth - title.attributedSubstring(from: valueRange).size().width)
            title.addAttribute(.kern, value: padding, range: NSRange(location: gapIndex, length: 1))
            if let delta = rows[index].paceDelta(now: options.now) {
                let color: NSColor? = delta > 5 ? .systemRed : (delta < -5 ? .systemGreen : nil)
                let paceLabel = color == nil ? L("On pace") : (delta > 0
                    ? L("%d%% in deficit", Int(abs(delta).rounded()))
                    : L("%d%% in reserve", Int(abs(delta).rounded())))
                accessibilityLabels[index] += ", \(paceLabel)"
                if let color, !options.isHighlighted {
                    title.addAttribute(.foregroundColor, value: color, range: valueRange)
                }
            }
        }
        return Self.composeStackedProviderRows(
            top: MenuBarLayoutRenderedTitle(
                attributedTitle: titles[0], accessibilityLabel: accessibilityLabels[0], leadingIcon: nil),
            bottom: MenuBarLayoutRenderedTitle(
                attributedTitle: titles[1], accessibilityLabel: accessibilityLabels[1], leadingIcon: nil),
            topProviderName: rows[0].label,
            bottomProviderName: rows[1].label)
    }
}
