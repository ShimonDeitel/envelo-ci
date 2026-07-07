import XCTest
@testable import Envelo

final class EnveloTests: XCTestCase {
    func testEntryDefaults() {
        let entry = GiftEntry(personName: "Test", direction: .given, occasion: .birthday, amount: 50)
        XCTAssertEqual(entry.amount, 50)
        XCTAssertEqual(entry.direction, .given)
    }

    @MainActor
    func testStoreAddEntryRespectsFreeLimit() {
        let store = EnveloStore()
        for e in store.entries { store.deleteEntry(e.id) }
        for i in 0..<EnveloStore.freeEntryLimit {
            XCTAssertTrue(store.addEntry(personName: "P\(i)", direction: .given, occasion: .birthday, amount: 10, date: Date(), note: "", isPro: false))
        }
        XCTAssertFalse(store.addEntry(personName: "Overflow", direction: .given, occasion: .birthday, amount: 10, date: Date(), note: "", isPro: false))
        XCTAssertTrue(store.addEntry(personName: "Overflow", direction: .given, occasion: .birthday, amount: 10, date: Date(), note: "", isPro: true))
    }

    @MainActor
    func testAddEntryRejectsEmptyNameOrZeroAmount() {
        let store = EnveloStore()
        for e in store.entries { store.deleteEntry(e.id) }
        XCTAssertFalse(store.addEntry(personName: "   ", direction: .given, occasion: .birthday, amount: 20, date: Date(), note: "", isPro: false))
        XCTAssertFalse(store.addEntry(personName: "Valid Name", direction: .given, occasion: .birthday, amount: 0, date: Date(), note: "", isPro: false))
        XCTAssertEqual(store.entries.count, 0)
    }

    @MainActor
    func testTotalsAndPersonBalance() {
        let store = EnveloStore()
        for e in store.entries { store.deleteEntry(e.id) }
        store.addEntry(personName: "Aunt Rivka", direction: .given, occasion: .birthday, amount: 40, date: Date(), note: "", isPro: false)
        store.addEntry(personName: "Aunt Rivka", direction: .received, occasion: .holiday, amount: 25, date: Date(), note: "", isPro: false)
        XCTAssertEqual(store.totalGiven, 40, accuracy: 0.01)
        XCTAssertEqual(store.totalReceived, 25, accuracy: 0.01)
        let balance = store.personBalances.first { $0.personName == "Aunt Rivka" }
        XCTAssertNotNil(balance)
        XCTAssertEqual(balance?.net ?? 0, 15, accuracy: 0.01)
    }

    @MainActor
    func testReciprocityNudgeFlagsOverdue() {
        let store = EnveloStore()
        for e in store.entries { store.deleteEntry(e.id) }
        let oldDate = Calendar.current.date(byAdding: .month, value: -9, to: Date())!
        store.addEntry(personName: "Cousin Dan", direction: .given, occasion: .graduation, amount: 100, date: oldDate, note: "", isPro: false)
        let nudges = store.reciprocityNudges(monthsThreshold: 6)
        XCTAssertTrue(nudges.contains { $0.personName == "Cousin Dan" })
    }

    @MainActor
    func testReciprocityNudgeIgnoresEvenBalance() {
        let store = EnveloStore()
        for e in store.entries { store.deleteEntry(e.id) }
        let oldDate = Calendar.current.date(byAdding: .month, value: -9, to: Date())!
        store.addEntry(personName: "Even Pat", direction: .given, occasion: .birthday, amount: 50, date: oldDate, note: "", isPro: false)
        store.addEntry(personName: "Even Pat", direction: .received, occasion: .birthday, amount: 50, date: oldDate, note: "", isPro: false)
        let nudges = store.reciprocityNudges(monthsThreshold: 6)
        XCTAssertFalse(nudges.contains { $0.personName == "Even Pat" })
    }

    @MainActor
    func testMilestonesAwardedProgressively() {
        let store = EnveloStore()
        for e in store.entries { store.deleteEntry(e.id) }
        XCTAssertFalse(store.earnedMilestones.contains(.firstEntry))
        store.addEntry(personName: "First", direction: .given, occasion: .birthday, amount: 10, date: Date(), note: "", isPro: false)
        XCTAssertTrue(store.earnedMilestones.contains(.firstEntry))
        XCTAssertFalse(store.earnedMilestones.contains(.fiveHundredGiven))
        store.addEntry(personName: "Big", direction: .given, occasion: .wedding, amount: 500, date: Date(), note: "", isPro: false)
        XCTAssertTrue(store.earnedMilestones.contains(.fiveHundredGiven))
    }

    @MainActor
    func testUpdateEntryModifiesFields() {
        let store = EnveloStore()
        for e in store.entries { store.deleteEntry(e.id) }
        store.addEntry(personName: "Original", direction: .given, occasion: .birthday, amount: 20, date: Date(), note: "", isPro: false)
        let entry = store.entries[0]
        store.updateEntry(entry.id, personName: "Renamed", direction: .received, occasion: .wedding, amount: 99, date: Date(), note: "updated")
        XCTAssertEqual(store.entries[0].personName, "Renamed")
        XCTAssertEqual(store.entries[0].direction, .received)
        XCTAssertEqual(store.entries[0].amount, 99, accuracy: 0.01)
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        let store = EnveloStore()
        store.deleteAllData()
        XCTAssertFalse(store.entries.isEmpty)
    }
}
