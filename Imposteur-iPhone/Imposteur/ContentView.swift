import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Group {
            switch store.screen {
            case .home: HomeView()
            case .setup: SetupView()
            case .names: NamesView()
            case .cards: CardsView()
            case .game: GameView()
            case .result: ResultView()
            case .library: LibraryView()
            }
        }
        .animation(.easeInOut(duration: 0.18), value: store.screen)
        .alert("Information", isPresented: Binding(
            get: { store.message != nil },
            set: { if !$0 { store.message = nil } }
        )) {
            Button("OK", role: .cancel) { store.message = nil }
        } message: {
            Text(store.message ?? "")
        }
    }
}

private struct Page<Content: View>: View {
    let backgroundTapAction: (() -> Void)?
    let content: Content

    init(backgroundTapAction: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.backgroundTapAction = backgroundTapAction
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                content
            }
            .padding(20)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .background {
                if let backgroundTapAction {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: backgroundTapAction)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Page {
            HStack {
                Text("Imposteur")
                    .font(.largeTitle.bold())
                Spacer()
            }

            RoundedPanel {
                Text("Jeu local")
                    .font(.title2.bold())
                Text("Civils, Imposteurs et Mr. White sur un seul iPhone.")
                    .foregroundStyle(.secondary)

                Button("Nouvelle partie") { store.startNewGame() }
                    .buttonStyle(MainButtonStyle())

                Button("Bibliothèque de mots") { store.openLibrary() }
                    .buttonStyle(MainButtonStyle(secondary: true))

                Text("\(store.wordPairs.count) paires disponibles")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct SetupView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Page {
            HeaderView(title: "Configuration", backAction: store.backFromSetup)

            RoundedPanel {
                CounterRow(title: "Civils", value: store.config.civil) {
                    store.changeCount(.civil, delta: -1)
                } increment: {
                    store.changeCount(.civil, delta: 1)
                }
                CounterRow(title: "Imposteurs", value: store.config.impostor) {
                    store.changeCount(.impostor, delta: -1)
                } increment: {
                    store.changeCount(.impostor, delta: 1)
                }
                CounterRow(title: "Mr. White", value: store.config.white) {
                    store.changeCount(.white, delta: -1)
                } increment: {
                    store.changeCount(.white, delta: 1)
                }

                Divider()
                Text("Total : \(store.config.total) / 10")
                    .font(.headline)

                if let error = store.configError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Button("Choisir les noms") { store.prepareNames() }
                    .buttonStyle(MainButtonStyle())
                    .disabled(store.configError != nil)
                    .opacity(store.configError == nil ? 1 : 0.45)
            }
        }
    }
}

private struct CounterRow: View {
    let title: String
    let value: Int
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Button(action: decrement) {
                Image(systemName: "minus")
                    .frame(width: 38, height: 38)
                    .background(Color.gray.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            Text("\(value)")
                .font(.title3.monospacedDigit().bold())
                .frame(width: 34)
            Button(action: increment) {
                Image(systemName: "plus")
                    .frame(width: 38, height: 38)
                    .background(Color.gray.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
        }
    }
}

struct NamesView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Page {
            HeaderView(title: "Noms des joueurs", backAction: store.backFromNames)

            RoundedPanel {
                ForEach(0..<store.config.total, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Joueur \(index + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Prénom", text: Binding(
                            get: { index < store.names.count ? store.names[index] : "" },
                            set: { newValue in
                                guard index < store.names.count else { return }
                                store.names[index] = String(newValue.prefix(24))
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                    }
                }

                Button("Attribuer les rôles au hasard") { store.assignGame() }
                    .buttonStyle(MainButtonStyle())
                    .disabled(!store.allNamesFilled)
                    .opacity(store.allNamesFilled ? 1 : 0.45)
            }
        }
    }
}

struct CardsView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        let player = store.players.indices.contains(store.cardIndex) ? store.players[store.cardIndex] : nil

        Page {
            Text("Carte secrète")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            if let player {
                RoundedPanel {
                    if !store.cardVisible {
                        Text("Passe le téléphone à")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(player.name)
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Personne d’autre ne doit regarder.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Button("Voir ma carte") { store.showCurrentCard() }
                            .buttonStyle(MainButtonStyle())
                    } else {
                        Text(player.name)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(player.role.label)
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .center)

                        if player.role == .white {
                            Text("Aucun mot")
                                .font(.title.bold())
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("Écoute les indices et essaie de deviner le mot des civils.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Ton mot")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(player.role == .civil ? store.civilianWord : store.impostorWord)
                                .font(.system(size: 34, weight: .bold))
                                .minimumScaleFactor(0.6)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        Button(store.cardIndex == store.players.count - 1 ? "Masquer et commencer" : "Masquer et passer") {
                            store.hideCardAndAdvance()
                        }
                        .buttonStyle(MainButtonStyle())
                    }
                }
            }
        }
    }
}

struct GameView: View {
    @EnvironmentObject private var store: GameStore
    @State private var activeAlert: GameAlert?
    @State private var actionMode: PlayerActionMode?
    @State private var reviewPlayer: Player?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private enum PlayerActionMode {
        case reviewCard
        case eliminate
    }

