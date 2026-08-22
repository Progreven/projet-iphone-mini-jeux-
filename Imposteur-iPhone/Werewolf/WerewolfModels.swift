import Foundation

enum WerewolfCamp: String, Codable {
    case village
    case wolves
}

enum WerewolfRole: String, CaseIterable, Codable, Identifiable {
    case villager
    case werewolf
    case seer
    case witch
    case hunter
    case cupid
    case littleGirl
    case thief

    var id: String { rawValue }

    var title: String {
        switch self {
        case .villager: return "Villageois"
        case .werewolf: return "Loup-Garou"
        case .seer: return "Voyante"
        case .witch: return "Sorcière"
        case .hunter: return "Chasseur"
        case .cupid: return "Cupidon"
        case .littleGirl: return "Petite Fille"
        case .thief: return "Voleur"
        }
    }

    var shortDescription: String {
        switch self {
        case .villager:
            return "Tu n’as pas de pouvoir nocturne. Observe, discute et vote pour éliminer les Loups-Garous."
        case .werewolf:
            return "Chaque nuit, réveille-toi avec les autres Loups-Garous et choisissez une victime."
        case .seer:
            return "Chaque nuit, tu peux découvrir le rôle secret d’un joueur."
        case .witch:
            return "Tu possèdes une potion de vie et une potion de mort, utilisables une seule fois chacune."
        case .hunter:
            return "Si tu meurs, tu dois désigner un joueur qui meurt avec toi."
        case .cupid:
            return "La première nuit, choisis deux Amoureux. Si l’un meurt, l’autre meurt de chagrin."
        case .littleGirl:
            return "Pendant le réveil des Loups-Garous, tu peux tenter de les observer discrètement."
        case .thief:
            return "La première nuit, tu choisis deux joueurs et leurs rôles sont échangés. Les deux joueurs découvrent ensuite leur nouveau rôle."
        }
    }

    var camp: WerewolfCamp {
        self == .werewolf ? .wolves : .village
    }

    var repeatable: Bool {
        self == .villager || self == .werewolf
    }

    var imageName: String {
        switch self {
        case .villager: return "WWVillageois"
        case .werewolf: return "WWLoupGarou"
        case .seer: return "WWVoyante"
        case .witch: return "WWSorciere"
        case .hunter: return "WWChasseur"
        case .cupid: return "WWCupidon"
        case .littleGirl: return "WWPetiteFille"
        case .thief: return "WWVoleur"
        }
    }
}

struct WerewolfPlayer: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var role: WerewolfRole
    var alive: Bool
    var isLover: Bool
    var isMayor: Bool

    init(id: UUID = UUID(), name: String, role: WerewolfRole, alive: Bool = true, isLover: Bool = false, isMayor: Bool = false) {
        self.id = id
        self.name = name
        self.role = role
        self.alive = alive
        self.isLover = isLover
        self.isMayor = isMayor
    }
}

struct WerewolfSetup: Equatable {
    var playerCount: Int = 8
    var counts: [WerewolfRole: Int] = [
        .villager: 2,
        .werewolf: 2,
        .seer: 1,
        .witch: 1,
        .hunter: 1,
        .cupid: 1,
        .littleGirl: 0,
        .thief: 0
    ]

    var roleCount: Int {
        counts.values.reduce(0, +)
    }

    func count(_ role: WerewolfRole) -> Int {
        counts[role, default: 0]
    }
}

enum WerewolfScreen: Equatable {
    case home
    case setup
    case names
    case reveal
    case passToGameMaster
    case game
}

enum WerewolfGamePhase: Equatable {
    case night
    case day
    case gameOver
}

enum WerewolfNightStep: Equatable {
    case villageSleeps
    case thief
    case cupid
    case loversWake
    case seer
    case wolves
    case witch
    case dawn
}

enum WerewolfWinner: Equatable {
    case village
    case wolves
    case lovers
    case draw

    var title: String {
        switch self {
        case .village: return "Victoire du Village"
        case .wolves: return "Victoire des Loups-Garous"
        case .lovers: return "Victoire des Amoureux"
        case .draw: return "Égalité"
        }
    }

    var subtitle: String {
        switch self {
        case .village: return "Tous les Loups-Garous ont été éliminés."
        case .wolves: return "Il ne reste plus aucun membre du Village en vie."
        case .lovers: return "Le couple mixte est le dernier survivant."
        case .draw: return "Plus aucun joueur n’est en vie."
        }
    }
}

enum WerewolfPendingResolution: Equatable {
    case hunter(UUID)
    case mayorSuccessor
}

enum WerewolfDeathCause: String, Equatable {
    case wolves = "Loups-Garous"
    case poison = "Potion de la Sorcière"
    case vote = "Vote du village"
    case heartbreak = "Chagrin d’amour"
    case hunter = "Tir du Chasseur"
}

struct WerewolfDeathRecord: Identifiable, Equatable {
    let id = UUID()
    let playerID: UUID
    let playerName: String
    let role: WerewolfRole
    let cause: WerewolfDeathCause
}
