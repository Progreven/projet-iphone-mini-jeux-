import SwiftUI

@MainActor
final class WerewolfStore: ObservableObject {
    @Published var screen: WerewolfScreen = .home
    @Published var setup = WerewolfSetup()
    @Published var names: [String] = []
    @Published var players: [WerewolfPlayer] = []
    @Published var revealIndex = 0
    @Published var revealVisible = false

    @Published var phase: WerewolfGamePhase = .night
    @Published var nightNumber = 1
    @Published var dayNumber = 0
    @Published var nightStep: WerewolfNightStep = .villageSleeps
    @Published var selectedIDs: Set<UUID> = []
    @Published var thiefSelectionOrder: [UUID] = []
    @Published var thiefRevealIndex: Int?
    @Published var seerRevealedPlayerID: UUID?
    @Published var pendingWolfTargetID: UUID?
    @Published var littleGirlCaughtThisNight = false
    @Published var witchIntroSeen = false
    @Published var witchWillSave = false
    @Published var witchPoisonTargetID: UUID?
    @Published var healingPotionAvailable = true
    @Published var poisonPotionAvailable = true
    @Published var pendingResolution: WerewolfPendingResolution?
    @Published var lastDeaths: [WerewolfDeathRecord] = []
    @Published var lastEventText: String?
    @Published var winner: WerewolfWinner?
    @Published var message: String?
    @Published var initialMayorElectionCompleted = false
    @Published var dayVoteCompleted = false
    @Published var deathAnnouncements: [WerewolfDeathRecord] = []
    @Published var deathAnnouncementIndex: Int?

    private var pendingHunterShooters: [UUID] = []
    private var mayorNeedsSuccessor = false
    private var deathAnnouncementSummaryPrefix: String?
    private let savedNamesKey = "jeuxsoiree.werewolf.lastNames.v1"

