import Foundation
import SwiftUI

/// Polls the schedule once a minute while the app is foregrounded and
/// runs any actions whose `fireAt` is in the past.
@MainActor
final class ScheduleRunner: ObservableObject {
    private weak var manager: AccountManager?
    private weak var settings: SettingsStore?
    private weak var schedule: ScheduleStore?
    private var timer: Timer?

    func bind(manager: AccountManager, settings: SettingsStore, schedule: ScheduleStore) {
        self.manager = manager
        self.settings = settings
        self.schedule = schedule
        start()
    }

    private func start() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard let schedule, let manager, let settings else { return }
        let due = schedule.popDue()
        for action in due {
            run(action: action, manager: manager, settings: settings)
        }
    }

    private func run(action: ScheduledAction,
                      manager: AccountManager,
                      settings: SettingsStore) {
        Task {
            await manager.runBulk(category: "scheduled:\(action.kind.rawValue)",
                                   settings: settings,
                                   tagFilter: action.groupTag) { acc in
                switch action.kind {
                case .subscribe: return try await acc.subscribe(to: action.target)
                case .leave:     return try await acc.leave(from: action.target)
                case .markRead:  return try await acc.markRead(in: action.target)
                case .message:
                    let text = action.text.isEmpty ? "(scheduled)" : action.text
                    return try await acc.sendText(to: action.target, text: text)
                }
            }
        }
    }

    deinit { timer?.invalidate() }
}
