import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("ECHEC: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct TestRunner {
    static func main() {
        require(DefaultWords.pairs.count == 100, "La bibliothèque par défaut doit contenir 100 paires")
        let keys = DefaultWords.pairs.map(GameLogic.pairKey)
        require(Set(keys).count == 100, "Les 100 paires doivent être uniques")
        require(GameLogic.normalize("  ÉLÉPHANT ") == "elephant", "Normalisation accents/majuscules")

        let config = GameConfiguration(civil: 5, impostor: 2, white: 1)
        let roles = GameLogic.makeRoles(config)
        require(roles.count == 8, "Nombre total de rôles")
        require(roles.filter { $0 == .civil }.count == 5, "Nombre de civils")
        require(roles.filter { $0 == .impostor }.count == 2, "Nombre d'imposteurs")
        require(roles.filter { $0 == .white }.count == 1, "Nombre de Mr. White")

        var rng = SeededGenerator(seed: 42)
        var used: [String] = []
        var seen = Set<String>()
        for _ in 0..<100 {
            guard let selection = GameLogic.choosePair(from: DefaultWords.pairs, usedKeys: used, using: &rng) else {
                require(false, "Sélection d'une paire")
                return
            }
            let key = GameLogic.pairKey(selection.pair)
            require(!seen.contains(key), "Aucune répétition avant épuisement")
            seen.insert(key)
            used = selection.updatedUsedKeys
            require(GameLogic.normalize(selection.civilianWord) != GameLogic.normalize(selection.impostorWord), "Mots différents")
        }
        require(seen.count == 100, "Les 100 paires ont été utilisées une fois")


        // Ordre de passage : Mr. White ne doit jamais être 1er ni 2e.
        for seed in 0..<500 {
            var orderRng = SeededGenerator(seed: UInt64(seed + 1))
            let testRoles: [Role] = [.civil, .impostor, .white, .civil, .white, .impostor]
            let order = GameLogic.speakingOrderIndices(for: testRoles, using: &orderRng)
            require(order.count == testRoles.count, "Ordre de passage complet")
            require(Set(order).count == testRoles.count, "Chaque joueur apparaît une seule fois dans l'ordre")
            require(testRoles[order[0]] != .white, "Mr. White ne doit jamais être premier")
            require(testRoles[order[1]] != .white, "Mr. White ne doit jamais être deuxième")
        }

        var noWhiteRng = SeededGenerator(seed: 999)
        let noWhiteRoles: [Role] = [.civil, .impostor, .civil, .impostor]
        let noWhiteOrder = GameLogic.speakingOrderIndices(for: noWhiteRoles, using: &noWhiteRng)
        require(Set(noWhiteOrder) == Set(noWhiteRoles.indices), "Ordre valide sans Mr. White")

        require(GameLogic.configError(GameConfiguration(civil: 4, impostor: 1, white: 1)) == nil, "Configuration valide")
        require(GameLogic.configError(GameConfiguration(civil: 9, impostor: 2, white: 0)) != nil, "Blocage > 10 joueurs")
        require(GameLogic.configError(GameConfiguration(civil: 0, impostor: 1, white: 2)) != nil, "Au moins un civil")
        require(GameLogic.configError(GameConfiguration(civil: 1, impostor: 0, white: 2)) != nil, "Deux non-Mr. White minimum si Mr. White présent")
        require(GameLogic.configError(GameConfiguration(civil: 2, impostor: 2, white: 0)) != nil, "Les non-imposteurs doivent être strictement majoritaires au départ")
        require(GameLogic.configError(GameConfiguration(civil: 1, impostor: 2, white: 1)) != nil, "Civil + Mr. White à égalité avec les imposteurs doit être refusé")
        require(GameLogic.configError(GameConfiguration(civil: 2, impostor: 2, white: 1)) == nil, "Civil + Mr. White majoritaires doit être accepté")
        require(GameLogic.configError(GameConfiguration(civil: 3, impostor: 2, white: 0)) == nil, "Majorité de civils sans Mr. White acceptée")
        require(GameLogic.isValidPair(first: "Chat", second: "Tigre"), "Paire valide")
        require(!GameLogic.isValidPair(first: "Chat", second: "chat"), "Deux mots identiques refusés")

        // Conditions de fin de partie automatiques V1.3.
        let civiliansWin = [
            Player(name: "A", role: .civil),
            Player(name: "B", role: .civil),
            Player(name: "C", role: .impostor, alive: false),
            Player(name: "D", role: .white)
        ]
        require(GameLogic.winner(for: civiliansWin) == .civilians, "0 imposteur vivant = victoire des Civils")

        let oneVsOne = [
            Player(name: "A", role: .civil),
            Player(name: "B", role: .impostor)
        ]
        require(GameLogic.winner(for: oneVsOne) == .impostors, "1 imposteur + 1 civil seuls en vie = victoire des Imposteurs")

        let oneVsOnePlusWhite = [
            Player(name: "A", role: .civil),
            Player(name: "B", role: .impostor),
            Player(name: "C", role: .white)
        ]
        require(GameLogic.winner(for: oneVsOnePlusWhite) == nil, "1 imposteur + 1 civil + Mr. White : la partie continue")

        let twoVsTwo = [
            Player(name: "A", role: .civil),
            Player(name: "B", role: .civil),
            Player(name: "C", role: .impostor),
            Player(name: "D", role: .impostor),
            Player(name: "E", role: .white)
        ]
        require(GameLogic.winner(for: twoVsTwo) == nil, "2 imposteurs = 2 civils : la partie continue")

        let majorityWin = [
            Player(name: "A", role: .civil),
            Player(name: "B", role: .impostor),
            Player(name: "C", role: .impostor),
            Player(name: "D", role: .white)
        ]
        require(GameLogic.winner(for: majorityWin) == .impostors, "Plus d'imposteurs que de civils = victoire des Imposteurs")

        let continueGame = [
            Player(name: "A", role: .civil),
            Player(name: "B", role: .civil),
            Player(name: "C", role: .civil),
            Player(name: "D", role: .impostor),
            Player(name: "E", role: .white)
        ]
        require(GameLogic.winner(for: continueGame) == nil, "Moins d'imposteurs que de civils = la partie continue")


        // Vérification exhaustive des configurations possibles jusqu'à 10 joueurs.
        for civil in 0...10 {
            for impostor in 0...10 {
                for white in 0...10 {
                    let cfg = GameConfiguration(civil: civil, impostor: impostor, white: white)
                    let total = civil + impostor + white
                    let shouldBeValid = total >= 3
                        && total <= 10
                        && civil >= 1
                        && impostor + white >= 1
                        && civil + white > impostor
                        && (white == 0 || civil + impostor >= 2)
                    require((GameLogic.configError(cfg) == nil) == shouldBeValid, "Validation exhaustive de configuration \(civil)/\(impostor)/\(white)")
                }
            }
        }

        // Vérification exhaustive des règles de victoire sur de petites compositions.
        for civil in 0...4 {
            for impostor in 0...4 {
                for white in 0...3 {
                    let testPlayers =
                        (0..<civil).map { Player(name: "C\($0)", role: .civil) }
                        + (0..<impostor).map { Player(name: "I\($0)", role: .impostor) }
                        + (0..<white).map { Player(name: "W\($0)", role: .white) }
                    let aliveCount = civil + impostor + white
                    let expected: GameWinner?
                    if impostor == 0 {
                        expected = .civilians
                    } else if aliveCount == 2 && impostor == 1 && civil == 1 {
                        expected = .impostors
                    } else if impostor > civil {
                        expected = .impostors
                    } else {
                        expected = nil
                    }
                    require(GameLogic.winner(for: testPlayers) == expected, "Victoire exhaustive C=\(civil) I=\(impostor) W=\(white)")
                }
            }
        }

        require(GameWinner.white.title == "Victoire de Mr. White", "Titre de victoire Mr. White")

        print("Tous les tests de logique ont réussi.")
    }
}