    private enum GameAlert: Identifiable {
        case home
        case eliminate(Player)

        var id: String {
            switch self {
            case .home: return "home"
            case .eliminate(let player): return "eliminate-\(player.id.uuidString)"
            }
        }
    }

    var body: some View {
        Page(backgroundTapAction: deactivateMode) {
            HeaderView(title: "Partie en cours", homeAction: {
                deactivateMode()
                activeAlert = .home
            })

            Text("Ordre de passage initial : le numéro est affiché en haut à droite de chaque joueur.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(instructionText)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.players) { player in
                    Button {
                        select(player)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 6) {
                                Text(player.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                if !player.alive {
                                    Text(player.role.label)
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 74)
                            .padding(.horizontal, 8)

                            Text("\(player.turnOrder)")
                                .font(.caption.monospacedDigit().bold())
                                .frame(minWidth: 25, minHeight: 25)
                                .background(Color.gray.opacity(0.18))
                                .clipShape(Circle())
                                .padding(8)
                                .accessibilityLabel("Passage numéro \(player.turnOrder)")
                        }
                        .background(Color.gray.opacity(player.alive ? 0.12 : 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            if !player.alive {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!player.alive)
                    .opacity(player.alive ? 1 : 0.55)
                    .accessibilityHint(accessibilityHint)
                }
            }

            // Zone volontairement vide : un toucher ici quitte aussi le mode actif.
            Color.clear
                .frame(height: 28)
                .contentShape(Rectangle())
                .onTapGesture(perform: deactivateMode)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    toggleMode(.reviewCard)
                } label: {
                    Label("Revoir ma carte", systemImage: "eye.fill")
                }
                .buttonStyle(GameModeButtonStyle(isActive: actionMode == .reviewCard))

                Button {
                    toggleMode(.eliminate)
                } label: {
                    Label("Éliminer", systemImage: "person.fill.xmark")
                }
                .buttonStyle(GameModeButtonStyle(isActive: actionMode == .eliminate))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .home:
                return Alert(
                    title: Text("Retour à l’accueil"),
                    message: Text("Vous êtes sûr de revenir à la maison ? La partie en cours sera abandonnée."),
                    primaryButton: .cancel(Text("Annuler")),
                    secondaryButton: .destructive(Text("Oui, quitter la partie")) { store.goHome() }
                )

            case .eliminate(let player):
                return Alert(
                    title: Text("Confirmer l’élimination"),
                    message: Text("Vous êtes sûr de vouloir éliminer \(player.name) ?"),
                    primaryButton: .cancel(Text("Annuler")),
                    secondaryButton: .destructive(Text("Éliminer")) { store.eliminate(player.id) }
                )
            }
        }
        .sheet(item: $reviewPlayer) { player in
            CardReviewView(player: player)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $store.elimination) { elimination in
            EliminationView(elimination: elimination)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
        }
    }

    private var instructionText: String {
        switch actionMode {
        case .reviewCard:
            return "Mode Revoir ma carte actif : touche ton prénom."
        case .eliminate:
            return "Mode Éliminer actif : touche la personne choisie après le vote."
        case nil:
            return "Choisis une action en bas de l’écran, puis touche un joueur."
        }
    }

    private var accessibilityHint: String {
        switch actionMode {
        case .reviewCard: return "Revoir la carte de ce joueur"
        case .eliminate: return "Choisir ce joueur pour l’élimination"
        case nil: return "Choisissez d’abord une action en bas de l’écran"
        }
    }

    private func toggleMode(_ mode: PlayerActionMode) {
        actionMode = actionMode == mode ? nil : mode
    }

    private func deactivateMode() {
        actionMode = nil
    }

    private func select(_ player: Player) {
        guard player.alive else { return }

        switch actionMode {
        case .reviewCard:
            deactivateMode()
            reviewPlayer = player
        case .eliminate:
            deactivateMode()
            activeAlert = .eliminate(player)
        case nil:
            break
        }
    }
}

struct CardReviewView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let player: Player
    @State private var cardVisible = false

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            if !cardVisible {
                Text("Passe le téléphone à")
                    .foregroundStyle(.secondary)
                Text(player.name)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Personne d’autre ne doit regarder.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Revoir ma carte") {
                    cardVisible = true
                }
                .buttonStyle(MainButtonStyle())
            } else {
                Text(player.name)
                    .foregroundStyle(.secondary)
                Text(player.role.label)
                    .font(.largeTitle.bold())

                if player.role == .white {
                    Text("Aucun mot")
                        .font(.title.bold())
                    Text("Tu es Mr. White.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Ton mot")
                        .foregroundStyle(.secondary)
                    Text(player.role == .civil ? store.civilianWord : store.impostorWord)
                        .font(.system(size: 34, weight: .bold))
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.center)
                }

                Button("Masquer et revenir") {
                    cardVisible = false
                    dismiss()
                }
                .buttonStyle(MainButtonStyle())
            }
        }
        .padding(24)
    }
}

