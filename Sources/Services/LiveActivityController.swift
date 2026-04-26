import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Drives the lifecycle of the Live Activity that displays the developer
/// handle ("@MaksimXyila") near the iPhone status bar / Dynamic Island.
///
/// Live Activities require iOS 16.1+. On older systems all calls are
/// no-ops. Errors are surfaced through `lastError` so the Settings screen
/// can explain why nothing appears under the notch (most commonly the
/// system-wide "Live Activities" toggle is OFF).
@MainActor
final class LiveActivityController: ObservableObject {
    static let shared = LiveActivityController()
    private init() {
        refreshAuthorizationStatus()
    }

    @Published var isRunning: Bool = false
    @Published var systemAllowsActivities: Bool = false
    @Published var lastError: String?

    func refreshAuthorizationStatus() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            systemAllowsActivities = ActivityAuthorizationInfo().areActivitiesEnabled
        }
        #endif
    }

    func start(label: String) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else {
            lastError = "Live Activities требуют iOS 16.1+"
            return
        }
        refreshAuthorizationStatus()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            lastError = "Live Activity отключена в системных настройках iOS"
            return
        }
        await stop()
        let attributes = TGActivityAttributes(name: "TGMultiAcc")
        let initial = TGActivityAttributes.ContentState(label: label)
        do {
            if #available(iOS 16.2, *) {
                _ = try Activity.request(
                    attributes: attributes,
                    content: .init(state: initial, staleDate: nil),
                    pushType: nil
                )
            } else {
                _ = try Activity.request(
                    attributes: attributes,
                    contentState: initial,
                    pushType: nil
                )
            }
            isRunning = true
            lastError = nil
        } catch {
            isRunning = false
            lastError = "Не удалось запустить: \(error.localizedDescription)"
        }
        #endif
    }

    func update(label: String) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        for activity in Activity<TGActivityAttributes>.activities {
            let prev: TGActivityAttributes.ContentState
            if #available(iOS 16.2, *) {
                prev = activity.content.state
            } else {
                prev = activity.contentState
            }
            let state = TGActivityAttributes.ContentState(
                label: label,
                totalAccounts: prev.totalAccounts,
                ready: prev.ready,
                lastAction: prev.lastAction
            )
            if #available(iOS 16.2, *) {
                await activity.update(.init(state: state, staleDate: nil))
            } else {
                await activity.update(using: state)
            }
        }
        #endif
    }

    func update(label: String, totalAccounts: Int, ready: Int, lastAction: String) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        let state = TGActivityAttributes.ContentState(
            label: label,
            totalAccounts: totalAccounts,
            ready: ready,
            lastAction: lastAction
        )
        for activity in Activity<TGActivityAttributes>.activities {
            if #available(iOS 16.2, *) {
                await activity.update(.init(state: state, staleDate: nil))
            } else {
                await activity.update(using: state)
            }
        }
        #endif
    }

    func stop() async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        for activity in Activity<TGActivityAttributes>.activities {
            if #available(iOS 16.2, *) {
                let final = activity.content.state
                await activity.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        isRunning = false
        #endif
    }
}
