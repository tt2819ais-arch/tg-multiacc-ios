import Foundation
import SwiftUI

/// Persistent collection of `MessageTemplate` objects. Backed by
/// UserDefaults; observable so SwiftUI views update automatically.
@MainActor
final class TemplatesStore: ObservableObject {
    private static let storageKey = "templates.list.v1"

    @Published var templates: [MessageTemplate] = []

    init() {
        load()
    }

    func add(_ template: MessageTemplate) {
        templates.insert(template, at: 0)
        save()
    }

    func update(_ template: MessageTemplate) {
        guard let i = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[i] = template
        save()
    }

    func delete(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        save()
    }

    func remove(_ template: MessageTemplate) {
        templates.removeAll { $0.id == template.id }
        save()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.storageKey),
            let list = try? JSONDecoder().decode([MessageTemplate].self, from: data)
        else { return }
        templates = list
    }

    private func save() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
