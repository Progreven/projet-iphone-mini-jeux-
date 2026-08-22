import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("❌ \(message)\n", stderr)
        exit(1)
    }
}

func player(_ name: String, _ role: WerewolfRole, lover: Bool = false, mayor: Bool = false, alive: Bool = true) -> WerewolfPlayer {
    WerewolfPlayer(name: name, role: role, alive: alive, isLover: lover, isMayor: mayor)
}

// --- Setup / assignment ---
var setup = WerewolfSetup()
expect(WerewolfLogic.setupError(setup) == nil, "Default setup should be valid")
setup.playerCount = 9
expect(WerewolfLogic.setupError(setup) != nil, "Mismatched roles/player count should fail")
setup.playerCount = 8
setup.counts[.werewolf] = 0
setup.counts[.villager] = 4
expect(WerewolfLogic.setupError(setup) != nil, "A game without wolves should fail")
setup = WerewolfSetup()
setup.counts[.seer] = 2
setup.counts[.villager] = 1
expect(WerewolfLogic.setupError(setup) != nil, "Duplicate special role should fail")

let names = (1...8).map { "J\($0)" }
let assigned = WerewolfLogic.assignPlayers(names: names, setup: WerewolfSetup())
expect(assigned.count == 8, "Assignment count")
expect(Set(assigned.map(\.name)) == Set(names), "All names preserved")
let assignedCounts = Dictionary(grouping: assigned, by: \.role).mapValues(\.count)
for role in WerewolfRole.allCases {
    expect(assignedCounts[role, default: 0] == WerewolfSetup().count(role), "Role count preserved for \(role)")
}

// --- Night order ---
let allRoles = [
    player("T", .thief), player("C", .cupid), player("S", .seer), player("W", .witch),
    player("L", .werewolf), player("F", .littleGirl), player("V", .villager)
]
expect(WerewolfLogic.nextNightStep(after: .villageSleeps, nightNumber: 1, players: allRoles, hasLovers: false) == .thief, "Thief first on night 1")
expect(WerewolfLogic.nextNightStep(after: .thief, nightNumber: 1, players: allRoles, hasLovers: false) == .cupid, "Cupid after thief")
expect(WerewolfLogic.nextNightStep(after: .cupid, nightNumber: 1, players: allRoles, hasLovers: true) == .loversWake, "Lovers after Cupid")
expect(WerewolfLogic.nextNightStep(after: .loversWake, nightNumber: 1, players: allRoles, hasLovers: true) == .seer, "Seer after lovers")
expect(WerewolfLogic.nextNightStep(after: .seer, nightNumber: 1, players: allRoles, hasLovers: true) == .wolves, "Wolves after seer")
expect(WerewolfLogic.nextNightStep(after: .wolves, nightNumber: 1, players: allRoles, hasLovers: true) == .witch, "Witch after wolves")
expect(WerewolfLogic.nextNightStep(after: .villageSleeps, nightNumber: 2, players: allRoles, hasLovers: true) == .seer, "Night 2 skips thief/cupid")

var deadSeer = allRoles
if let i = deadSeer.firstIndex(where: { $0.role == .seer }) { deadSeer[i].alive = false }
expect(WerewolfLogic.nextNightStep(after: .loversWake, nightNumber: 1, players: deadSeer, hasLovers: true) == .wolves, "Dead seer skipped")

// --- Winner cases ---
expect(WerewolfLogic.winner(players: [player("A", .villager), player("B", .seer)]) == .village, "Village wins without wolves")
expect(WerewolfLogic.winner(players: [player("A", .werewolf), player("B", .werewolf)]) == .wolves, "Wolves win without village")
expect(WerewolfLogic.winner(players: [player("A", .werewolf, lover: true), player("B", .villager, lover: true)]) == .lovers, "Mixed lovers win as final pair")
expect(WerewolfLogic.winner(players: [player("A", .werewolf, lover: true), player("B", .villager, lover: true), player("C", .villager)]) == nil, "Mixed lovers do not win with third survivor")
expect(WerewolfLogic.winner(players: [player("A", .villager, alive: false)]) == .draw, "No survivor = draw")

// --- Store: thief -> cupid -> seer -> wolves -> witch ---
do {
    let store = WerewolfStore()
    store.players = [
        player("Theo", .thief), player("Claire", .cupid), player("Vera", .seer), player("Wolf", .werewolf),
        player("Witch", .witch), player("Hunter", .hunter), player("Girl", .littleGirl), player("Vic", .villager)
    ]
    store.screen = .game
    store.phase = .night
    store.nightNumber = 1
    store.moveToNightStep(.thief)
    let thiefID = store.players[0].id
    let cupidID = store.players[1].id
    store.selectedIDs = [thiefID, cupidID]
    store.confirmThiefSwap()
    expect(store.players[0].role == .cupid && store.players[1].role == .thief, "House thief swap applies roles")
    expect(store.nightStep == .cupid, "Cupid step still happens after swapped roles")

    store.selectedIDs = [store.players[0].id, store.players[7].id]
    store.confirmCupid()
    expect(store.hasLovers, "Cupid stores two lovers")
    expect(store.nightStep == .loversWake, "Lovers wake")
    store.continueAfterLoversWake()
    expect(store.nightStep == .seer, "Seer follows")

    let wolfID = store.players.first(where: { $0.role == .werewolf })!.id
    store.selectedIDs = [wolfID]
    store.confirmSeerSelection()
    expect(store.seerRevealedPlayer?.role == .werewolf, "Seer reveals real role")
    store.continueAfterSeerReveal()
    expect(store.nightStep == .wolves, "Wolves follow seer")

    // House rule: wolves can target a wolf.
    store.selectedIDs = [wolfID]
    store.confirmWolfTarget()
    expect(store.pendingWolfTargetID == wolfID, "Wolf may target wolf")
    expect(store.nightStep == .witch, "Witch follows wolves")
}

