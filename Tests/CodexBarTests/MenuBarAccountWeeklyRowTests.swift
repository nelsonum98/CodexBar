import AppKit
import CodexBarCore
import CoreText
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct MenuBarAccountWeeklyRowTests {
    @Test(arguments: [-5.1, -5.0, 0.0, 5.0, 5.1])
    func `weekly percentages color only outside the five point pace band`(delta: Double) throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let rows = [
            self.pacedRow(label: "AAA", used: 50 + delta, reset: now.addingTimeInterval(302_400)),
            self.pacedRow(label: "BB", used: 50, reset: now.addingTimeInterval(302_400)),
        ]
        let output = MenuBarLayoutRenderer().renderAccountWeeklyRows(
            rows,
            provider: .claude,
            iconKey: "example",
            icon: nil,
            options: MenuBarLayoutRenderOptions(
                size: .regular,
                highContrast: false,
                showUsed: false,
                conditionals: [],
                appearanceName: "NSAppearanceNameAqua",
                isDebugApp: false,
                now: now,
                forceStackedStyle: true))
        let title = output.attributedTitle
        let labelIndex = (title.string as NSString).range(of: "AAA").location
        let percentIndex = (title.string as NSString).range(of: "%").location
        let color = try #require(title.attribute(.foregroundColor, at: percentIndex, effectiveRange: nil) as? NSColor)
        let labelColor = try #require(title.attribute(
            .foregroundColor,
            at: labelIndex,
            effectiveRange: nil) as? NSColor)
        let expected: NSColor = delta > 5 ? .systemRed : (delta < -5 ? .systemGreen : labelColor)
        #expect(color == expected)
        #expect(labelColor != .systemRed && labelColor != .systemGreen)
        if abs(delta) <= 5 {
            #expect(output.accessibilityLabel.contains("On pace"))
        } else {
            #expect(output.statusImage == nil)
            #expect(output.accessibilityLabel.contains(delta > 0 ? "deficit" : "reserve"))
        }
    }

    @Test
    func `pace uses each accounts reset and becomes unknown after reset`() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let first = self.pacedRow(label: "AAA", used: 50, reset: now.addingTimeInterval(302_400))
        let second = self.pacedRow(label: "BB", used: 50, reset: now.addingTimeInterval(151_200))
        #expect(first.paceDelta(now: now) == 0)
        #expect(second.paceDelta(now: now) == -25)
        #expect(first.paceDelta(now: now.addingTimeInterval(6048)) == -1)
        #expect(second.paceDelta(now: now.addingTimeInterval(151_200)) == nil)
        #expect(self.pacedRow(label: "AAA", used: 50, reset: nil).paceDelta(now: now) == nil)
        #expect(MenuBarAccountWeeklyRow(label: "AAA", provider: .claude, snapshot: nil).paceDelta(now: now) == nil)
    }

    @Test(arguments: [0.0, 9.0, 100.0, nil] as [Double?])
    func `account columns align values without a visible window marker`(remaining: Double?) {
        let rows = [
            MenuBarAccountWeeklyRow(
                label: "PER",
                provider: .claude,
                snapshot: UsageSnapshot(
                    primary: nil,
                    secondary: self.window(used: 58, minutes: 10080),
                    updatedAt: Date())),
            MenuBarAccountWeeklyRow(
                label: "FC",
                provider: .claude,
                snapshot: remaining.map {
                    UsageSnapshot(
                        primary: nil,
                        secondary: self.window(used: 100 - $0, minutes: 10080),
                        updatedAt: Date())
                }),
        ]
        let output = MenuBarLayoutRenderer().renderAccountWeeklyRows(
            rows,
            provider: .claude,
            iconKey: "example",
            icon: nil,
            options: MenuBarLayoutRenderOptions(
                size: .regular,
                highContrast: false,
                showUsed: false,
                conditionals: [],
                appearanceName: "NSAppearanceNameAqua",
                isDebugApp: false,
                now: Date(),
                forceStackedStyle: true))
        let title = output.attributedTitle
        let lines = title.string.components(separatedBy: "\n")
        let top = title.attributedSubstring(from: NSRange(location: 0, length: (lines[0] as NSString).length))
        let bottom = title.attributedSubstring(from: NSRange(
            location: top.length + 1, length: (lines[1] as NSString).length))
        let topWidth = CTLineGetTypographicBounds(CTLineCreateWithAttributedString(top), nil, nil, nil)
        let bottomWidth = CTLineGetTypographicBounds(CTLineCreateWithAttributedString(bottom), nil, nil, nil)
        #expect(abs(topWidth - bottomWidth) < 0.01)
        #expect(!title.string.contains("W"))
        #expect(output.accessibilityLabel.contains("Weekly"))
        #expect(output.accessibilityLabel.contains("42%"))
        if remaining != nil {
            let topPercent = (top.string as NSString).range(of: "%").location
            let bottomPercent = (bottom.string as NSString).range(of: "%").location
            let topOffset = CTLineGetOffsetForStringIndex(CTLineCreateWithAttributedString(top), topPercent, nil)
            let bottomOffset = CTLineGetOffsetForStringIndex(
                CTLineCreateWithAttributedString(bottom),
                bottomPercent,
                nil)
            #expect(abs(topOffset - bottomOffset) < 0.01)
        }
    }

    @Test
    func `weekly account rows render their account labels and percentages`() {
        let row = MenuBarAccountWeeklyRow(
            label: "Account 1",
            provider: .claude,
            snapshot: UsageSnapshot(primary: nil, secondary: self.window(used: 10, minutes: 10080), updatedAt: Date()))
        let rendered = MenuBarLayoutRenderer().render(
            layout: MenuBarLayout(lines: [[.accountLabel, .percent(window: .weekly)]]),
            data: row.renderData(provider: .claude, iconKey: "example"),
            icon: nil,
            options: MenuBarLayoutRenderOptions(
                size: .regular,
                highContrast: false,
                showUsed: false,
                conditionals: [],
                appearanceName: "NSAppearanceNameAqua",
                isDebugApp: false,
                now: Date(),
                forceStackedStyle: true))
        #expect(rendered.attributedTitle.string.contains(row.label))
        #expect(rendered.accessibilityLabel.contains("90%"))
    }

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

    private func pacedRow(label: String, used: Double, reset: Date?) -> MenuBarAccountWeeklyRow {
        MenuBarAccountWeeklyRow(
            label: label,
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: nil,
                secondary: RateWindow(
                    usedPercent: used, windowMinutes: 10080, resetsAt: reset, resetDescription: nil),
                updatedAt: Date()))
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
