import SwiftUI

/// Enveloppe le mini-jeu Imposteur V1.4 sans modifier son code interne.
/// Le GameStore n'existe que lorsque ce module est affiché.
struct ImposteurModuleView: View {
    @StateObject private var store = GameStore()
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if store.screen == .home {
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Retour aux mini-jeux")

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            ContentView()
                .environmentObject(store)
        }
    }
}
