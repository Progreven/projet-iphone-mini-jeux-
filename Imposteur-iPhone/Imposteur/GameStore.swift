import Foundation
import Combine

@MainActor
final class GameStore: ObservableObject {
    private enum StorageKey {
        static let library = "imposteur.native.library.v1"
        static let used = "imposteur.native.used.v1"
        static let names = "imposteur.native.names.v1"
    }

    @Published var screen: AppScreen = .home
    @Published var config = GameConfiguration()
    @Published var names: [String] = []
    @Published var players: [Player] = []
    @Published var currentPair: WordPair?
    @Published var civilianWord = ""
    @Published var impostorWord = ""
    @Published var cardIndex = 0
    @Published var cardVisible = false
    @Published var elimination: EliminationState?
    @Published var gameWinner: GameWinner?
    @Published var wordPairs: [WordPair]
    @Published var message: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: StorageKey.library),
           let decoded = try? JSONDecoder().decode([WordPair].self, from: data),
           !decoded.isEmpty {
            self.wordPairs = decoded
        } else {
            self.wordPairs = DefaultWords.pairs
        }
    }

    var configError: String? { GameLogic.configError(config) }
    var allNamesFilled: Bool {
        names.count == config.total && names.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func startNewGame() {
        resetRoundData()
        screen = .setup
    }

    func goHome() {
        resetRoundData()
        screen = .home
    }

    func backFromSetup() { screen = .home }
    func backFromNames() { screen = .setup }
    func openLibrary() { screen = .library }
    func closeLibrary() { screen = .home }

    func changeCount(_ role: Role, delta: Int) {
        var next = config
        switch role {
        case .civil: next.civil = max(0, next.civil + delta)
        case .impostor: next.impostor = max(0, next.impostor + delta)
        case .white: next.white = max(0, next.white + delta)
        }
        guard next.total <= 10 else { return }
        config = next
    }

    func prepareNames() {
        guard configError == nil else { return }
        let saved = loadSavedNames()
        names = (0..<config.total).map { index in
            if index < saved.count { return saved[index] }
            return ""
        }
        screen = .names
    }

    func assignGame() {
        guard configError == nil, allNamesFilled, !wordPairs.isEmpty else { return }

        var rng = SystemRandomNumberGenerator()
        let used = loadUsedKeys()
        guard let selection = GameLogic.choosePair(from: wordPairs, usedKeys: used, using: &rng) else { return }

        let roles = GameLogic.shuffledRoles(config, using: &rng)
        let speakingOrder = GameLogic.speakingOrderIndices(for: roles, using: &rng)
        var orderByPlayerIndex = Array(repeating: 0, count: roles.count)
        for (position, playerIndex) in speakingOrder.enumerated() {
            orderByPlayerIndex[playerIndex] = position + 1
        }

        let trimmedNames = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        players = trimmedNames.indices.map { index in
            Player(name: trimmedNames[index], role: roles[index], turnOrder: orderByPlayerIndex[index])
        }
        currentPair = selection.pair
        civilianWord = selection.civilianWord
        impostorWord = selection.impostorWord
        saveUsedKeys(selection.updatedUsedKeys)
        saveNames(trimmedNames)

        cardIndex = 0
        cardVisible = false
        elimination = nil
        screen = .cards
    }

    func showCurrentCard() { cardVisible = true }

    func hideCardAndAdvance() {
        guard !players.isEmpty else { return }
        cardVisible = false
        if cardIndex >= players.count - 1 {
            screen = .game
        } else {
            cardIndex += 1
        }
    }

    func eliminate(_ playerID: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerID && $0.alive }) else { return }
        players[index].alive = false
        let player = players[index]
        elimination = EliminationState(playerID: player.id, playerName: player.name, role: player.role)
    }

    func submitWhiteGuess(_ text: String) {
        guard var current = elimination, current.role == .white else { return }
        current.guessSubmitted = true
        current.guessCorrect = GameLogic.normalize(text) == GameLogic.normalize(civilianWord)
        elimination = current
    }

    func closeElimination() {
        // Mr. White gagne immédiatement s'il a été éliminé et a trouvé
        // correctement le mot des civils. Cette victoire est prioritaire
        // sur les autres conditions calculées après l'élimination.
        if let current = elimination,
           current.role == .white,
           current.guessSubmitted,
           current.guessCorrect {
            elimination = nil
            gameWinner = .white
            screen = .result
            return
        }

        elimination = nil
        if let winner = GameLogic.winner(for: players) {
            gameWinner = winner
            screen = .result
        }
    }

    func playAgain() {
        resetRoundData()
        screen = .setup
    }

    var alivePlayers: [Player] { players.filter(\.alive) }
    var aliveImpostors: Int { alivePlayers.filter { $0.role == .impostor }.count }
    var aliveCivilians: Int { alivePlayers.filter { $0.role == .civil }.count }

    // MARK: - Bibliothèque

    func addPair(first: String, second: String) -> Bool {
        guard GameLogic.isValidPair(first: first, second: second) else {
            message = "Les deux mots doivent être différents et non vides."
            return false
        }
        let candidate = WordPair(first: first.trimmingCharacters(in: .whitespacesAndNewlines), second: second.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !wordPairs.contains(where: { GameLogic.pairKey($0) == GameLogic.pairKey(candidate) }) else {
            message = "Cette paire existe déjà."
            return false
        }
        wordPairs.append(candidate)
        saveLibrary()
        return true
    }

    func updatePair(id: UUID, first: String, second: String) -> Bool {
        guard GameLogic.isValidPair(first: first, second: second),
              let index = wordPairs.firstIndex(where: { $0.id == id }) else {
            message = "Les deux mots doivent être différents et non vides."
            return false
        }
        let candidate = WordPair(id: id, first: first.trimmingCharacters(in: .whitespacesAndNewlines), second: second.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !wordPairs.enumerated().contains(where: { $0.offset != index && GameLogic.pairKey($0.element) == GameLogic.pairKey(candidate) }) else {
            message = "Cette paire existe déjà."
            return false
        }
        wordPairs[index] = candidate
        saveLibrary()
        return true
    }

    func deletePair(id: UUID) {
        guard wordPairs.count > 1 else {
            message = "Il faut garder au moins une paire de mots."
            return
        }
        wordPairs.removeAll { $0.id == id }
        saveLibrary()
    }

    func resetLibrary() {
        wordPairs = DefaultWords.pairs
        saveLibrary()
        saveUsedKeys([])
    }

    func replaceLibrary(with pairs: [WordPair]) -> Bool {
        let clean = pairs.filter { GameLogic.isValidPair(first: $0.first, second: $0.second) }
        let uniqueKeys = Set(clean.map(GameLogic.pairKey))
        guard !clean.isEmpty, uniqueKeys.count == clean.count else {
            message = "Le fichier contient une paire vide, identique ou en double."
            return false
        }
        wordPairs = clean
        saveLibrary()
        saveUsedKeys([])
        return true
    }

    private func resetRoundData() {
        players = []
        currentPair = nil
        civilianWord = ""
        impostorWord = ""
        cardIndex = 0
        cardVisible = false
        elimination = nil
        gameWinner = nil
    }

    private func saveLibrary() {
        if let data = try? JSONEncoder().encode(wordPairs) {
            defaults.set(data, forKey: StorageKey.library)
        }
    }

    private func loadUsedKeys() -> [String] {
        defaults.stringArray(forKey: StorageKey.used) ?? []
    }

    private func saveUsedKeys(_ keys: [String]) {
        defaults.set(keys, forKey: StorageKey.used)
    }

    private func loadSavedNames() -> [String] {
        defaults.stringArray(forKey: StorageKey.names) ?? []
    }

    private func saveNames(_ names: [String]) {
        defaults.set(names, forKey: StorageKey.names)
    }
}