// --- Witch saves wolf victim and poisons someone else ---
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("Witch", .witch), player("A", .villager), player("B", .villager)]
    store.screen = .game
    store.phase = .night
    store.nightNumber = 1
    store.moveToNightStep(.wolves)
    let victim = store.players[2].id
    let poison = store.players[3].id
    store.selectedIDs = [victim]
    store.confirmWolfTarget()
    store.showWitchChoices()
    store.toggleWitchSave()
    store.chooseWitchPoisonTarget(poison)
    store.confirmWitch()
    expect(!store.healingPotionAvailable && !store.poisonPotionAvailable, "Both potions consumed")
    expect(store.nightStep == .dawn, "Witch ends at dawn")
    store.wakeVillage()
    expect(store.players.first(where: { $0.id == victim })!.alive, "Saved victim survives")
    expect(!store.players.first(where: { $0.id == poison })!.alive, "Poison target dies")
}

// --- Duplicate night kill target is only killed once ---
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("Witch", .witch), player("A", .villager), player("B", .villager)]
    store.screen = .game; store.phase = .night; store.moveToNightStep(.wolves)
    let target = store.players[2].id
    store.selectedIDs = [target]; store.confirmWolfTarget(); store.showWitchChoices(); store.chooseWitchPoisonTarget(target); store.confirmWitch(); store.wakeVillage()
    expect(store.lastDeaths.filter { $0.playerID == target }.count == 1, "Same target wolf+poison dies once")
}

// --- Lovers chain ---
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("A", .villager, lover: true), player("B", .seer, lover: true), player("C", .villager)]
    store.phase = .day; store.dayNumber = 1
    store.eliminateByVote(store.players[1].id)
    expect(!store.players[1].alive && !store.players[2].alive, "Lover death kills partner")
    expect(store.lastDeaths.contains { $0.playerID == store.players[2].id && $0.cause == .heartbreak }, "Partner cause is heartbreak")
}

// --- Hunter resolves before victory ---
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("Hunter", .hunter)]
    store.phase = .day; store.dayNumber = 1
    let hunterID = store.players[1].id
    let wolfID = store.players[0].id
    store.eliminateByVote(hunterID)
    expect(store.pendingResolution == .hunter(hunterID), "Dead hunter gets last shot before win")
    expect(store.winner == nil, "Winner waits for hunter shot")
    store.resolveHunterShot(targetID: wolfID)
    expect(store.winner == .draw, "Hunter can turn final wolves win into draw")
}

// --- Mayor succession after hunter if game continues ---
do {
    let store = WerewolfStore()
    store.players = [
        player("Wolf", .werewolf),
        player("HunterMayor", .hunter, mayor: true),
        player("A", .villager),
        player("B", .villager),
        player("C", .villager)
    ]
    store.phase = .day; store.dayNumber = 1
    let hm = store.players[1].id
    store.eliminateByVote(hm)
    expect(store.pendingResolution == .hunter(hm), "Hunter is resolved before mayor succession")
    let target = store.players[2].id
    store.resolveHunterShot(targetID: target)
    expect(store.pendingResolution == .mayorSuccessor, "Mayor succession requested after hunter")
    let successor = store.players[3].id
    store.appointMayor(successor)
    expect(store.mayor?.id == successor, "Mayor successor saved")
    expect(store.pendingResolution == nil, "Resolution finished")
}

// --- Mayor not required if game ended ---
do {
    let store = WerewolfStore()
    store.players = [player("MayorWolf", .werewolf, mayor: true), player("A", .villager), player("B", .villager)]
    store.phase = .day; store.dayNumber = 1
    store.eliminateByVote(store.players[0].id)
    expect(store.winner == .village, "Killing last wolf ends game")
    expect(store.pendingResolution == nil, "No pointless mayor succession after game over")
}

// --- First day requires mayor before next night ---
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("A", .villager), player("B", .villager)]
    store.phase = .day; store.dayNumber = 1; store.nightNumber = 1
    store.startNextNight()
    expect(store.phase == .day, "Cannot start night 2 before mayor election")
    let mayor = store.players[1].id
    store.appointMayor(mayor)
    store.startNextNight()
    expect(store.phase == .night && store.nightNumber == 2, "Night 2 starts after mayor election")
}

// --- Mixed lovers last pair after a vote ---
do {
    let store = WerewolfStore()
    store.players = [
        player("WolfLover", .werewolf, lover: true),
        player("VillageLover", .villager, lover: true),
        player("Other", .villager)
    ]
    store.phase = .day; store.dayNumber = 1
    store.eliminateByVote(store.players[2].id)
    expect(store.winner == .lovers, "Mixed lovers win when they become final pair")
}

print("✅ Werewolf core/store tests passed")
