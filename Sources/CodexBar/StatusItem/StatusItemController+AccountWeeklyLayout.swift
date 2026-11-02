import AppKit
import CodexBarCore

extension StatusItemController {
    func menuBarAccountWeeklyRows(for provider: UsageProvider) -> [MenuBarAccountWeeklyRow] {
        guard self.settings.menuBarAccountWeeklyUsageEnabled,
              !self.shouldMergeIcons,
              !self.menuBarUsageSource(for: provider).isFleet
        else { return [] }
        switch provider {
        case .claude:
            return MenuBarAccountWeeklyRow.claude(
                accounts: self.store.claudeSwapAccountSnapshots,
                adapterError: self.store.claudeSwapLastError,
                hidePersonalInfo: self.settings.hidePersonalInfo)
        case .codex:
            return MenuBarAccountWeeklyRow.codex(
                accounts: self.settings.codexVisibleAccountProjectionForMenuDisplay?.visibleAccounts ?? [],
                snapshots: self.store.codexAccountSnapshots,
                hidePersonalInfo: self.settings.hidePersonalInfo)
        default:
            return []
        }
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
            var data = self.store.menuBarLayoutRenderData(
                provider: provider,
                snapshot: nil,
                iconKey: "\(provider.rawValue):\(warningFlash ? "warning" : "normal")",
                accountLabel: row.label,
                costs: MenuBarLayoutCostValues(today: nil, last30Days: nil, todayUSD: nil, last30DaysUSD: nil),
                includeLocalDerivedData: false,
                now: now)
            data.weekly = row.weekly
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
