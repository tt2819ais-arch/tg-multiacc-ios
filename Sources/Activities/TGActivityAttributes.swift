import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Shape of the Live Activity that runs while the app is open. Both the
/// host app and the widget extension reference this type, so it lives in
/// `Sources/Activities/` and is included in both targets.
#if canImport(ActivityKit)
@available(iOS 16.1, *)
public struct TGActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var label: String
        public var totalAccounts: Int
        public var ready: Int
        public var lastAction: String

        public init(label: String,
                    totalAccounts: Int = 0,
                    ready: Int = 0,
                    lastAction: String = "") {
            self.label = label
            self.totalAccounts = totalAccounts
            self.ready = ready
            self.lastAction = lastAction
        }
    }

    public var name: String

    public init(name: String = "TGMultiAcc") {
        self.name = name
    }
}
#endif
