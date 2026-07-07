import SwiftUI

struct EntryListView: View {
    @EnvironmentObject private var store: EnveloStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: EntrySheetMode?
    @State private var deletingEntry: GiftEntry?
    @State private var savedToast: String?

    private var sortedEntries: [GiftEntry] {
        store.entries.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EVTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        netBanner

                        if store.entries.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(sortedEntries) { entry in
                                    EnvelopeCard(entry: entry) {
                                        sheetMode = .edit(entry)
                                    } onDelete: {
                                        Haptics.warning()
                                        deletingEntry = entry
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.entries)

                            if !purchases.isPro {
                                Text("Free plan: \(store.entries.count)/\(EnveloStore.freeEntryLimit) envelopes used")
                                    .font(.caption)
                                    .foregroundStyle(EVTheme.inkFaded)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }

                if let name = savedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                            Text(name)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(EVTheme.receivedTeal)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    EntryEditSheet(mode: mode) { name, direction, occasion, amount, date, note in
                        switch mode {
                        case .add:
                            store.addEntry(personName: name, direction: direction, occasion: occasion, amount: amount, date: date, note: note, isPro: purchases.isPro)
                            Haptics.success()
                            showToast("Envelope logged")
                        case .edit(let entry):
                            store.updateEntry(entry.id, personName: name, direction: direction, occasion: occasion, amount: amount, date: date, note: note)
                        case .paywall:
                            break
                        }
                    }
                }
            }
            .confirmationDialog(
                "Remove entry for \(deletingEntry?.personName ?? "")?",
                isPresented: Binding(
                    get: { deletingEntry != nil },
                    set: { if !$0 { deletingEntry = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deletingEntry {
                        store.deleteEntry(deletingEntry.id)
                    }
                    deletingEntry = nil
                }
                Button("Cancel", role: .cancel) { deletingEntry = nil }
            }
        }
    }

    private func showToast(_ text: String) {
        savedToast = text
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if savedToast == text { savedToast = nil }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Envelo")
                    .font(EVTheme.titleFont)
                    .foregroundStyle(EVTheme.ink)
                Text("Gift money, tracked")
                    .font(.caption)
                    .foregroundStyle(EVTheme.inkFaded)
            }
            Spacer()
            Button {
                if store.canAddEntry(isPro: purchases.isPro) {
                    sheetMode = .add
                } else {
                    sheetMode = .paywall
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(EVTheme.coral)
            }
            .accessibilityIdentifier("addEntryButton")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var netBanner: some View {
        HStack(spacing: 0) {
            statTile(label: "Given", value: store.totalGiven, color: EVTheme.coral)
            Divider().frame(height: 34)
            statTile(label: "Received", value: store.totalReceived, color: EVTheme.receivedTeal)
        }
        .padding(.vertical, 14)
        .background(EVTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(EVTheme.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 18)
    }

    private func statTile(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(EVTheme.inkFaded)
            Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 34))
                .foregroundStyle(EVTheme.inkFaded)
            Text("No envelopes logged yet. Tap + to record your first gift.")
                .font(.subheadline)
                .foregroundStyle(EVTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
}

/// The signature visual: a flat envelope card with a colored "flap" wedge at
/// the top matching direction (coral = given, teal = received), and the
/// occasion glyph stamped like a wax seal on the flap point.
private struct EnvelopeCard: View {
    let entry: GiftEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var accentColor: Color {
        entry.direction == .given ? EVTheme.coral : EVTheme.receivedTeal
    }

    var body: some View {
        HStack(spacing: 0) {
            EnvelopeFlapGlyph(symbolName: entry.occasion.symbolName, color: accentColor)
                .frame(width: 54, height: 54)
                .padding(.leading, 14)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.personName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EVTheme.ink)
                HStack(spacing: 6) {
                    Text(entry.occasion.rawValue)
                        .font(.caption)
                        .foregroundStyle(EVTheme.inkFaded)
                    Text("\u{00B7}")
                        .foregroundStyle(EVTheme.inkFaded)
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(EVTheme.inkFaded)
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption2)
                        .foregroundStyle(EVTheme.inkFaded)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 12)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.direction == .given ? "\u{2212}" : "+")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
                +
                Text(entry.amount, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accentColor)

                Menu {
                    Button(action: onEdit) {
                        Label("Edit Envelope", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove Envelope", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(EVTheme.inkFaded)
                        .padding(6)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("entryMenu_\(entry.personName)")
            }
            .padding(.trailing, 14)
        }
        .padding(.vertical, 12)
        .background(EVTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.35), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// A stylized envelope-flap triangle behind the occasion glyph, evoking a
/// sealed envelope corner rather than a generic circular icon badge.
private struct EnvelopeFlapGlyph: View {
    let symbolName: String
    let color: Color

    var body: some View {
        ZStack {
            Triangle()
                .fill(color.opacity(0.16))
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .offset(y: 6)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    EntryListView()
        .environmentObject(EnveloStore())
        .environmentObject(PurchaseManager())
}
