import SwiftUI

struct WerewolfRulesView: View {
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Objectif") {
                    Text("Le Village cherche à éliminer tous les Loups-Garous. Les Loups-Garous cherchent à éliminer tous les joueurs du camp du Village. Le Maître du Jeu guide les nuits et conserve le téléphone.")
                }

                Section("Déroulement") {
                    Text("La nuit, tout le monde ferme les yeux. L’application indique au Maître du Jeu quels rôles réveiller et dans quel ordre. Le jour, les survivants discutent puis votent dans la vraie vie. L’application n’autorise qu’une seule élimination décidée par le vote du village avant de relancer automatiquement la nuit suivante.")
                    Text("La première nuit ajoute les actions du Voleur et de Cupidon. Les nuits suivantes ne les répètent plus.")
                }

                Section("Ordre de la première nuit") {
                    Text("Village endormi → Voleur → Cupidon → Amoureux → Voyante → Loups-Garous (Petite Fille) → Sorcière → Réveil du village.")
                }

                Section("Ordre des nuits suivantes") {
                    Text("Village endormi → Voyante → Loups-Garous (Petite Fille) → Sorcière → Réveil du village. Les rôles morts sont automatiquement ignorés.")
                }

                Section("Règles maison de cette application") {
                    Text("Les Loups-Garous peuvent viser n’importe quel joueur vivant, y compris un autre Loup-Garou.")
                    Text("Le Voleur utilise votre variante : la première nuit, il choisit deux joueurs et échange leurs rôles. L’application demande ensuite de réveiller séparément les deux joueurs afin de leur montrer leur nouveau rôle.")
                }

                Section("Sorcière") {
                    Text("La Sorcière possède une potion de vie et une potion de mort. Chaque potion ne peut être utilisée qu’une fois pendant la partie, et les deux peuvent être utilisées la même nuit.")
                }

                Section("Cupidon et les Amoureux") {
                    Text("Cupidon choisit deux Amoureux la première nuit. Si l’un meurt, l’autre meurt immédiatement de chagrin. Si le couple est mixte (un Loup-Garou et un membre du Village) et qu’ils sont les deux derniers survivants, les Amoureux gagnent ensemble.")
                }

                Section("Chasseur") {
                    Text("Quand le Chasseur meurt, l’application interrompt la partie afin que le Maître du Jeu sélectionne la personne qu’il emporte avec lui.")
                }

                Section("Maire") {
                    Text("Le Maire est obligatoirement élu pendant le premier jour et son statut s’ajoute à son rôle secret. Il ne possède pas de voix supplémentaire : il sert uniquement à départager le vote en cas d’égalité. S’il meurt et que la partie continue, l’application demande de choisir son successeur.")
                }

                Section("Jeu de base") {
                    Text("Cette version utilise uniquement les rôles du set de base : Villageois, Loup-Garou, Voyante, Sorcière, Chasseur, Cupidon, Petite Fille et Voleur. Le Maire est un statut public, pas un rôle secret distribué.")
                }
            }
            .navigationTitle("Règles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer", action: onClose)
                }
            }
        }
    }
}

struct WerewolfCharactersView: View {
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(WerewolfRole.allCases) { role in
                        WerewolfCharacterCard(
                            imageName: role.imageName,
                            title: role.title,
                            text: role.shortDescription
                        )
                    }

                    WerewolfCharacterCard(
                        imageName: "WWMaire",
                        title: "Maire",
                        text: "Élu obligatoirement pendant le premier jour. Il départage uniquement les égalités lors du vote. S’il meurt, un successeur est choisi tant que la partie continue."
                    )
                }
                .padding(20)
            }
            .navigationTitle("Personnages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer", action: onClose)
                }
            }
        }
    }
}

private struct WerewolfCharacterCard: View {
    let imageName: String
    let title: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 105, height: 138)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.title3.bold())
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
