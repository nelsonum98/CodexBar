import CodexBarCore

extension MenuBarAccountWeeklyRow {
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
}
