import Foundation
import Combine

@MainActor
final class HeadsUpStore: ObservableObject {
    private enum StorageKey {
        static let libraryPrefix = "jeuxsoiree.headsup.library.v1."
        static let durationPrefix = "jeuxsoiree.headsup.duration.v1."
    }

    @Published var screen: HeadsUpScreen = .themes
    @Published private(set) var libraries: [HeadsUpTheme: [HeadsUpEntry]] = [:]
    @Published private(set) var durations: [HeadsUpTheme: Int] = [:]

    @Published private(set) var deck: [String] = []
    @Published private(set) var cardIndex = 0
    @Published private(set) var score = 0
    @Published private(set) var skipped = 0
    @Published private(set) var timeRemaining = 0
    @Published private(set) var feedback: HeadsUpFeedback = .neutral
    @Published var message: String?

    private let defaults: UserDefaults
    private var timerTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var roundEndDate: Date?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadLibraries()
        loadDurations()
    }

    deinit {
        timerTask?.cancel()
        feedbackTask?.cancel()
    }

    var currentTheme: HeadsUpTheme? {
        switch screen {
        case .theme(let theme), .library(let theme), .ready(let theme), .playing(let theme), .result(let theme):
            return theme
        case .themes:
            return nil
        }
    }

    var currentCard: String {
        guard deck.indices.contains(cardIndex) else { return "" }
        return deck[cardIndex]
    }

    func showThemes() {
        stopRound()
        screen = .themes
    }

    func openTheme(_ theme: HeadsUpTheme) {
        stopRound()
        screen = .theme(theme)
    }

    func openLibrary(_ theme: HeadsUpTheme) {
        screen = .library(theme)
    }

    func closeLibrary(_ theme: HeadsUpTheme) {
        screen = .theme(theme)
    }

    func prepareRound(_ theme: HeadsUpTheme) {
        guard !names(for: theme).isEmpty else {
            message = "La bibliothèque de ce thème est vide."
            return
        }
        stopRound()
        screen = .ready(theme)
    }

    func cancelReady(_ theme: HeadsUpTheme) {
        screen = .theme(theme)
    }

    func beginRound(_ theme: HeadsUpTheme) {
        var rng = SystemRandomNumberGenerator()
        let names = names(for: theme)
        let nextDeck = HeadsUpLogic.shuffledDeck(from: names, using: &rng)
        guard !nextDeck.isEmpty else {
            message = "La bibliothèque de ce thème est vide."
            screen = .theme(theme)
            return
        }

        stopRound()
        deck = nextDeck
        cardIndex = 0
        score = 0
        skipped = 0
        timeRemaining = duration(for: theme)
        roundEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        feedback = .neutral
        screen = .playing(theme)
        startTimer(for: theme)
    }

    func handleTilt(_ action: HeadsUpTiltAction) {
        guard case .playing = screen, timeRemaining > 0, feedback == .neutral else { return }

        switch action {
        case .correct:
            score += 1
            feedback = .correct
        case .skip:
            skipped += 1
            feedback = .skipped
        }

        feedbackTask?.cancel()
        feedbackTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 320_000_000)
            guard !Task.isCancelled, let self else { return }
            self.advanceAfterFeedback()
        }
    }

    func finishRound(_ theme: HeadsUpTheme) {
        timerTask?.cancel()
        timerTask = nil
        feedbackTask?.cancel()
        feedbackTask = nil
        roundEndDate = nil
        feedback = .neutral
        if case .playing = screen {
            screen = .result(theme)
        }
    }

    func replay(_ theme: HeadsUpTheme) {
        prepareRound(theme)
    }

    func setDuration(_ value: Int, for theme: HeadsUpTheme) {
        let clamped = HeadsUpLogic.duration(value)
        durations[theme] = clamped
        defaults.set(clamped, forKey: StorageKey.durationPrefix + theme.rawValue)
    }

    func duration(for theme: HeadsUpTheme) -> Int {
        durations[theme] ?? 60
    }

    func names(for theme: HeadsUpTheme) -> [String] {
        if theme == .all {
            return HeadsUpLogic.combinedNames(
                HeadsUpTheme.allCases
                    .filter { !$0.isCombined }
                    .map { libraries[$0, default: []].map(\.name) }
            )
        }
        return libraries[theme, default: []].map(\.name)
    }

    func entries(for theme: HeadsUpTheme) -> [HeadsUpEntry] {
        if theme == .all {
            return names(for: .all).map { HeadsUpEntry(name: $0) }
        }
        return libraries[theme, default: []]
    }

    @discardableResult
    func addEntry(_ text: String, to theme: HeadsUpTheme) -> Bool {
        guard !theme.isCombined else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = HeadsUpLogic.normalize(trimmed)
        guard !key.isEmpty else {
            message = "Le nom ne peut pas être vide."
            return false
        }
        guard !libraries[theme, default: []].contains(where: { HeadsUpLogic.normalize($0.name) == key }) else {
            message = "Cet élément existe déjà dans ce thème."
            return false
        }
        libraries[theme, default: []].append(HeadsUpEntry(name: trimmed))
        saveLibrary(theme)
        return true
    }

    @discardableResult
    func updateEntry(id: UUID, text: String, in theme: HeadsUpTheme) -> Bool {
        guard !theme.isCombined,
              let index = libraries[theme, default: []].firstIndex(where: { $0.id == id }) else { return false }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = HeadsUpLogic.normalize(trimmed)
        guard !key.isEmpty else {
            message = "Le nom ne peut pas être vide."
            return false
        }
        guard !libraries[theme, default: []].enumerated().contains(where: {
            $0.offset != index && HeadsUpLogic.normalize($0.element.name) == key
        }) else {
            message = "Cet élément existe déjà dans ce thème."
            return false
        }

        libraries[theme]?[index].name = trimmed
        saveLibrary(theme)
        return true
    }

    func deleteEntry(id: UUID, from theme: HeadsUpTheme) {
        guard !theme.isCombined else { return }
        libraries[theme]?.removeAll { $0.id == id }
        saveLibrary(theme)
    }

    func resetLibrary(_ theme: HeadsUpTheme) {
        guard !theme.isCombined else { return }
        libraries[theme] = HeadsUpDefaults.names(for: theme).map { HeadsUpEntry(name: $0) }
        saveLibrary(theme)
    }

    @discardableResult
    func replaceLibrary(_ names: [String], for theme: HeadsUpTheme) -> Bool {
        guard !theme.isCombined else { return false }
        let clean = HeadsUpLogic.cleanedNames(names)
        guard !clean.isEmpty else {
            message = "Le fichier JSON ne contient aucun élément valide."
            return false
        }
        libraries[theme] = clean.map { HeadsUpEntry(name: $0) }
        saveLibrary(theme)
        return true
    }

    private func advanceAfterFeedback() {
        guard case .playing(let theme) = screen, timeRemaining > 0 else { return }
        feedback = .neutral

        if cardIndex + 1 < deck.count {
            cardIndex += 1
            return
        }

        // Une carte ne se répète pas avant épuisement de la bibliothèque.
        // Si le chrono est très long, on redémarre ensuite un nouveau cycle mélangé.
        let previous = deck.last
        var rng = SystemRandomNumberGenerator()
        var next = HeadsUpLogic.shuffledDeck(from: names(for: theme), using: &rng)
        if next.count > 1, next.first == previous {
            next.swapAt(0, 1)
        }
        deck = next
        cardIndex = 0
    }

    private func startTimer(for theme: HeadsUpTheme) {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled, let self else { return }
                guard case .playing = self.screen, let endDate = self.roundEndDate else { return }

                let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
                if remaining != self.timeRemaining {
                    self.timeRemaining = remaining
                }
                if remaining == 0 {
                    self.finishRound(theme)
                    return
                }
            }
        }
    }

    private func stopRound() {
        timerTask?.cancel()
        timerTask = nil
        feedbackTask?.cancel()
        feedbackTask = nil
        roundEndDate = nil
        feedback = .neutral
    }

    private func loadLibraries() {
        for theme in HeadsUpTheme.allCases where !theme.isCombined {
            let key = StorageKey.libraryPrefix + theme.rawValue
            if let data = defaults.data(forKey: key),
               let decoded = try? JSONDecoder().decode([HeadsUpEntry].self, from: data),
               !decoded.isEmpty {
                libraries[theme] = decoded
            } else {
                libraries[theme] = HeadsUpDefaults.names(for: theme).map { HeadsUpEntry(name: $0) }
            }
        }
    }

    private func loadDurations() {
        for theme in HeadsUpTheme.allCases {
            let key = StorageKey.durationPrefix + theme.rawValue
            let value = defaults.integer(forKey: key)
            durations[theme] = value == 0 ? 60 : HeadsUpLogic.duration(value)
        }
    }

    private func saveLibrary(_ theme: HeadsUpTheme) {
        guard !theme.isCombined,
              let entries = libraries[theme],
              let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: StorageKey.libraryPrefix + theme.rawValue)
    }
}
