import Foundation

enum Role: String, Codable, CaseIterable {
    case civil
    case impostor
    case white

    var label: String {
        switch self {
        case .civil: return "CIVIL"
        case .impostor: return "IMPOSTEUR"
        case .white: return "MR. WHITE"
        }
    }
}

struct WordPair: Codable, Identifiable, Equatable {
    var id: UUID
    var first: String
    var second: String

    init(id: UUID = UUID(), first: String, second: String) {
        self.id = id
        self.first = first
        self.second = second
    }
}

struct Player: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var role: Role
    var alive: Bool
    var turnOrder: Int

    init(id: UUID = UUID(), name: String, role: Role, alive: Bool = true, turnOrder: Int = 0) {
        self.id = id
        self.name = name
        self.role = role
        self.alive = alive
        self.turnOrder = turnOrder
    }
}

struct GameConfiguration: Equatable {
    var civil = 4
    var impostor = 1
    var white = 1

    var total: Int { civil + impostor + white }
}

struct PairSelection {
    let pair: WordPair
    let civilianWord: String
    let impostorWord: String
    let updatedUsedKeys: [String]
}

enum AppScreen: Equatable {
    case home
    case setup
    case names
    case cards
    case game
    case result
    case library
}

enum GameWinner: Equatable {
    case civilians
    case impostors
    case white

    var title: String {
        switch self {
        case .civilians: return "Victoire des Civils"
        case .impostors: return "Victoire des Imposteurs"
        case .white: return "Victoire de Mr. White"
        }
    }

    var message: String {
        switch self {
        case .civilians:
            return "Tous les imposteurs ont été éliminés."
        case .impostors:
            return "Les imposteurs ont rempli leur condition de victoire."
        case .white:
            return "Mr. White a trouvé le mot des civils."
        }
    }
}

struct EliminationState: Identifiable {
    let id = UUID()
    let playerID: UUID
    let playerName: String
    let role: Role
    var guessSubmitted = false
    var guessCorrect = false
}
