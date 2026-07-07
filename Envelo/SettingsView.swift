import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: EnveloStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("envelo_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("envelo_default_currency_symbol") private var defaultCurrencySymbol: String = "$"
    /// Pro bonus feature: configurable reciprocity-nudge threshold, in months.
    @AppStorage("envelo_nudge_months") private var nudgeMonths: Int = 6

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: EntrySheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                EVTheme.backdrop.ignoresSafeArea()

                Form {
                    Section {
                        if purchases.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(EVTheme.seal)
                                Text("Envelo Pro unlocked")
                                    .foregroundStyle(EVTheme.ink)
                            }
                        } else {
                            Button {
                                sheetMode = .paywall
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill").foregroundStyle(EVTheme.seal)
                                    Text("Unlock Envelo Pro")
                                        .foregroundStyle(EVTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(EVTheme.inkFaded)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(EVTheme.card)

                    if purchases.isPro {
                        Section("Per-Person Balance") {
                            if store.personBalances.isEmpty {
                                Text("Add envelopes to see running balances per person.")
                                    .font(.caption)
                                    .foregroundStyle(EVTheme.inkFaded)
                            } else {
                                ForEach(store.personBalances) { balance in
                                    balanceRow(balance)
                                }
                            }
                        }
                        .listRowBackground(EVTheme.card)

                        Section("Occasion Breakdown") {
                            if store.occasionBreakdown.isEmpty {
                                Text("No occasions logged yet.")
                                    .font(.caption)
                                    .foregroundStyle(EVTheme.inkFaded)
                            } else {
                                ForEach(store.occasionBreakdown, id: \.occasion) { row in
                                    HStack {
                                        Label(row.occasion.rawValue, systemImage: row.occasion.symbolName)
                                            .foregroundStyle(EVTheme.ink)
                                        Spacer()
                                        Text("Given \(row.given, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                            .font(.caption)
                                            .foregroundStyle(EVTheme.coral)
                                        Text("Recv \(row.received, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                            .font(.caption)
                                            .foregroundStyle(EVTheme.receivedTeal)
                                    }
                                }
                            }
                        }
                        .listRowBackground(EVTheme.card)

                        Section("Reciprocity Nudge") {
                            Stepper("Nudge after \(nudgeMonths) months", value: $nudgeMonths, in: 1...24)
                                .foregroundStyle(EVTheme.ink)
                                .accessibilityIdentifier("nudgeMonthsStepper")

                            let nudges = store.reciprocityNudges(monthsThreshold: nudgeMonths)
                            if nudges.isEmpty {
                                Text("Nobody is overdue right now.")
                                    .font(.caption)
                                    .foregroundStyle(EVTheme.inkFaded)
                            } else {
                                ForEach(nudges) { balance in
                                    HStack {
                                        Image(systemName: "clock.badge.exclamationmark.fill")
                                            .foregroundStyle(EVTheme.danger)
                                        Text(balance.personName)
                                            .foregroundStyle(EVTheme.ink)
                                        Spacer()
                                        Text("\(balance.monthsSinceLastGift)mo since last gift")
                                            .font(.caption)
                                            .foregroundStyle(EVTheme.inkFaded)
                                    }
                                }
                            }
                        }
                        .listRowBackground(EVTheme.card)

                        Section("Milestone Badges") {
                            let earned = store.earnedMilestones
                            ForEach(Milestone.allCases) { milestone in
                                let isEarned = earned.contains(milestone)
                                HStack {
                                    Image(systemName: milestone.symbolName)
                                        .foregroundStyle(isEarned ? EVTheme.seal : EVTheme.inkFaded.opacity(0.4))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(milestone.rawValue)
                                            .foregroundStyle(isEarned ? EVTheme.ink : EVTheme.inkFaded)
                                        Text(milestone.detail)
                                            .font(.caption2)
                                            .foregroundStyle(EVTheme.inkFaded)
                                    }
                                    Spacer()
                                    if isEarned {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(EVTheme.receivedTeal)
                                    }
                                }
                            }
                        }
                        .listRowBackground(EVTheme.card)
                    } else {
                        Section("Pro Features") {
                            Text("Unlock per-person balances, occasion breakdowns, the reciprocity nudge, and milestone badges with Envelo Pro.")
                                .font(.caption)
                                .foregroundStyle(EVTheme.inkFaded)
                        }
                        .listRowBackground(EVTheme.card)
                    }

                    Section("Envelopes") {
                        Button {
                            if store.canAddEntry(isPro: purchases.isPro) {
                                sheetMode = .add
                            } else {
                                sheetMode = .paywall
                            }
                        } label: {
                            Label("Add Envelope", systemImage: "plus.circle")
                                .foregroundStyle(EVTheme.coral)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsAddEntryButton")

                        if !purchases.isPro {
                            Text("\(store.entries.count)/\(EnveloStore.freeEntryLimit) free envelopes used")
                                .font(.caption)
                                .foregroundStyle(EVTheme.inkFaded)
                        }
                    }
                    .listRowBackground(EVTheme.card)

                    Section("Preferences") {
                        Picker("Default currency symbol", selection: $defaultCurrencySymbol) {
                            Text("$").tag("$")
                            Text("\u{20AC}").tag("\u{20AC}")
                            Text("\u{00A3}").tag("\u{00A3}")
                            Text("\u{20AA}").tag("\u{20AA}")
                        }
                        .foregroundStyle(EVTheme.ink)
                        .accessibilityIdentifier("currencySymbolPicker")

                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap.fill")
                                .foregroundStyle(EVTheme.ink)
                        }
                        .tint(EVTheme.coral)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(EVTheme.ink)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(EVTheme.card)

                    Section("About") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/envelo-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundStyle(EVTheme.ink)
                        }
                        Link(destination: URL(string: "https://shimondeitel.github.io/envelo-site/support.html")!) {
                            Label("Support", systemImage: "questionmark.circle")
                                .foregroundStyle(EVTheme.ink)
                        }
                        Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundStyle(EVTheme.ink)
                        }
                        HStack {
                            Text("Version").foregroundStyle(EVTheme.ink)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(EVTheme.inkFaded)
                        }
                    }
                    .listRowBackground(EVTheme.card)

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(EVTheme.card)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    EntryEditSheet(mode: mode) { name, direction, occasion, amount, date, note in
                        switch mode {
                        case .add:
                            store.addEntry(personName: name, direction: direction, occasion: occasion, amount: amount, date: date, note: note, isPro: purchases.isPro)
                        case .edit(let entry):
                            store.updateEntry(entry.id, personName: name, direction: direction, occasion: occasion, amount: amount, date: date, note: note)
                        case .paywall:
                            break
                        }
                    }
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every logged envelope. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }

    private func balanceRow(_ balance: PersonBalance) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(balance.personName)
                    .foregroundStyle(EVTheme.ink)
                Text("\(balance.entryCount) envelope\(balance.entryCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(EVTheme.inkFaded)
            }
            Spacer()
            Text(balance.net, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(balance.net >= 0 ? EVTheme.coral : EVTheme.receivedTeal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("balanceRow_\(balance.personName)")
    }
}

#Preview {
    SettingsView()
        .environmentObject(EnveloStore())
        .environmentObject(PurchaseManager())
}
