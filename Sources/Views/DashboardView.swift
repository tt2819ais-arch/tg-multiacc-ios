import SwiftUI

/// Top-level dashboard tab. Surfaces high-signal real-time stats — number of
/// authorized accounts, ones in flood-wait, the latest bulk run, today's
/// activity counters, and the most recent error rows.
struct DashboardView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var manager: AccountManager
    @EnvironmentObject var logger: AppLogger
    @EnvironmentObject var liveActivity: LiveActivityController

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    statsGrid
                    if manager.bulkState.total > 0 { lastBulkCard }
                    recentLogsCard
                    quickActions
                }
                .padding(16)
            }
        }
        .navigationTitle("Dashboard")
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Multi")
                    .font(AppTheme.mono(11))
                    .foregroundStyle(AppTheme.textTertiary)
                Spacer()
                if liveActivity.isRunning {
                    Label("Live", systemImage: "dot.radiowaves.left.and.right")
                        .font(AppTheme.body(11))
                        .foregroundStyle(AppTheme.success)
                }
            }
            Text("Привет, \(headline)")
                .font(AppTheme.headline(20))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Сегодня: \(todayCount) действий, \(errorsToday) ошибок")
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(AppTheme.surfaceElevated)
    }

    private var headline: String {
        let label = settings.liveActivityText
        return label.isEmpty ? "Telegram pilot" : label
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        let total = manager.accounts.count
        let ready = manager.readyAccounts.count
        let flood = floodWaitCount
        let pending = total - ready - flood
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            StatTile(value: "\(ready)", label: "Готовы", color: AppTheme.success, icon: "checkmark.seal.fill")
            StatTile(value: "\(flood)", label: "FloodWait", color: AppTheme.warning, icon: "hourglass")
            StatTile(value: "\(pending)", label: "Ожидание", color: AppTheme.accent, icon: "clock")
            StatTile(value: "\(total)", label: "Всего", color: settings.theme.accent, icon: "person.2.fill")
        }
    }

    private var floodWaitCount: Int {
        manager.accounts.filter {
            if case .error(let m) = $0.authState, m.uppercased().contains("FLOOD") { return true }
            return false
        }.count
    }

    private var todayCount: Int {
        let calendar = Calendar.current
        return logger.entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: Date()) && entry.level != .debug
        }.count
    }

    private var errorsToday: Int {
        let calendar = Calendar.current
        return logger.entries.filter { e in
            calendar.isDate(e.date, inSameDayAs: Date()) && e.level == .error
        }.count
    }

    // MARK: - Last bulk

    private var lastBulkCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Последний bulk run")
                .font(AppTheme.headline(15))
                .foregroundStyle(AppTheme.textPrimary)
            Text(manager.bulkState.category.isEmpty
                  ? "—"
                  : manager.bulkState.category)
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.textSecondary)
            ProgressBar(done: manager.bulkState.done, total: manager.bulkState.total)
            if !manager.bulkState.results.isEmpty {
                let ok = manager.bulkState.results.filter(\.success).count
                Text("OK: \(ok) / \(manager.bulkState.results.count)")
                    .font(AppTheme.mono(12))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .card(AppTheme.surfaceElevated)
    }

    // MARK: - Recent logs

    private var recentLogsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Последние ошибки")
                .font(AppTheme.headline(15))
                .foregroundStyle(AppTheme.textPrimary)
            let recent = logger.entries.filter { $0.level == .error || $0.level == .warning }.suffix(5)
            if recent.isEmpty {
                Text("Тишина — ошибок нет")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(Array(recent), id: \.id) { e in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(e.level == .error ? AppTheme.danger : AppTheme.warning)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.category).font(AppTheme.mono(11))
                                .foregroundStyle(AppTheme.textTertiary)
                            Text(e.message).font(AppTheme.body(12))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                }
            }
        }
        .card(AppTheme.surfaceElevated)
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickButton(icon: "person.crop.circle.badge.plus", title: "Аккаунт")
            quickButton(icon: "bolt.fill", title: "Bulk")
            quickButton(icon: "doc.text.magnifyingglass", title: "Логи")
        }
    }

    private func quickButton(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(settings.theme.accent)
            Text(title)
                .font(AppTheme.body(12))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        )
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                Spacer()
                Text(label.uppercased())
                    .font(AppTheme.mono(10))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(color.opacity(0.4), lineWidth: 1)
        )
    }
}
