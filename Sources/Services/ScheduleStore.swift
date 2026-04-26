import Foundation
import SwiftUI

/// Persistent list of scheduled bulk actions. The scheduler itself is a
/// foreground-only timer driven by the running app — when the app is in
/// background iOS will pause us. We additionally schedule a local
/// notification at the same time to remind the user to bring the app
/// foreground if needed.
@MainActor
final class ScheduleStore: ObservableObject {
    private static let storageKey = "scheduled.actions.v1"

    @Published private(set) var actions: [ScheduledAction] = []

    init() { load() }

    func add(_ action: ScheduledAction) {
        actions.append(action)
        actions.sort { $0.fireAt < $1.fireAt }
        save()
    }

    func remove(_ action: ScheduledAction) {
        actions.removeAll { $0.id == action.id }
        save()
    }

    func remove(at offsets: IndexSet) {
        actions.remove(atOffsets: offsets)
        save()
    }

    /// Returns and removes the actions whose `fireAt` is in the past relative
    /// to `now`.
    func popDue(now: Date = Date()) -> [ScheduledAction] {
        let due = actions.filter { $0.fireAt <= now }
        if !due.isEmpty {
            actions.removeAll { a in due.contains(where: { $0.id == a.id }) }
            save()
        }
        return due
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.storageKey),
            let list = try? JSONDecoder().decode([ScheduledAction].self, from: data)
        else { return }
        actions = list.sorted { $0.fireAt < $1.fireAt }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(actions) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
