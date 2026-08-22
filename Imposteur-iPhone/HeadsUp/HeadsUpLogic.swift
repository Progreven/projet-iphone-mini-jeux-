import Foundation

enum HeadsUpLogic {
    static func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased(with: Locale(identifier: "fr_FR"))
    }

    static func cleanedNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        result.reserveCapacity(names.count)

        for raw in names {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalize(trimmed)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(trimmed)
        }
        return result
    }

    static func combinedNames(_ libraries: [[String]]) -> [String] {
        cleanedNames(libraries.flatMap { $0 })
    }

    static func shuffledDeck<R: RandomNumberGenerator>(from names: [String], using rng: inout R) -> [String] {
        cleanedNames(names).shuffled(using: &rng)
    }

    static func duration(_ value: Int) -> Int {
        min(180, max(30, value))
    }
}

struct HeadsUpTiltDetector {
    private(set) var baselineZ: Double?
    private(set) var isLocked = false

    let triggerThreshold: Double
    let neutralThreshold: Double

    init(triggerThreshold: Double = 0.52, neutralThreshold: Double = 0.20) {
        self.triggerThreshold = triggerThreshold
        self.neutralThreshold = neutralThreshold
    }

    mutating func reset() {
        baselineZ = nil
        isLocked = false
    }

    mutating func consume(z: Double) -> HeadsUpTiltAction? {
        guard let baseline = baselineZ else {
            baselineZ = z
            return nil
        }

        let delta = z - baseline

        if isLocked {
            if abs(delta) <= neutralThreshold {
                isLocked = false
                baselineZ = z
            }
            return nil
        }

        if delta <= -triggerThreshold {
            isLocked = true
            return .correct
        }

        if delta >= triggerThreshold {
            isLocked = true
            return .skip
        }

        if abs(delta) <= neutralThreshold {
            baselineZ = baseline * 0.92 + z * 0.08
        }
        return nil
    }
}
