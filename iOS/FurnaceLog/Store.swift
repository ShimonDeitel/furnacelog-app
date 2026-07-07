import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published var items: [FurnaceLogItem] = []
    @Published var isPro: Bool = false

    /// Free tier limit. Kept comfortably above seed count so a fresh install
    /// never immediately hits the paywall.
    static let freeLimit = 6

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("furnacelog_items.json")
        load()
    }

    var canAddMore: Bool {
        isPro || items.count < Store.freeLimit
    }

    func add(_ item: FurnaceLogItem) {
        items.append(item)
        save()
    }

    func update(_ item: FurnaceLogItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func delete(_ item: FurnaceLogItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func seedIfNeeded() -> [FurnaceLogItem] {
        [
            FurnaceLogItem(name: "Annual Inspection", detail: "ABC Heating", extra: "All checks passed", date: Date()),
            FurnaceLogItem(name: "Filter Replacement", detail: "Self", extra: "Changed HVAC filter", date: Date()),
            FurnaceLogItem(name: "Igniter Repair", detail: "Local HVAC Co", extra: "Replaced faulty igniter", date: Date())
        ]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([FurnaceLogItem].self, from: data) else {
            items = seedIfNeeded()
            save()
            return
        }
        items = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
