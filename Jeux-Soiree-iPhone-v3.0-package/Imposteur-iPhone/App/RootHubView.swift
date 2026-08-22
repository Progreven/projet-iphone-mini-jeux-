import SwiftUI

enum MiniGameDestination: String, Identifiable {
    case imposteur
    case headsUp
    case werewolf

    var id: String { rawValue }
}

struct RootHubView: View {
    @State private var destination: MiniGameDestination?

    var body: some View {
        Group {
            switch destination {
            case .none:
                GameHubView { destination = $0 }
            case .imposteur:
                ImposteurModuleView { destination = nil }
            case .headsUp:
                HeadsUpModuleView { destination = nil }
            case .werewolf:
                WerewolfModuleView { destination = nil }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: destination?.rawValue)
    }
}

private struct GameHubView: View {
    let openGame: (MiniGameDestination) -> Void

    var body: some View {
        PartyPage {
            VStack(alignment: .leading, spacing: 5) {
                Text("Jeux Soirée")
                    .font(.largeTitle.bold())
                Text("Choisis un mini-jeu")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MiniGameCard(
                title: "Imposteur (Undercover)",
                subtitle: "Bluff, mots secrets et Mr. White",
                systemImage: "person.2.fill"
            ) {
                openGame(.imposteur)
            }

            MiniGameCard(
                title: "Heads Up",
                subtitle: "Fais deviner un maximum de cartes",
                systemImage: "iphone"
            ) {
                openGame(.headsUp)
            }

            MiniGameCard(
                title: "Werewolf",
                subtitle: "Loup-Garou avec assistant du Maître du Jeu",
                systemImage: "moon.stars.fill"
            ) {
                openGame(.werewolf)
            }
        }
    }
}

private struct MiniGameCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 54, height: 54)
                    .background(Color.accentColor.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
