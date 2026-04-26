import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Drives the lifecycle of the Live Activity that displays the developer
/// handle ("@MaksimXyila") near the iPhone status bar / Dynamic Island.
///
/// Live Activities require iOS 16.1+. On older systems and on simulator
/// without a real device, all calls are no-ops.
@MainActor
final class LiveActivityController: ObservableObject {
    static let shared = LiveActivityController()
    private init() {}

    @Published var isRunning: Bool = false

    func start(label: String) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Stop any previous running activity to avoid duplicates.
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
        } catch {
            // Activity could not be started (rate-limited, disabled, etc.).
            isRunning = false
        }
        #endif
    }

    /// Convenience overload for views that only know the label text.
    func update(label: String) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        for activity in Activity<TGActivityAttributes>.activities {
            let prev = activity.content.state
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
