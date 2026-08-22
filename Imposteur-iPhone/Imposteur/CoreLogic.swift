import Foundation

enum GameLogic {
    static func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased(with: Locale(identifier: "fr_FR"))
    }

    static func pairKey(_ pair: WordPair) -> String {
        [normalize(pair.first), normalize(pair.second)]
            .sorted()
            .joined(separator: "||")
    }

    static func makeRoles(_ config: GameConfiguration) -> [Role] {
        Array(repeating: .civil, count: max(0, config.civil))
        + Array(repeating: .impostor, count: max(0, config.impostor))
        + Array(repeating: .white, count: max(0, config.white))
    }

    static func shuffledRoles<R: RandomNumberGenerator>(_ config: GameConfiguration, using rng: inout R) -> [Role] {
        makeRoles(config).shuffled(using: &rng)
    }

    /// Renvoie les indices des joueurs dans l'ordre de parole initial.
    /// S'il y a au moins un Mr. White, les deux premières places sont
    /// obligatoirement occupées par des joueurs qui ne sont pas Mr. White.
    static func speakingOrderIndices<R: RandomNumberGenerator>(
        for roles: [Role],
        using rng: inout R
    ) -> [Int] {
        let allIndices = Array(roles.indices)
        guard roles.contains(.white) else {
            return allIndices.shuffled(using: &rng)
        }

        var nonWhite = allIndices.filter { roles[$0] != .white }.shuffled(using: &rng)
        guard nonWhite.count >= 2 else {
            // Cette situation est normalement bloquée par configError.
            return allIndices.shuffled(using: &rng)
        }

        let firstTwo = Array(nonWhite.prefix(2))
        nonWhite.removeFirst(2)
        let remaining = (nonWhite + allIndices.filter { roles[$0] == .white }).shuffled(using: &rng)
        return firstTwo + remaining
    }

    static func choosePair<R: RandomNumberGenerator>(
        from library: [WordPair],
        usedKeys: [String],
        using rng: inout R
    ) -> PairSelection? {
        guard !library.isEmpty else { return nil }

        let validKeys = Set(library.map(pairKey))
        var cleanedUsed = usedKeys.filter { validKeys.contains($0) }
        var available = library.filter { !cleanedUsed.contains(pairKey($0)) }

        if available.isEmpty {
            cleanedUsed.removeAll()
            available = library
        }

        guard let pair = available.randomElement(using: &rng) else { return nil }
        cleanedUsed.append(pairKey(pair))

        let reversed = Bool.random(using: &rng)
        return PairSelection(
            pair: pair,
            civilianWord: reversed ? pair.second : pair.first,
            impostorWord: reversed ? pair.first : pair.second,
            updatedUsedKeys: cleanedUsed
        )
    }

    static func configError(_ config: GameConfiguration) -> String? {
        if config.total < 3 { return "Il faut au moins 3 joueurs." }
        if config.total > 10 { return "Maximum 10 joueurs." }
        if config.civil < 1 { return "Il faut au moins 1 civil." }
        if config.impostor + config.white < 1 { return "Il faut au moins 1 imposteur ou 1 Mr. White." }
        if config.civil + config.white <= config.impostor {
            return "Il faut plus de Civils + Mr. White que d'Imposteurs."
        }
        if config.white > 0 && config.civil + config.impostor < 2 {
            return "Avec un Mr. White, il faut au moins 2 joueurs qui ne sont pas Mr. White."
        }
        return nil
    }

    static func winner(for players: [Player]) -> GameWinner? {
        // Une seule passe sur les joueurs : au maximum 10 éléments.
        // Mr. White compte dans le nombre total de joueurs vivants, mais les
        // règles V1.3 comparent les Imposteurs aux Civils classiques.
        var aliveCount = 0
        var impostors = 0
        var civilians = 0

        for player in players where player.alive {
            aliveCount += 1
            switch player.role {
            case .civil: civilians += 1
            case .impostor: impostors += 1
            case .white: break
            }
        }

        // Règles de victoire conservées en V1.4 :
        // - plus aucun imposteur vivant -> victoire des Civils ;
        // - exactement 1 imposteur et 1 civil, seuls encore vivants -> Imposteurs ;
        // - plus d'imposteurs que de civils vivants -> Imposteurs ;
        // - toute autre égalité (ex. 2 contre 2) continue.
        if impostors == 0 { return .civilians }
        if aliveCount == 2 && impostors == 1 && civilians == 1 { return .impostors }
        if impostors > civilians { return .impostors }
        return nil
    }

    static func isValidPair(first: String, second: String) -> Bool {
        let a = normalize(first)
        let b = normalize(second)
        return !a.isEmpty && !b.isEmpty && a != b
    }
}
