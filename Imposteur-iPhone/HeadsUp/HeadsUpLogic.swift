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

/// Détecteur de mouvement indépendant de l'orientation portrait/paysage.
/// Il travaille sur l'angle de la normale de l'écran par rapport à la gravité
/// plutôt que directement sur gravity.z. Cela rend les deux directions beaucoup
/// plus symétriques, notamment lorsque la position de départ est déjà inclinée.
struct HeadsUpTiltDetector {
    private(set) var baselineAngle: Double?
    private(set) var isLocked = false
    private(set) var isCalibrated = false

    private var calibrationSamples: [Double] = []
    private var filteredAngle: Double?
    private var lastRawAngle: Double?
    private var lastTimestamp: TimeInterval?
    private var candidateAction: HeadsUpTiltAction?
    private var candidateSince: TimeInterval?
    private var neutralFrameCount = 0

    let calibrationSampleCount: Int
    let correctThreshold: Double
    let skipThreshold: Double
    let quickThreshold: Double
    let neutralThreshold: Double
    let quickVelocityThreshold: Double
    let confirmationDuration: TimeInterval

    init(
        calibrationSampleCount: Int = 12,
        correctThresholdDegrees: Double = 22,
        skipThresholdDegrees: Double = 24,
        quickThresholdDegrees: Double = 16,
        neutralThresholdDegrees: Double = 9,
        quickVelocityDegreesPerSecond: Double = 70,
        confirmationDuration: TimeInterval = 0.035
    ) {
        self.calibrationSampleCount = max(4, calibrationSampleCount)
        self.correctThreshold = correctThresholdDegrees * .pi / 180
        self.skipThreshold = skipThresholdDegrees * .pi / 180
        self.quickThreshold = quickThresholdDegrees * .pi / 180
        self.neutralThreshold = neutralThresholdDegrees * .pi / 180
        self.quickVelocityThreshold = quickVelocityDegreesPerSecond * .pi / 180
        self.confirmationDuration = confirmationDuration
    }

    mutating func reset() {
        baselineAngle = nil
        isLocked = false
        isCalibrated = false
        calibrationSamples.removeAll(keepingCapacity: true)
        filteredAngle = nil
        lastRawAngle = nil
        lastTimestamp = nil
        candidateAction = nil
        candidateSince = nil
        neutralFrameCount = 0
    }

    mutating func consume(z: Double, timestamp: TimeInterval) -> HeadsUpTiltAction? {
        let rawAngle = screenNormalAngle(z: z)

        guard isCalibrated, let baseline = baselineAngle else {
            calibrationSamples.append(rawAngle)
            if calibrationSamples.count >= calibrationSampleCount {
                let sorted = calibrationSamples.sorted()
                let middle = sorted.count / 2
                let median = sorted.count.isMultiple(of: 2)
                    ? (sorted[middle - 1] + sorted[middle]) / 2
                    : sorted[middle]
                baselineAngle = median
                filteredAngle = median
                lastRawAngle = rawAngle
                lastTimestamp = timestamp
                calibrationSamples.removeAll(keepingCapacity: true)
                isCalibrated = true
            }
            return nil
        }

        let previousFiltered = filteredAngle ?? rawAngle
        // Filtre passe-bas léger : stable sur le front mais suffisamment réactif
        // pour un mouvement volontaire bref.
        let filtered = previousFiltered * 0.64 + rawAngle * 0.36
        filteredAngle = filtered

        let dt = max(1.0 / 120.0, min(0.20, timestamp - (lastTimestamp ?? timestamp)))
        let rawVelocity = (rawAngle - (lastRawAngle ?? rawAngle)) / dt
        lastRawAngle = rawAngle
        lastTimestamp = timestamp

        let delta = filtered - baseline
        let rawDelta = rawAngle - baseline

        if isLocked {
            // Pour réarmer rapidement après une carte, on tient aussi compte de
            // l'angle brut : le filtre ne doit pas retarder artificiellement le
            // retour à la position du front. Trois trames neutres restent exigées.
            if abs(rawDelta) <= neutralThreshold * 1.25 || abs(delta) <= neutralThreshold {
                neutralFrameCount += 1
                if neutralFrameCount >= 3 {
                    isLocked = false
                    neutralFrameCount = 0
                    baselineAngle = rawAngle
                    filteredAngle = rawAngle
                    candidateAction = nil
                    candidateSince = nil
                }
            } else {
                neutralFrameCount = 0
            }
            return nil
        }

        // En zone neutre, on recale très lentement le point de repos afin de
        // compenser naturellement les petites différences de posture du joueur.
        if abs(delta) <= neutralThreshold {
            baselineAngle = baseline * 0.985 + filtered * 0.015
            candidateAction = nil
            candidateSince = nil
            return nil
        }

        let proposed: HeadsUpTiltAction?
        if delta <= -correctThreshold ||
            (rawDelta <= -quickThreshold && (rawVelocity <= -quickVelocityThreshold || delta <= -quickThreshold * 0.65)) {
            proposed = .correct
        } else if delta >= skipThreshold ||
                    (rawDelta >= quickThreshold && (rawVelocity >= quickVelocityThreshold || delta >= quickThreshold * 0.65)) {
            proposed = .skip
        } else {
            proposed = nil
        }

        guard let proposed else {
            candidateAction = nil
            candidateSince = nil
            return nil
        }

        if candidateAction != proposed {
            candidateAction = proposed
            candidateSince = timestamp
            return nil
        }

        if timestamp - (candidateSince ?? timestamp) >= confirmationDuration {
            isLocked = true
            neutralFrameCount = 0
            candidateAction = nil
            candidateSince = nil
            return proposed
        }

        return nil
    }

    private func screenNormalAngle(z: Double) -> Double {
        asin(min(1, max(-1, z)))
    }
}
