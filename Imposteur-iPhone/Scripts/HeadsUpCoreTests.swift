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

        // 1) Une inclinaison vers le haut produit exactement une bonne réponse.
        var correctActions: [HeadsUpTiltAction] = []
        for angle in [-8.0, -16.0, -24.0, -30.0, -31.0] {
            if let action = detector.consume(z: z(angle), timestamp: timestamp) { correctActions.append(action) }
            timestamp += 0.02
        }
        require(correctActions == [.correct], "inclinaison haut")

        // 2) Le retour/overshoot dans la direction opposée pendant le cooldown
        // ne doit JAMAIS être interprété comme un skip.
        var actionsDuringCooldown: [HeadsUpTiltAction] = []
        for i in 0..<40 { // 0,8 seconde
            let angle: Double = i < 8 ? 34.0 : (i < 20 ? 8.0 : 0.0)
            if let action = detector.consume(z: z(angle), timestamp: timestamp) {
                actionsDuringCooldown.append(action)
            }
            timestamp += 0.02
        }
        require(actionsDuringCooldown.isEmpty, "aucune action opposée pendant le cooldown")
        require(detector.isLocked, "le détecteur reste verrouillé avant 1 seconde")

        // 3) On reste neutre jusqu'à la fin de la seconde : le détecteur se réarme.
        for _ in 0..<20 { // +0,4 seconde, donc >1 seconde au total
            require(detector.consume(z: z(0), timestamp: timestamp) == nil, "retour neutre")
            timestamp += 0.02
        }
        require(!detector.isLocked, "réarmement après cooldown + retour neutre")

        // 4) Une nouvelle inclinaison vers le bas fonctionne ensuite normalement.
        var skipActions: [HeadsUpTiltAction] = []
        for angle in [8.0, 17.0, 26.0, 31.0, 32.0] {
            if let action = detector.consume(z: z(angle), timestamp: timestamp) { skipActions.append(action) }
            timestamp += 0.02
        }
        require(skipActions == [.skip], "inclinaison bas après cooldown")

        print("PASS HeadsUpLogic — 5x100 cartes, mode global \(combined.count) cartes uniques, gestes OK")
    }
}
