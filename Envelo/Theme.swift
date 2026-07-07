import SwiftUI

/// Envelo's identity: a bright parchment-free warm-white backdrop with a
/// coral envelope-flap accent and a deep teal ink for contrast, plus a soft
/// gold "wax seal" highlight for milestones. Deliberately distinct from every
/// sibling app's palette (Beacon's slate/amber-to-cool-blue glow, Ream's
/// red-tape/pencil-yellow marble look, and any cream/ink-navy/amber or
/// walnut/gold-leaf/burgundy "luxury ledger" family).
enum EVTheme {
    static let backdrop = Color(red: 0.984, green: 0.976, blue: 0.965)      // bright warm white
    static let card = Color.white
    static let cardBorder = Color(red: 0.902, green: 0.851, blue: 0.816)

    static let ink = Color(red: 0.145, green: 0.169, blue: 0.192)          // deep teal-charcoal
    static let inkFaded = Color(red: 0.145, green: 0.169, blue: 0.192).opacity(0.56)

    // Envelope flap coral — the given/received signature color pair.
    static let coral = Color(red: 0.910, green: 0.365, blue: 0.318)         // "given" accent
    static let coralDeep = Color(red: 0.737, green: 0.239, blue: 0.208)
    static let receivedTeal = Color(red: 0.145, green: 0.463, blue: 0.443)  // "received" accent
    static let receivedTealDeep = Color(red: 0.098, green: 0.337, blue: 0.322)

    static let seal = Color(red: 0.816, green: 0.639, blue: 0.278)          // wax-seal gold for milestones

    static let danger = Color(red: 0.780, green: 0.271, blue: 0.243)
    static let rule = Color.black.opacity(0.06)

    static let titleFont = Font.system(.title2, design: .serif).weight(.bold)
    static let displayFont = Font.system(size: 40, weight: .bold, design: .serif)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
