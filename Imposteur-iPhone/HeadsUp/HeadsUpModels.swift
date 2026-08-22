import Foundation

enum HeadsUpTheme: String, CaseIterable, Codable, Identifiable, Hashable {
    case celebrities
    case moviesSeries
    case animationAnime
    case videoGames
    case animals
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .celebrities: return "Célébrités"
        case .moviesSeries: return "Films & Séries"
        case .animationAnime: return "Dessins animés & Anime"
        case .videoGames: return "Jeux vidéo"
        case .animals: return "Animaux"
        case .all: return "Tous les thèmes"
        }
    }

    var subtitle: String {
        switch self {
        case .celebrities: return "Musique, sport, cinéma, culture et figures connues"
        case .moviesSeries: return "Personnages cultes du petit et du grand écran"
        case .animationAnime: return "Animation, Disney, mangas et anime"
        case .videoGames: return "Personnages de grandes licences gaming"
        case .animals: return "Animaux, insectes et quelques créatures mythiques"
        case .all: return "Mélange automatiquement les cinq bibliothèques"
        }
    }

    var systemImage: String {
        switch self {
        case .celebrities: return "star.fill"
        case .moviesSeries: return "film.fill"
        case .animationAnime: return "tv.fill"
        case .videoGames: return "gamecontroller.fill"
        case .animals: return "pawprint.fill"
        case .all: return "square.grid.2x2.fill"
        }
    }

    var isCombined: Bool { self == .all }
}

struct HeadsUpEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

enum HeadsUpScreen: Equatable {
    case themes
    case theme(HeadsUpTheme)
    case library(HeadsUpTheme)
    case ready(HeadsUpTheme)
    case playing(HeadsUpTheme)
    case result(HeadsUpTheme)
}

enum HeadsUpFeedback: Equatable {
    case neutral
    case correct
    case skipped
}

enum HeadsUpTiltAction: Equatable {
    case correct
    case skip
}
