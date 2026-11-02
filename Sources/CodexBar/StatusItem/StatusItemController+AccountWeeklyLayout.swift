import AppKit
import CodexBarCore

extension StatusItemController {
    func menuBarAccountWeeklyRows(for provider: UsageProvider) -> [MenuBarAccountWeeklyRow] {
        guard self.settings.menuBarAccountWeeklyUsageEnabled,
              !self.shouldMergeIcons,
              !self.menuBarUsageSource(for: provider).isFleet
        else { return [] }
        return ProviderCatalog.implementation(for: provider)?.menuBarAccountWeeklyRows(
            store: self.store, settings: self.settings) ?? []
    }

    func applyAccountWeeklyMenuBarLayout(
        provider: UsageProvider, statusItem: NSStatusItem, warningFlash: Bool) -> Bool?
    {
        let rows = self.menuBarAccountWeeklyRows(for: provider)
        guard rows.count == 2,
              self.settings.menuBarIconStyle == .iconAndPercent,
              let button = statusItem.button
        else { return nil }
        let now = Date()
        var options = self.menuBarLayoutRenderOptions(
            forInstanceID: provider.instanceID, button: button, now: now, forceStackedStyle: true)
        options.showUsed = false
        options.isStale = false
        let icon = ProviderBrandIcon.image(for: provider)
            .map { warningFlash ? Self.quotaWarningFlashImage(base: $0) : $0 }
        let renderedRows = rows.map { row in
            let data = row.renderData(
                provider: provider,
                iconKey: "\(provider.rawValue):\(warningFlash ? "warning" : "normal")")
            return self.menuBarLayoutRenderer.render(
                layout: MenuBarLayout(lines: [[.icon, .accountLabel, .percent(window: .weekly)]]),
                data: data,
                icon: icon,
                options: options)
        }
        let rendered = MenuBarLayoutRenderer.composeStackedProviderRows(
            top: renderedRows[0],
            bottom: renderedRows[1],
            topProviderName: rows[0].label,
            bottomProviderName: rows[1].label)
        let wasCached = button.image === rendered.statusImage
        self.lastAppliedProviderIconRenderSignatures[provider.instanceID] = nil
        statusItem.length = Self.applyMenuBarLayoutContent(rendered, for: button, gap: self.settings.menuBarLayoutGap)
        return wasCached
    }
}
