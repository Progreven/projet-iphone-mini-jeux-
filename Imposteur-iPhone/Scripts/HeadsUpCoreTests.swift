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

        func z(_ degrees: Double) -> Double { sin(degrees * .pi / 180) }
        var detector = HeadsUpTiltDetector()
        var timestamp = 0.0
        for _ in 0..<12 {
            require(detector.consume(z: z(0), timestamp: timestamp) == nil, "calibration")
            timestamp += 0.02
        }
        require(detector.isCalibrated, "calibration terminée")

        var correctActions: [HeadsUpTiltAction] = []
        for angle in [-8.0, -16.0, -24.0, -30.0, -31.0] {
            if let action = detector.consume(z: z(angle), timestamp: timestamp) { correctActions.append(action) }
            timestamp += 0.02
        }
        require(correctActions == [.correct], "inclinaison haut")

        for angle in [-4.0, -2.0, 0.0, 0.0] {
            _ = detector.consume(z: z(angle), timestamp: timestamp)
            timestamp += 0.02
        }

        var skipActions: [HeadsUpTiltAction] = []
        for angle in [8.0, 17.0, 26.0, 31.0, 32.0] {
            if let action = detector.consume(z: z(angle), timestamp: timestamp) { skipActions.append(action) }
            timestamp += 0.02
        }
        require(skipActions == [.skip], "inclinaison bas")

        print("PASS HeadsUpLogic — 5x100 cartes, mode global \(combined.count) cartes uniques, gestes OK")
    }
}
