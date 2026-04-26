import Foundation
import SwiftUI

enum LogLevel: String, Codable, CaseIterable, Identifiable {
    case debug, info, success, warning, error

    var id: String { rawValue }

    var label: String {
        switch self {
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .success: return "OK"
        case .warning: return "WARN"
        case .error:   return "ERR"
        }
    }

    var color: Color {
        switch self {
        case .debug:   return Color.white.opacity(0.45)
        case .info:    return AppTheme.accent
        case .success: return AppTheme.success
        case .warning: return AppTheme.warning
        case .error:   return AppTheme.danger
        }
    }
}

struct LogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let level: LogLevel
    let category: String           // e.g. "auth", "bulk", "account:Maxim", "tdlib"
    let message: String
    let detail: String?            // multi-line: stacktrace, payload, error description

    init(id: UUID = UUID(),
         date: Date = Date(),
         level: LogLevel,
         category: String,
         message: String,
         detail: String? = nil) {
        self.id = id
        self.date = date
        self.level = level
        self.category = category
        self.message = message
        self.detail = detail
    }

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    var timeString: String { Self.timeFormatter.string(from: date) }

    var oneLine: String {
        "[\(timeString)] [\(level.label)] [\(category)] \(message)"
    }

    var fullText: String {
        var s = oneLine
        if let d = detail, !d.isEmpty { s += "\n    " + d.replacingOccurrences(of: "\n", with: "\n    ") }
        return s
    }
}

/// Global, thread-safe, in-memory + on-disk logger. Use ``AppLogger.shared``.
final class AppLogger: ObservableObject {
    static let shared = AppLogger()

    @Published private(set) var entries: [LogEntry] = []

    private let queue = DispatchQueue(label: "app.tgmultiacc.logger", qos: .utility)
    private let maxInMemory = 5_000
    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("app.log", isDirectory: false)
        loadFromDisk()
        log(.info, category: "app", "Logger initialized. Log file: \(fileURL.path)")
    }

    // MARK: - Public API

    func log(_ level: LogLevel, category: String, _ message: String, detail: String? = nil) {
        let entry = LogEntry(level: level, category: category, message: message, detail: detail)
        append(entry)
    }

    func debug(_ category: String, _ message: String, detail: String? = nil) {
        log(.debug, category: category, message, detail: detail)
    }

    func info(_ category: String, _ message: String, detail: String? = nil) {
        log(.info, category: category, message, detail: detail)
    }

    func success(_ category: String, _ message: String, detail: String? = nil) {
        log(.success, category: category, message, detail: detail)
    }

    func warning(_ category: String, _ message: String, detail: String? = nil) {
        log(.warning, category: category, message, detail: detail)
    }

    func error(_ category: String, _ message: String, detail: String? = nil) {
        log(.error, category: category, message, detail: detail)
    }

    func error(_ category: String, _ message: String, error: Error) {
        let detail = "\(error)\n\(String(describing: type(of: error)))"
        log(.error, category: category, message, detail: detail)
    }

    func clear() {
        queue.async {
            DispatchQueue.main.async { self.entries.removeAll() }
            try? "".write(to: self.fileURL, atomically: true, encoding: .utf8)
        }
    }

    /// Returns a fresh URL of a text snapshot of the log, suitable for sharing.
    func makeShareableSnapshot() -> URL? {
        let text = entries.map { $0.fullText }.joined(separator: "\n")
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("tg-multiacc-\(Int(Date().timeIntervalSince1970)).log")
        do {
            try text.write(to: tmp, atomically: true, encoding: .utf8)
            return tmp
        } catch {
            return nil
        }
    }

    // MARK: - Internals

    private func append(_ entry: LogEntry) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.entries.append(entry)
            if self.entries.count > self.maxInMemory {
                self.entries.removeFirst(self.entries.count - self.maxInMemory)
            }
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            self.appendLineToFile(entry.fullText + "\n")
        }
        #if DEBUG
        print(entry.oneLine)
        #endif
    }

    private func appendLineToFile(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            }
        } else {
            try? data.write(to: fileURL)
        }
        // Truncate the file if it grew over 4 MB
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? UInt64, size > 4 * 1024 * 1024 {
            // Keep the last 1 MB
            if let handle = try? FileHandle(forReadingFrom: fileURL) {
                _ = try? handle.seek(toOffset: size - 1024 * 1024)
                let tail = (try? handle.readToEnd()) ?? Data()
                try? handle.close()
                try? tail.write(to: fileURL)
            }
        }
    }

    private func loadFromDisk() {
        // We do not deserialize old log entries into `entries` (they're plain text);
        // they remain on disk for export, but the in-memory list starts fresh per launch.
    }
}
