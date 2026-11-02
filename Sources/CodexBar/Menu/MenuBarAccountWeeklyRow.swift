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
}