    var setupError: String? { WerewolfLogic.setupError(setup) }
    var allNamesFilled: Bool {
        names.count == setup.playerCount && names.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    var currentRevealPlayer: WerewolfPlayer? {
        players.indices.contains(revealIndex) ? players[revealIndex] : nil
    }
    var alivePlayers: [WerewolfPlayer] { players.filter(\.alive) }
    var hasLovers: Bool { players.filter(\.isLover).count == 2 }
    var currentThief: WerewolfPlayer? { players.first { $0.alive && $0.role == .thief } }
    var thiefRevealPlayer: WerewolfPlayer? {
        guard let index = thiefRevealIndex, thiefSelectionOrder.indices.contains(index) else { return nil }
        let id = thiefSelectionOrder[index]
        return players.first { $0.id == id }
    }
    var currentDeathAnnouncement: WerewolfDeathRecord? {
        guard let index = deathAnnouncementIndex, deathAnnouncements.indices.contains(index) else { return nil }
        return deathAnnouncements[index]
    }
    var deathAnnouncementsActive: Bool { currentDeathAnnouncement != nil }
    var needsInitialMayorElection: Bool {
        phase == .day && dayNumber == 1 && !initialMayorElectionCompleted && winner == nil && !deathAnnouncementsActive
    }
    var canUseDayVote: Bool {
        phase == .day && winner == nil && pendingResolution == nil && !dayVoteCompleted && !needsInitialMayorElection && !deathAnnouncementsActive
    }
    var wolfTarget: WerewolfPlayer? {
        guard let id = pendingWolfTargetID else { return nil }
        return players.first { $0.id == id }
    }
    var seerRevealedPlayer: WerewolfPlayer? {
        guard let id = seerRevealedPlayerID else { return nil }
        return players.first { $0.id == id }
    }
    var pendingHunter: WerewolfPlayer? {
        guard case .hunter(let id) = pendingResolution else { return nil }
        return players.first { $0.id == id }
    }
    var mayor: WerewolfPlayer? { players.first { $0.alive && $0.isMayor } }

    func openSetup() {
        screen = .setup
    }

    func returnHome() {
        screen = .home
        winner = nil
        pendingResolution = nil
        selectedIDs.removeAll()
        deathAnnouncements = []
        deathAnnouncementIndex = nil
        deathAnnouncementSummaryPrefix = nil
    }

    func updatePlayerCount(_ delta: Int) {
        setup.playerCount = min(30, max(4, setup.playerCount + delta))
    }

    func updateRole(_ role: WerewolfRole, delta: Int) {
        let old = setup.count(role)
        if role.repeatable {
            setup.counts[role] = min(setup.playerCount, max(0, old + delta))
        } else {
            setup.counts[role] = min(1, max(0, old + delta))
        }
    }

    func toggleSpecialRole(_ role: WerewolfRole) {
        guard !role.repeatable else { return }
        setup.counts[role] = setup.count(role) == 0 ? 1 : 0
    }

    func prepareNames() {
        guard setupError == nil else { return }
        let saved = UserDefaults.standard.stringArray(forKey: savedNamesKey) ?? []
        names = (0..<setup.playerCount).map { index in
            index < saved.count ? saved[index] : ""
        }
        screen = .names
    }

    func assignRoles() {
        guard setupError == nil, allNamesFilled else { return }
        let cleanNames = names.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24)) }
        UserDefaults.standard.set(cleanNames, forKey: savedNamesKey)
        players = WerewolfLogic.assignPlayers(names: cleanNames, setup: setup)
        revealIndex = 0
        revealVisible = false
        screen = .reveal
    }

    func showRevealCard() {
        revealVisible = true
    }

    func hideRevealAndAdvance() {
        revealVisible = false
        if revealIndex + 1 < players.count {
            revealIndex += 1
        } else {
            screen = .passToGameMaster
        }
    }

    func beginGameMasterMode() {
        players = players.map {
            var player = $0
            player.alive = true
            player.isLover = false
            player.isMayor = false
            return player
        }
        phase = .night
        nightNumber = 1
        dayNumber = 0
        healingPotionAvailable = true
        poisonPotionAvailable = true
        pendingWolfTargetID = nil
        littleGirlCaughtThisNight = false
        witchWillSave = false
        witchPoisonTargetID = nil
        pendingResolution = nil
        pendingHunterShooters = []
        mayorNeedsSuccessor = false
        thiefSelectionOrder = []
        thiefRevealIndex = nil
        initialMayorElectionCompleted = false
        dayVoteCompleted = false
        lastDeaths = []
        lastEventText = nil
        deathAnnouncements = []
        deathAnnouncementIndex = nil
        deathAnnouncementSummaryPrefix = nil
        winner = nil
        screen = .game
        moveToNightStep(.villageSleeps)
    }

    func moveToNightStep(_ step: WerewolfNightStep) {
        nightStep = step
        selectedIDs.removeAll()
        seerRevealedPlayerID = nil
        thiefSelectionOrder = []
        thiefRevealIndex = nil
        if step == .wolves {
            littleGirlCaughtThisNight = false
        }
        if step == .witch {
            witchIntroSeen = false
            witchWillSave = false
            witchPoisonTargetID = nil
        }
    }

    private func advanceNightStep() {
        let next = WerewolfLogic.nextNightStep(
            after: nightStep,
            nightNumber: nightNumber,
            players: players,
            hasLovers: hasLovers
        )
        moveToNightStep(next)
    }

    func continueFromVillageSleeps() {
        advanceNightStep()
    }

    func skipCurrentNightAction() {
        switch nightStep {
        case .thief:
            guard thiefRevealIndex == nil else { return }
            thiefSelectionOrder = []
            advanceNightStep()
        case .cupid, .seer:
            advanceNightStep()
        case .wolves:
            pendingWolfTargetID = nil
            littleGirlCaughtThisNight = false
            advanceNightStep()
        case .witch:
            witchWillSave = false
            witchPoisonTargetID = nil
            advanceNightStep()
        case .villageSleeps, .loversWake, .dawn:
            break
        }
    }

    func toggleSelection(_ id: UUID, maximum: Int) {
        guard players.contains(where: { $0.id == id && $0.alive }) else { return }
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else if selectedIDs.count < maximum {
            selectedIDs.insert(id)
        }
    }

    func toggleThiefSelection(_ id: UUID) {
        guard nightStep == .thief, thiefRevealIndex == nil,
              players.contains(where: { $0.id == id && $0.alive }) else { return }
        if let existing = thiefSelectionOrder.firstIndex(of: id) {
            thiefSelectionOrder.remove(at: existing)
        } else if thiefSelectionOrder.count < 2 {
            thiefSelectionOrder.append(id)
        }
    }

    func confirmThiefSwap() {
        guard nightStep == .thief, thiefRevealIndex == nil, thiefSelectionOrder.count == 2,
              let firstIndex = players.firstIndex(where: { $0.id == thiefSelectionOrder[0] }),
              let secondIndex = players.firstIndex(where: { $0.id == thiefSelectionOrder[1] }) else {
            message = "Le Voleur doit choisir exactement deux joueurs."
            return
        }

        let firstRole = players[firstIndex].role
        players[firstIndex].role = players[secondIndex].role
        players[secondIndex].role = firstRole
        selectedIDs.removeAll()
        thiefRevealIndex = 0
    }

    func continueAfterThiefReveal() {
        guard nightStep == .thief, let index = thiefRevealIndex else { return }
        if index + 1 < thiefSelectionOrder.count {
            thiefRevealIndex = index + 1
        } else {
            thiefRevealIndex = nil
            thiefSelectionOrder = []
            advanceNightStep()
        }
    }

    func confirmCupid() {
        guard nightStep == .cupid, selectedIDs.count == 2 else {
            message = "Cupidon doit choisir exactement deux personnes."
            return
        }
        for index in players.indices {
            players[index].isLover = selectedIDs.contains(players[index].id)
        }
        advanceNightStep()
    }

    func continueAfterLoversWake() {
        advanceNightStep()
    }

    func confirmSeerSelection() {
        guard nightStep == .seer, selectedIDs.count == 1, let id = selectedIDs.first else {
            message = "Choisis une personne à révéler."
            return
        }
        seerRevealedPlayerID = id
    }

    func continueAfterSeerReveal() {
        advanceNightStep()
    }

    func toggleLittleGirlCaught() {
        guard players.contains(where: { $0.alive && $0.role == .littleGirl }) else { return }
        littleGirlCaughtThisNight.toggle()
    }

    func confirmWolfTarget() {
        guard nightStep == .wolves, selectedIDs.count == 1, let id = selectedIDs.first else {
            message = "Choisis une victime pour les Loups-Garous."
            return
        }
        // Règle maison : les Loups-Garous peuvent viser absolument n'importe quel joueur vivant,
        // y compris un autre Loup-Garou. Si la Petite Fille est repérée pendant qu'elle espionne,
        // elle remplace la victime choisie conformément à la règle classique.
        if littleGirlCaughtThisNight, let girl = players.first(where: { $0.alive && $0.role == .littleGirl }) {
            pendingWolfTargetID = girl.id
        } else {
            pendingWolfTargetID = id
        }
        advanceNightStep()
    }

    func showWitchChoices() {
        witchIntroSeen = true
        selectedIDs.removeAll()
    }

    func chooseWitchAction(_ id: UUID) {
        guard nightStep == .witch, witchIntroSeen,
              players.contains(where: { $0.id == id && $0.alive }) else { return }

        // Une seule potion peut être utilisée par nuit :
        // - toucher la victime des Loups = choisir/annuler la potion de vie ;
        // - toucher toute autre personne = choisir/annuler la potion de mort.
        // Choisir une potion annule automatiquement l'autre choix de cette nuit.
        if id == pendingWolfTargetID {
            guard healingPotionAvailable else { return }
            if witchWillSave {
                witchWillSave = false
            } else {
                witchWillSave = true
                witchPoisonTargetID = nil
            }
        } else {
            guard poisonPotionAvailable else { return }
            if witchPoisonTargetID == id {
                witchPoisonTargetID = nil
            } else {
                witchPoisonTargetID = id
                witchWillSave = false
            }
        }
    }

    func confirmWitch() {
        guard nightStep == .witch else { return }
        // Défense supplémentaire : même si l'état UI devenait incohérent,
        // une seule potion peut être consommée pendant cette nuit.
        if witchWillSave && healingPotionAvailable && pendingWolfTargetID != nil {
            healingPotionAvailable = false
            witchPoisonTargetID = nil
        } else if witchPoisonTargetID != nil && poisonPotionAvailable {
            poisonPotionAvailable = false
            witchWillSave = false
        }
        advanceNightStep()
    }

    func wakeVillage() {
        guard nightStep == .dawn else { return }
        var deaths: [(UUID, WerewolfDeathCause)] = []
        if let wolfID = pendingWolfTargetID, !witchWillSave {
            deaths.append((wolfID, .wolves))
        }
        if let poisonID = witchPoisonTargetID {
            deaths.append((poisonID, .poison))
        }

        pendingWolfTargetID = nil
        littleGirlCaughtThisNight = false
        witchWillSave = false
        witchPoisonTargetID = nil
        dayNumber += 1
        phase = .day
        dayVoteCompleted = false
        lastDeaths = []
        enqueueDeaths(deaths)

        if lastDeaths.isEmpty {
            lastEventText = "Personne n’est mort cette nuit."
            advancePendingResolution()
        } else {
            beginDeathAnnouncements(prefix: "Cette nuit")
        }
    }

    func appointMayor(_ id: UUID) {
        guard phase == .day,
              players.contains(where: { $0.id == id && $0.alive }) else { return }

        let isSuccessorChoice = pendingResolution == .mayorSuccessor
        let isInitialElection = dayNumber == 1 && !initialMayorElectionCompleted && pendingResolution == nil
        guard isSuccessorChoice || isInitialElection else { return }

        for index in players.indices {
            players[index].isMayor = players[index].id == id
        }
        mayorNeedsSuccessor = false

        if isInitialElection {
            initialMayorElectionCompleted = true
            lastEventText = "Premier jour : le Maire a été élu. Le village peut maintenant débattre puis voter."
        }

        if isSuccessorChoice {
            pendingResolution = nil
            advancePendingResolution()
        }
    }

    func eliminateByVote(_ id: UUID) {
        guard canUseDayVote,
              players.contains(where: { $0.id == id && $0.alive }) else { return }
        dayVoteCompleted = true
        lastDeaths = []
        enqueueDeaths([(id, .vote)])
        beginDeathAnnouncements(prefix: "Vote du village")
    }

    func resolveHunterShot(targetID: UUID) {
        guard case .hunter(let shooterID) = pendingResolution,
              pendingHunterShooters.first == shooterID,
              players.contains(where: { $0.id == targetID && $0.alive }) else { return }
        pendingResolution = nil
        if !pendingHunterShooters.isEmpty { pendingHunterShooters.removeFirst() }
        lastDeaths = []
        enqueueDeaths([(targetID, .hunter)])
        beginDeathAnnouncements(prefix: "Dernières éliminations")
    }

    private func beginDeathAnnouncements(prefix: String) {
        deathAnnouncements = lastDeaths
        deathAnnouncementIndex = deathAnnouncements.isEmpty ? nil : 0
        deathAnnouncementSummaryPrefix = prefix
        lastEventText = nil
        if deathAnnouncements.isEmpty {
            advancePendingResolution()
        }
    }

    func continueDeathAnnouncement() {
        guard let index = deathAnnouncementIndex else { return }
        if index + 1 < deathAnnouncements.count {
            deathAnnouncementIndex = index + 1
            return
        }

        let prefix = deathAnnouncementSummaryPrefix ?? "Éliminations"
        deathAnnouncementIndex = nil
        deathAnnouncements = []
        deathAnnouncementSummaryPrefix = nil
        lastEventText = deathSummary(prefix: prefix)
        advancePendingResolution()
    }

    private func beginNextNightAfterDay() {
        guard phase == .day, pendingResolution == nil, winner == nil, dayVoteCompleted else { return }
        nightNumber += 1
        phase = .night
        lastDeaths = []
        lastEventText = nil
        deathAnnouncements = []
        deathAnnouncementIndex = nil
        deathAnnouncementSummaryPrefix = nil
        moveToNightStep(.villageSleeps)
    }

    func restartFromSetup() {
        screen = .setup
        winner = nil
        players = []
        names = []
        selectedIDs.removeAll()
    }

    private func enqueueDeaths(_ initial: [(UUID, WerewolfDeathCause)]) {
        var queue = initial
        var queuedIDs = Set(initial.map(\.0))

        while !queue.isEmpty {
            let (id, cause) = queue.removeFirst()
            guard let index = players.firstIndex(where: { $0.id == id }), players[index].alive else { continue }

            let dyingPlayer = players[index]
            players[index].alive = false
            let wasMayor = players[index].isMayor
            players[index].isMayor = false

            lastDeaths.append(WerewolfDeathRecord(
                playerID: dyingPlayer.id,
                playerName: dyingPlayer.name,
                role: dyingPlayer.role,
                cause: cause
            ))

            if dyingPlayer.role == .hunter {
                pendingHunterShooters.append(dyingPlayer.id)
            }
            if wasMayor {
                mayorNeedsSuccessor = true
            }

            if dyingPlayer.isLover,
               let partner = WerewolfLogic.loverPartner(of: dyingPlayer.id, players: players),
               partner.alive,
               !queuedIDs.contains(partner.id) {
                queue.append((partner.id, .heartbreak))
                queuedIDs.insert(partner.id)
            }
        }
    }

    private func advancePendingResolution() {
        while let shooterID = pendingHunterShooters.first {
            let candidates = players.filter { $0.alive && $0.id != shooterID }
            if candidates.isEmpty {
                pendingHunterShooters.removeFirst()
                continue
            }
            pendingResolution = .hunter(shooterID)
            return
        }

        if let detectedWinner = WerewolfLogic.winner(players: players) {
            winner = detectedWinner
            phase = .gameOver
            pendingResolution = nil
            return
        }

        if mayorNeedsSuccessor && !alivePlayers.isEmpty {
            pendingResolution = .mayorSuccessor
            return
        }

        mayorNeedsSuccessor = false
        pendingResolution = nil

        if phase == .day && dayVoteCompleted {
            beginNextNightAfterDay()
        }
    }

    private func deathSummary(prefix: String) -> String {
        let unique = Array(Dictionary(grouping: lastDeaths, by: \.playerID).values.compactMap { $0.first })
        guard !unique.isEmpty else { return "\(prefix) : aucune élimination." }
        let names = unique.map(\.playerName).joined(separator: ", ")
        return "\(prefix) : \(names)."
    }
}
