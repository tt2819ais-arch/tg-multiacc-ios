import Foundation
import UIKit

enum TDConfig {
    // Test credentials provided by the project owner.
    // Replace with your own from https://my.telegram.org for production builds.
    static let apiId: Int = 22435995
    static let apiHash: String = "4c7b651950ed7f53520e66299453144d"

    static let appName: String = "TG MultiAcc"
    static let appVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"

    static var systemVersion: String {
        let v = UIDevice.current.systemVersion
        return "iOS \(v)"
    }

    static var deviceModel: String {
        UIDevice.current.model
    }

    static var languageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Root directory where each account stores its TDLib database/files.
    static var rootDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("td", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func directory(forAccountId id: String) -> URL {
        let dir = rootDirectory.appendingPathComponent(id, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
