import Foundation

struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 2862933555777941757 &+ 3037000493
        return state
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct Tests {
    static func main() {
        let themes: [HeadsUpTheme] = [.celebrities, .moviesSeries, .animationAnime, .videoGames, .animals]
        var libraries: [[String]] = []
        for theme in themes {
            let names = HeadsUpDefaults.names(for: theme)
            require(names.count == 100, "\(theme.rawValue) doit contenir 100 cartes")
            require(HeadsUpLogic.cleanedNames(names).count == 100, "doublon dans \(theme.rawValue)")
            libraries.append(names)
        }

        let combined = HeadsUpLogic.combinedNames(libraries)
        require(combined.count >= 450, "le mode Tous les thèmes doit rester riche")
        require(Set(combined.map(HeadsUpLogic.normalize)).count == combined.count, "doublon dans le mélange global")

        var rng = SeededGenerator(state: 42)
        let deck = HeadsUpLogic.shuffledDeck(from: HeadsUpDefaults.videoGames, using: &rng)
        require(deck.count == 100, "deck incomplet")
        require(Set(deck.map(HeadsUpLogic.normalize)).count == 100, "répétition dans un cycle")
        require(Set(deck) == Set(HeadsUpDefaults.videoGames), "le mélange a perdu ou ajouté des cartes")

        require(HeadsUpLogic.duration(10) == 30, "durée mini")
        require(HeadsUpLogic.duration(60) == 60, "durée normale")
        require(HeadsUpLogic.duration(999) == 180, "durée maxi")

        let clean = HeadsUpLogic.cleanedNames([" Mario ", "mario", "Éléphant", "elephant", "", "  "])
        require(clean.count == 2, "normalisation/dédoublonnage")

        var detector = HeadsUpTiltDetector(triggerThreshold: 0.52, neutralThreshold: 0.20)
        require(detector.consume(z: 0.0) == nil, "calibration")
        require(detector.consume(z: -0.30) == nil, "petit mouvement ne doit rien déclencher")
        require(detector.consume(z: -0.60) == .correct, "inclinaison haut")
        require(detector.consume(z: -0.70) == nil, "anti double-déclenchement")
        require(detector.consume(z: 0.0) == nil, "retour neutre")
        require(detector.consume(z: 0.60) == .skip, "inclinaison bas")

        print("PASS HeadsUpLogic — 5x100 cartes, mode global \(combined.count) cartes uniques, gestes OK")
    }
}
