import Foundation

enum GiftDirection: String, Codable, CaseIterable, Identifiable {
    case given = "Given"
    case received = "Received"

    var id: String { rawValue }
    var symbolName: String {
        switch self {
        case .given: return "arrow.up.right"
        case .received: return "arrow.down.left"
        }
    }
}

enum GiftOccasion: String, Codable, CaseIterable, Identifiable {
    case birthday = "Birthday"
    case wedding = "Wedding"
    case graduation = "Graduation"
    case holiday = "Holiday"
    case newBaby = "New Baby"
    case other = "Other"

    var id: String { rawValue }
    var symbolName: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .wedding: return "heart.fill"
        case .graduation: return "graduationcap.fill"
        case .holiday: return "gift.fill"
        case .newBaby: return "figure.and.child.holdinghands"
        case .other: return "envelope.fill"
        }
    }
}

struct GiftEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var personName: String
    var direction: GiftDirection
    var occasion: GiftOccasion
    var amount: Double
    var date: Date
    var note: String
    var createdDate: Date

    init(
        id: UUID = UUID(),
        personName: String,
        direction: GiftDirection,
        occasion: GiftOccasion,
        amount: Double,
        date: Date = Date(),
        note: String = "",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.direction = direction
        self.occasion = occasion
        self.amount = amount
        self.date = date
        self.note = note
        self.createdDate = createdDate
    }
}

/// A per-person running total: how much has been given to them vs received
/// from them, and the net balance (positive = they owe reciprocity, i.e. you
/// have given more than received; negative = you're behind).
struct PersonBalance: Identifiable {
    var personName: String
    var totalGiven: Double
    var totalReceived: Double
    var lastGiftDate: Date
    var entryCount: Int

    var id: String { personName }

    var net: Double { totalGiven - totalReceived }

    var monthsSinceLastGift: Int {
        let comps = Calendar.current.dateComponents([.month], from: lastGiftDate, to: Date())
        return max(0, comps.month ?? 0)
    }
}

/// Pro bonus feature #1: milestone badges awarded on running totals/streaks.
enum Milestone: String, CaseIterable, Identifiable {
    case firstEntry = "First Envelope"
    case tenEntries = "Regular Giver"
    case fiftyEntries = "Envelope Veteran"
    case fiveHundredGiven = "Generous Streak"
    case fivePeopleTracked = "Circle of Five"
    case fullReciprocity = "Even Keel"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .firstEntry: return "envelope.badge.fill"
        case .tenEntries: return "repeat.circle.fill"
        case .fiftyEntries: return "star.circle.fill"
        case .fiveHundredGiven: return "flame.fill"
        case .fivePeopleTracked: return "person.3.fill"
        case .fullReciprocity: return "scale.3d"
        }
    }

    var detail: String {
        switch self {
        case .firstEntry: return "Logged your first gift."
        case .tenEntries: return "Logged 10 gift entries."
        case .fiftyEntries: return "Logged 50 gift entries."
        case .fiveHundredGiven: return "Given $500 or more in total."
        case .fivePeopleTracked: return "Tracking gifts with 5+ people."
        case .fullReciprocity: return "A person's given/received balance is perfectly even."
        }
    }
}
