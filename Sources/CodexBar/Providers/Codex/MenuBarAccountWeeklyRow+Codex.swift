import CodexBarCore

extension MenuBarAccountWeeklyRow {
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
