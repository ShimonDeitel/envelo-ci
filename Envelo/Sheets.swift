import SwiftUI

/// One unified sheet enum per screen — stacking multiple `.sheet(item:)` or
/// `.alert(...)` modifiers on the same view is a known SwiftUI bug (only the
/// last-declared one reliably fires). Route every sheet through this enum.
enum EntrySheetMode: Identifiable {
    case add
    case edit(GiftEntry)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let entry): return entry.id.uuidString
        case .paywall: return "paywall"
        }
    }
}

struct EntryEditSheet: View {
    let mode: EntrySheetMode
    let onSave: (String, GiftDirection, GiftOccasion, Double, Date, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var personName: String
    @State private var direction: GiftDirection
    @State private var occasion: GiftOccasion
    @State private var amountText: String
    @State private var date: Date
    @State private var note: String

    init(mode: EntrySheetMode, onSave: @escaping (String, GiftDirection, GiftOccasion, Double, Date, String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .edit(let entry):
            _personName = State(initialValue: entry.personName)
            _direction = State(initialValue: entry.direction)
            _occasion = State(initialValue: entry.occasion)
            _amountText = State(initialValue: String(format: "%.2f", entry.amount))
            _date = State(initialValue: entry.date)
            _note = State(initialValue: entry.note)
        default:
            _personName = State(initialValue: "")
            _direction = State(initialValue: .received)
            _occasion = State(initialValue: .birthday)
            _amountText = State(initialValue: "")
            _date = State(initialValue: Date())
            _note = State(initialValue: "")
        }
    }

    private var title: String {
        if case .edit = mode { return "Edit Envelope" }
        return "New Envelope"
    }

    private var parsedAmount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var isValid: Bool {
        !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Direction") {
                    Picker("Direction", selection: $direction) {
                        ForEach(GiftDirection.allCases) { d in
                            Label(d.rawValue, systemImage: d.symbolName).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("directionPicker")
                }

                Section("Gift") {
                    TextField("Person's name", text: $personName)
                        .accessibilityIdentifier("personNameField")

                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("amountField")

                    Picker("Occasion", selection: $occasion) {
                        ForEach(GiftOccasion.allCases) { occ in
                            Label(occ.rawValue, systemImage: occ.symbolName).tag(occ)
                        }
                    }
                    .accessibilityIdentifier("occasionPicker")

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("entryDatePicker")
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .accessibilityIdentifier("noteField")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(personName, direction, occasion, parsedAmount, date, note)
                        dismiss()
                    }
                    .accessibilityIdentifier("entrySaveButton")
                    .disabled(!isValid)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
