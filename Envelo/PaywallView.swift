import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ZStack {
                EVTheme.backdrop.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(EVTheme.coral)
                        .padding(.top, 40)

                    Text("Envelo Pro")
                        .font(EVTheme.titleFont)
                        .foregroundStyle(EVTheme.ink)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("infinity", "Unlimited envelopes")
                        featureRow("person.2.fill", "Per-person running balance")
                        featureRow("chart.pie.fill", "Occasion-by-occasion breakdown")
                        featureRow("clock.badge.exclamationmark.fill", "\"It's been a while\" reciprocity nudges")
                        featureRow("rosette", "Milestone badges")
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Button {
                        purchasing = true
                        Task {
                            await purchases.purchase()
                            purchasing = false
                            if purchases.isPro { dismiss() }
                        }
                    } label: {
                        HStack {
                            if purchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(purchases.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Pro")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(EVTheme.coral)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(purchasing || purchases.product == nil)
                    .padding(.horizontal, 24)

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .font(.footnote)
                    .foregroundStyle(EVTheme.inkFaded)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(EVTheme.ink)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(EVTheme.coral)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(EVTheme.ink)
        }
    }
}

#Preview {
    PaywallView().environmentObject(PurchaseManager())
}