struct ResultView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Page {
            Text("Partie terminée")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            RoundedPanel {
                if let winner = store.gameWinner {
                    Text(winner.title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Text(winner.message)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Button("Nouvelle partie") { store.playAgain() }
                    .buttonStyle(MainButtonStyle())
                Button("Retour à l’accueil") { store.goHome() }
                    .buttonStyle(MainButtonStyle(secondary: true))
            }
        }
    }
}

struct EliminationView: View {
    @EnvironmentObject private var store: GameStore
    let elimination: EliminationState
    @State private var guess = ""

    private var currentElimination: EliminationState {
        store.elimination ?? elimination
    }

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            Text("\(currentElimination.playerName) était")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(currentElimination.role.label)
                .font(.largeTitle.bold())

            if currentElimination.role == .white {
                if currentElimination.guessSubmitted {
                    Text(currentElimination.guessCorrect ? "Bonne réponse !" : "Mauvaise réponse")
                        .font(.title2.bold())
                    Text("Le mot des civils était : \(store.civilianWord)")
                        .multilineTextAlignment(.center)
                } else {
                    Text("Dernière chance : devine le mot des civils.")
                        .multilineTextAlignment(.center)
                    TextField("Mot des civils", text: $guess)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Valider") { store.submitWhiteGuess(guess) }
                        .buttonStyle(MainButtonStyle())
                        .disabled(guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Button("Continuer") { store.closeElimination() }
                .buttonStyle(MainButtonStyle(secondary: true))
        }
        .padding(24)
    }
}

private struct PairEditorContext: Identifiable {
    let id = UUID()
    let pair: WordPair?
}

private struct PairEditorView: View {
    let pair: WordPair?
    let save: (String, String) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var first: String
    @State private var second: String

    init(pair: WordPair?, save: @escaping (String, String) -> Bool) {
        self.pair = pair
        self.save = save
        _first = State(initialValue: pair?.first ?? "")
        _second = State(initialValue: pair?.second ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Premier mot", text: $first)
                TextField("Deuxième mot", text: $second)
            }
            .navigationTitle(pair == nil ? "Ajouter une paire" : "Modifier la paire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        if save(first, second) { dismiss() }
                    }
                }
            }
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var search = ""
    @State private var editor: PairEditorContext?
    @State private var showReset = false
    @State private var showImporter = false
    @State private var showExporter = false

    private var filteredPairs: [WordPair] {
        let term = GameLogic.normalize(search)
        guard !term.isEmpty else { return store.wordPairs }
        return store.wordPairs.filter {
            GameLogic.normalize($0.first).contains(term) || GameLogic.normalize($0.second).contains(term)
        }
    }

    var body: some View {
        Page {
            HeaderView(title: "Bibliothèque", backAction: store.closeLibrary)

            TextField("Rechercher un mot", text: $search)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 10) {
                Button {
                    editor = PairEditorContext(pair: nil)
                } label: {
                    Label("Ajouter", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MainButtonStyle())

                Menu {
                    Button("Importer JSON") { showImporter = true }
                    Button("Exporter JSON") { showExporter = true }
                    Divider()
                    Button("Remettre les 100 paires", role: .destructive) { showReset = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 48, height: 48)
                        .background(Color.gray.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Text("\(store.wordPairs.count) paires")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVStack(spacing: 10) {
                ForEach(filteredPairs) { pair in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pair.first).font(.headline)
                            Text("↔ \(pair.second)").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            editor = PairEditorContext(pair: pair)
                        } label: {
                            Image(systemName: "pencil")
                                .frame(width: 38, height: 38)
                                .background(Color.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                        Button(role: .destructive) {
                            store.deletePair(id: pair.id)
                        } label: {
                            Image(systemName: "trash")
                                .frame(width: 38, height: 38)
                                .background(Color.red.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .sheet(item: $editor) { context in
            PairEditorView(pair: context.pair) { first, second in
                if let pair = context.pair {
                    return store.updatePair(id: pair.id, first: first, second: second)
                } else {
                    return store.addPair(first: first, second: second)
                }
            }
        }
        .alert("Réinitialiser la bibliothèque ?", isPresented: $showReset) {
            Button("Annuler", role: .cancel) {}
            Button("Réinitialiser", role: .destructive) { store.resetLibrary() }
        } message: {
            Text("Tes modifications seront remplacées par les 100 paires d’origine.")
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                let pairs: [WordPair]
                if let decoded = try? JSONDecoder().decode([WordPair].self, from: data) {
                    pairs = decoded
                } else if let legacy = try? JSONDecoder().decode([[String]].self, from: data) {
                    pairs = legacy.compactMap { row in
                        guard row.count == 2 else { return nil }
                        return WordPair(first: row[0], second: row[1])
                    }
                } else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                _ = store.replaceLibrary(with: pairs)
            } catch {
                store.message = "Impossible d’importer ce fichier JSON."
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: LibraryDocument(pairs: store.wordPairs),
            contentType: .json,
            defaultFilename: "imposteur-mots"
        ) { result in
            if case .failure = result {
                store.message = "Impossible d’exporter la bibliothèque."
            }
        }
    }
}
