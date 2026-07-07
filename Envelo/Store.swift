import Foundation

@MainActor
final class EnveloStore: ObservableObject {
    @Published private(set) var entries: [GiftEntry] = []

    static let freeEntryLimit = 20

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("envelo_entries.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if entries.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        entries = [
            GiftEntry(personName: "Aunt Rivka", direction: .received, occasion: .birthday, amount: 50,
                      date: Calendar.current.date(byAdding: .month, value: -8, to: Date())!, note: "18th birthday"),
            GiftEntry(personName: "Uncle Moshe", direction: .given, occasion: .wedding, amount: 180,
                      date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, note: "")
        ]
        save()
    }

    func canAddEntry(isPro: Bool) -> Bool {
        isPro || entries.count < Self.freeEntryLimit
    }

    @discardableResult
    func addEntry(personName: String, direction: GiftDirection, occasion: GiftOccasion, amount: Double, date: Date, note: String, isPro: Bool) -> Bool {
        let trimmed = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0, canAddEntry(isPro: isPro) else { return false }
        let entry = GiftEntry(personName: trimmed, direction: direction, occasion: occasion, amount: amount, date: date, note: note)
        entries.append(entry)
        save()
        return true
    }

    func updateEntry(_ id: UUID, personName: String, direction: GiftDirection, occasion: GiftOccasion, amount: Double, date: Date, note: String) {
        let trimmed = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0, let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].personName = trimmed
        entries[idx].direction = direction
        entries[idx].occasion = occasion
        entries[idx].amount = amount
        entries[idx].date = date
        entries[idx].note = note
        save()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func deleteAllData() {
        entries = []
        seedDefaults()
    }

    // MARK: - Derived data

    var totalGiven: Double {
        entries.filter { $0.direction == .given }.reduce(0) { $0 + $1.amount }
    }

    var totalReceived: Double {
        entries.filter { $0.direction == .received }.reduce(0) { $0 + $1.amount }
    }

    /// Pro bonus feature: per-person running balance (net given vs received).
    var personBalances: [PersonBalance] {
        let grouped = Dictionary(grouping: entries, by: { $0.personName })
        return grouped.map { name, list in
            let given = list.filter { $0.direction == .given }.reduce(0) { $0 + $1.amount }
            let received = list.filter { $0.direction == .received }.reduce(0) { $0 + $1.amount }
            let lastDate = list.map(\.date).max() ?? Date()
            return PersonBalance(personName: name, totalGiven: given, totalReceived: received, lastGiftDate: lastDate, entryCount: list.count)
        }.sorted { $0.personName < $1.personName }
    }

    /// Pro bonus feature: per-occasion-type breakdown of totals.
    var occasionBreakdown: [(occasion: GiftOccasion, given: Double, received: Double)] {
        GiftOccasion.allCases.map { occ in
            let list = entries.filter { $0.occasion == occ }
            let given = list.filter { $0.direction == .given }.reduce(0) { $0 + $1.amount }
            let received = list.filter { $0.direction == .received }.reduce(0) { $0 + $1.amount }
            return (occ, given, received)
        }.filter { $0.given > 0 || $0.received > 0 }
    }

    /// Pro bonus feature: "it's been a while" reminder nudge — people you've
    /// given to but not received from (or vice versa) in N+ months, based on
    /// their most recent gift in either direction.
    func reciprocityNudges(monthsThreshold: Int) -> [PersonBalance] {
        personBalances.filter { balance in
            balance.net != 0 && balance.monthsSinceLastGift >= monthsThreshold
        }.sorted { $0.monthsSinceLastGift > $1.monthsSinceLastGift }
    }

    /// Milestone badges earned so far, in declared order.
    var earnedMilestones: [Milestone] {
        var earned: [Milestone] = []
        if !entries.isEmpty { earned.append(.firstEntry) }
        if entries.count >= 10 { earned.append(.tenEntries) }
        if entries.count >= 50 { earned.append(.fiftyEntries) }
        if totalGiven >= 500 { earned.append(.fiveHundredGiven) }
        let uniquePeople = Set(entries.map { $0.personName })
        if uniquePeople.count >= 5 { earned.append(.fivePeopleTracked) }
        if personBalances.contains(where: { $0.net == 0 && $0.entryCount >= 2 }) { earned.append(.fullReciprocity) }
        return earned
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var entries: [GiftEntry]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            entries = decoded.entries
        }
    }

    private func save() {
        let snapshot = Snapshot(entries: entries)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
