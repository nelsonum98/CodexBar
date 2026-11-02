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

    static func claude(
        accounts: [ProviderAccountUsageSnapshot],
        adapterError: String?,
        hidePersonalInfo: Bool) -> [Self]
    {
        accounts.map { account in
            Self(
                label: ClaudeSwapAccountMenuDisplay.label(for: account, hidePersonalInfo: hidePersonalInfo),
                provider: .claude,
                snapshot: adapterError == nil && account.error == nil && !account.usesLastKnownUsage
                    ? account.snapshot : nil)
        }
    }

    static func codex(
        accounts: [CodexVisibleAccount],
        snapshots: [CodexAccountUsageSnapshot],
        hidePersonalInfo: Bool) -> [Self]
    {
        let labels = CodexAccountSwitcherLabeling.labels(for: accounts, hidePersonalInfo: hidePersonalInfo)
        return accounts.map { account in
            let record = snapshots.first {
                $0.id == account.id && UsageStore.codexPriorSnapshotAccountMatches($0.account, account: account)
            }
            return Self(
                label: labels[account.id] ?? L("Account"),
                provider: .codex,
                snapshot: CodexAccountHealth.status(for: account, error: record?.error) == .ok
                    ? record?.snapshot : nil)
        }
    }
}
