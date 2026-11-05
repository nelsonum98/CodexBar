import CodexBarCore
import Foundation

struct MenuBarAccountWeeklyRow: Hashable {
    let label: String
    let weekly: MenuBarLayoutRenderWindow?

    init(label: String, provider: UsageProvider, snapshot: UsageSnapshot?) {
        let prefix = ProviderDescriptorRegistry.descriptor(for: provider).metadata.displayName + " "
        self.label = label.hasPrefix(prefix) ? String(label.dropFirst(prefix.count)) : label
        self.weekly = MenuBarLayoutRenderWindow(
            MenuBarLayoutSemanticWindowResolver.windows(provider: provider, snapshot: snapshot).weekly)
    }

    func paceDelta(now: Date) -> Double? {
        guard let weekly else { return nil }
        return UsagePace.weekly(
            window: RateWindow(
                usedPercent: weekly.usedPercent,
                windowMinutes: weekly.windowMinutes,
                resetsAt: weekly.resetsAt,
                resetDescription: weekly.resetDescription),
            now: now)?.deltaPercent
    }

    func renderData(provider: UsageProvider, iconKey: String) -> MenuBarLayoutRenderData {
        MenuBarLayoutRenderData(
            provider: provider.instanceID,
            iconKey: iconKey,
            providerName: ProviderDescriptorRegistry.descriptor(for: provider).metadata.displayName,
            accountLabel: self.label,
            laneLabels: MenuBarLayoutLaneLabels(provider: provider, snapshot: nil),
            primary: nil,
            secondary: nil,
            tertiary: nil,
            session: nil,
            weekly: self.weekly,
            scopedWeekly: nil,
            scopedWeeklyTitle: nil,
            automatic: nil,
            automaticText: nil,
            sessionPace: nil,
            weeklyPace: nil,
            automaticPace: nil,
            runsOut: nil,
            balance: nil,
            costToday: nil,
            cost30d: nil,
            metrics: .unavailable)
    }
}
