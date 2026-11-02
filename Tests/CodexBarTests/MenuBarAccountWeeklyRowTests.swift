import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct MenuBarAccountWeeklyRowTests {
    @Test
    func `weekly allowance follows each account independently`() {
        let initial = MenuBarAccountWeeklyRow.claude(
            accounts: [self.claudeAccount(slot: 1, used: 10), self.claudeAccount(slot: 2, used: 60)],
            adapterError: nil,
            hidePersonalInfo: false)
        let updated = MenuBarAccountWeeklyRow.claude(
            accounts: [self.claudeAccount(slot: 1, used: 10), self.claudeAccount(slot: 2, used: 70)],
            adapterError: nil,
            hidePersonalInfo: false)
        #expect(initial.map { $0.weekly?.remainingPercent } == [90, 40])
        #expect(updated.map { $0.weekly?.remainingPercent } == [90, 30])
        #expect(initial != updated)
        #expect(initial[0].label == "Account 1")
    }

    @Test
    func `a failed account stays labeled while its sibling remains current`() {
        let rows = MenuBarAccountWeeklyRow.claude(
            accounts: [
                self.claudeAccount(slot: 1, used: 0, error: "Unavailable"),
                self.claudeAccount(slot: 2, used: 60),
            ],
            adapterError: nil,
            hidePersonalInfo: false)
        #expect(rows[0].label == "Account 1")
        #expect(rows[0].weekly == nil)
        #expect(rows[1].weekly?.remainingPercent == 40)
    }

    @Test
    func `adapter failures and last known usage never look like current allowance`() {
        let rows = MenuBarAccountWeeklyRow.claude(
            accounts: [self.claudeAccount(slot: 1, used: 10)],
            adapterError: "Feed failed",
            hidePersonalInfo: false)
        #expect(rows[0].weekly == nil)
        let retained = MenuBarAccountWeeklyRow.claude(
            accounts: [self.claudeAccount(slot: 1, used: 10, lastKnown: true)],
            adapterError: nil,
            hidePersonalInfo: false)
        #expect(retained[0].weekly == nil)
    }

    @Test
    func `Codex weekly usage can arrive in the primary window`() {
        let row = MenuBarAccountWeeklyRow(
            label: "Example",
            provider: .codex,
            snapshot: UsageSnapshot(
                primary: self.window(used: 23, minutes: 10080),
                secondary: nil,
                updatedAt: Date()))
        #expect(row.weekly?.remainingPercent == 77)
    }

    @Test
    func `session allowance is never substituted for an absent weekly window`() {
        let row = MenuBarAccountWeeklyRow(
            label: "Example",
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: self.window(used: 1, minutes: 300),
                secondary: nil,
                updatedAt: Date()))
        #expect(row.weekly == nil)
    }

    @Test
    func `private account labels retain distinct slots`() {
        let rows = MenuBarAccountWeeklyRow.claude(
            accounts: [self.claudeAccount(slot: 1, used: 10), self.claudeAccount(slot: 2, used: 60)],
            adapterError: nil,
            hidePersonalInfo: true)
        #expect(rows[0].label != rows[1].label)
    }

    @Test
    func `Codex accounts retain names and isolate missing and mismatched records`() {
        let first = self.codexAccount(id: "first", workspace: "one").withCustomName("First")
        let second = self.codexAccount(id: "second", workspace: "two").withCustomName("Second")
        let record = CodexAccountUsageSnapshot(
            account: first,
            snapshot: UsageSnapshot(primary: nil, secondary: self.window(used: 15, minutes: 10080), updatedAt: Date()),
            error: nil,
            sourceLabel: nil)
        let rows = MenuBarAccountWeeklyRow.codex(
            accounts: [first, second],
            snapshots: [record],
            hidePersonalInfo: false)
        #expect(rows.map(\.label) == ["First", "Second"])
        #expect(rows[0].weekly?.remainingPercent == 85)
        #expect(rows[1].weekly == nil)
        let replaced = self.codexAccount(id: "first", workspace: "replacement")
        let mismatched = MenuBarAccountWeeklyRow.codex(
            accounts: [replaced],
            snapshots: [record],
            hidePersonalInfo: false)
        #expect(mismatched[0].weekly == nil)
    }

    @Test
    func `Codex errors with a retained snapshot show unavailable`() {
        let account = self.codexAccount(id: "first", workspace: "one")
        let record = CodexAccountUsageSnapshot(
            account: account,
            snapshot: UsageSnapshot(primary: nil, secondary: self.window(used: 15, minutes: 10080), updatedAt: Date()),
            error: "Unauthorized",
            sourceLabel: nil)
        let rows = MenuBarAccountWeeklyRow.codex(
            accounts: [account],
            snapshots: [record],
            hidePersonalInfo: false)
        #expect(rows[0].weekly == nil)
    }

    private func codexAccount(id: String, workspace: String) -> CodexVisibleAccount {
        CodexVisibleAccount(
            id: id,
            email: "\(id)@example.com",
            workspaceAccountID: workspace,
            storedAccountID: nil,
            selectionSource: .liveSystem,
            isActive: false,
            isLive: true,
            canReauthenticate: false,
            canRemove: false)
    }

    private func claudeAccount(
        slot: Int, used: Double, error: String? = nil, lastKnown: Bool = false) -> ProviderAccountUsageSnapshot
    {
        ProviderAccountUsageSnapshot(
            id: ProviderAccountIdentity(source: "claude-swap", opaqueID: String(slot)),
            provider: .claude,
            displayLabel: "Claude Account \(slot)",
            isActive: false,
            usesLastKnownUsage: lastKnown,
            snapshot: UsageSnapshot(
                primary: self.window(used: 99, minutes: 300),
                secondary: self.window(used: used, minutes: 10080),
                updatedAt: Date()),
            error: error,
            sourceLabel: nil)
    }

    private func window(used: Double, minutes: Int) -> RateWindow {
        RateWindow(usedPercent: used, windowMinutes: minutes, resetsAt: nil, resetDescription: nil)
    }
}
