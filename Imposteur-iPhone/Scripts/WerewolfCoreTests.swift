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

// 1. Le Voleur peut choisir deux joueurs quelconques, leurs rôles sont échangés,
// puis les deux révélations se font dans l'ordre exact des sélections.
do {
    let store = WerewolfStore()
    store.players = [
        player("Theo", .thief),
        player("Alice", .seer),
        player("Bob", .werewolf),
        player("Claire", .cupid),
        player("Diane", .villager)
    ]
    store.phase = .night
    store.nightNumber = 1
    store.moveToNightStep(.thief)
    let alice = store.players[1].id
    let bob = store.players[2].id
    let theo = store.players[0].id

    // On ne force plus le Voleur à faire partie des deux joueurs échangés.
    store.toggleThiefSelection(alice)
    store.toggleThiefSelection(bob)
    expect(store.thiefSelectionOrder == [alice, bob], "L'ordre de sélection du Voleur doit être conservé")
    store.toggleThiefSelection(theo) // troisième sélection ignorée
    expect(store.thiefSelectionOrder.count == 2, "Le Voleur ne doit sélectionner que deux joueurs")

    store.confirmThiefSwap()
    expect(store.players[1].role == .werewolf, "Alice doit recevoir l'ancien rôle de Bob")
    expect(store.players[2].role == .seer, "Bob doit recevoir l'ancien rôle d'Alice")
    expect(store.nightStep == .thief, "La nuit ne doit pas avancer avant les deux révélations")
    expect(store.thiefRevealPlayer?.id == alice, "Le premier joueur sélectionné doit voir son nouveau rôle en premier")
    expect(store.thiefRevealPlayer?.role == .werewolf, "La première révélation doit montrer le nouveau rôle réel")

    store.continueAfterThiefReveal()
    expect(store.thiefRevealPlayer?.id == bob, "Le second joueur sélectionné doit voir son nouveau rôle ensuite")
    expect(store.thiefRevealPlayer?.role == .seer, "La seconde révélation doit montrer le nouveau rôle réel")

    store.continueAfterThiefReveal()
    expect(store.thiefRevealPlayer == nil, "Les révélations du Voleur doivent être terminées")
    expect(store.nightStep == .cupid, "La nuit doit reprendre normalement après les deux révélations")
}

// 2. Skip du Voleur possible avant échange, mais impossible pendant les révélations.
do {
    let store = WerewolfStore()
    store.players = [player("T", .thief), player("C", .cupid), player("W", .werewolf), player("V", .villager)]
    store.phase = .night; store.nightNumber = 1; store.moveToNightStep(.thief)
    let a = store.players[0].id, b = store.players[2].id
    store.toggleThiefSelection(a); store.toggleThiefSelection(b); store.confirmThiefSwap()
    store.skipCurrentNightAction()
    expect(store.nightStep == .thief && store.thiefRevealPlayer != nil, "On ne doit pas pouvoir skipper les révélations après l'échange")
}

// 3. Premier jour : élection du Maire obligatoire avant le vote.
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("A", .villager), player("B", .villager), player("C", .villager)]
    store.phase = .day; store.dayNumber = 1; store.nightNumber = 1
    expect(store.needsInitialMayorElection, "Le premier jour doit forcer l'élection du Maire")
    expect(!store.canUseDayVote, "Le vote ne doit pas être disponible avant l'élection")

    let beforeAlive = store.alivePlayers.count
    store.eliminateByVote(store.players[1].id)
    expect(store.alivePlayers.count == beforeAlive, "Une élimination avant l'élection doit être refusée")

    let mayorID = store.players[1].id
    store.appointMayor(mayorID)
    expect(store.initialMayorElectionCompleted, "L'élection initiale doit être mémorisée")
    expect(store.mayor?.id == mayorID, "Le Maire sélectionné doit être enregistré")
    expect(store.canUseDayVote, "Le débat/vote doit être débloqué après l'élection")

    // Une seconde nomination volontaire n'est plus autorisée.
    store.appointMayor(store.players[2].id)
    expect(store.mayor?.id == mayorID, "Le Maire ne doit pas pouvoir être réélu librement après l'élection initiale")
}

// 4. Une seule élimination de jour, puis démarrage automatique de la nuit suivante.
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("A", .villager, mayor: true), player("B", .villager), player("C", .villager), player("D", .villager)]
    store.phase = .day; store.dayNumber = 1; store.nightNumber = 1
    store.initialMayorElectionCompleted = true
    let target = store.players[2].id
    store.eliminateByVote(target)
    expect(!store.players[2].alive, "La cible du vote doit mourir")
    expect(store.phase == .day && store.currentDeathAnnouncement?.id != nil, "Le rôle de la victime doit être annoncé avant la nuit")
    store.continueDeathAnnouncement()
    expect(store.phase == .night, "Après l'annonce et les résolutions, la nuit doit recommencer automatiquement")
    expect(store.nightNumber == 2, "La nuit suivante doit être la nuit 2")
    let aliveAfter = store.alivePlayers.count
    store.eliminateByVote(store.players[3].id)
    expect(store.alivePlayers.count == aliveAfter, "Impossible d'effectuer un second vote pendant la même journée")
}

// 5. Si le vote tue le Maire, la succession doit être résolue avant la nuit.
do {
    let store = WerewolfStore()
    store.players = [
        player("Wolf", .werewolf),
        player("Mayor", .villager, mayor: true),
        player("A", .villager),
        player("B", .villager),
        player("C", .villager)
    ]
    store.phase = .day; store.dayNumber = 2; store.nightNumber = 2
    store.initialMayorElectionCompleted = true
    let mayor = store.players[1].id
    store.eliminateByVote(mayor)
    expect(store.currentDeathAnnouncement?.role == .villager, "Le rôle du Maire éliminé doit être annoncé")
    store.continueDeathAnnouncement()
    expect(store.pendingResolution == .mayorSuccessor, "La succession du Maire doit bloquer le passage à la nuit")
    expect(store.phase == .day, "Le jeu doit rester en journée pendant la succession")
    let successor = store.players[2].id
    store.appointMayor(successor)
    expect(store.mayor?.id == successor, "Le successeur doit être enregistré")
    expect(store.phase == .night && store.nightNumber == 3, "La nuit doit démarrer automatiquement après la succession")
}

// 6. Chasseur : résolution obligatoire avant retour automatique à la nuit.
do {
    let store = WerewolfStore()
    store.players = [
        player("Wolf", .werewolf),
        player("Mayor", .villager, mayor: true),
        player("Hunter", .hunter),
        player("A", .villager),
        player("B", .villager),
        player("C", .villager)
    ]
    store.phase = .day; store.dayNumber = 2; store.nightNumber = 2
    store.initialMayorElectionCompleted = true
    let hunter = store.players[2].id
    store.eliminateByVote(hunter)
    expect(store.currentDeathAnnouncement?.role == .hunter, "Le rôle du Chasseur doit être annoncé avant son tir")
    store.continueDeathAnnouncement()
    expect(store.pendingResolution == .hunter(hunter), "Le Chasseur doit agir après l'annonce et avant la nuit")
    expect(store.phase == .day, "Le jeu doit rester en journée pendant le tir du Chasseur")
    store.resolveHunterShot(targetID: store.players[3].id)
    expect(store.currentDeathAnnouncement?.playerName == "A", "La cible du Chasseur doit aussi être annoncée")
    store.continueDeathAnnouncement()
    expect(store.phase == .night && store.nightNumber == 3, "Après le tir, son annonce et les résolutions, la nuit doit commencer")
}

// 7. Une victoire déclenchée par le vote doit empêcher de relancer une nuit.
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("Mayor", .villager, mayor: true), player("A", .villager)]
    store.phase = .day; store.dayNumber = 2; store.nightNumber = 2
    store.initialMayorElectionCompleted = true
    store.eliminateByVote(store.players[0].id)
    expect(store.currentDeathAnnouncement?.role == .werewolf, "Le rôle du dernier Loup doit être révélé")
    store.continueDeathAnnouncement()
    expect(store.winner == .village, "La mort du dernier Loup doit donner la victoire au Village")
    expect(store.phase == .gameOver, "La partie doit se terminer au lieu de lancer une nouvelle nuit")
    expect(store.nightNumber == 2, "Aucune nuit supplémentaire ne doit être créée après victoire")
}

// 8. Le deuxième jour ne doit jamais refaire l'élection initiale.
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("Mayor", .villager, mayor: true), player("A", .villager), player("B", .villager)]
    store.phase = .day; store.dayNumber = 2
    store.initialMayorElectionCompleted = true
    expect(!store.needsInitialMayorElection, "L'élection initiale ne doit exister qu'au jour 1")
    expect(store.canUseDayVote, "Le jour 2 doit aller directement au débat/vote si aucune résolution n'est en attente")
}

// 9. Une nuit qui débouche sur le premier jour force bien l'élection.
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("A", .villager), player("B", .villager), player("C", .villager)]
    store.phase = .night; store.nightNumber = 1; store.moveToNightStep(.dawn)
    store.wakeVillage()
    expect(store.phase == .day && store.dayNumber == 1, "Le réveil doit ouvrir le premier jour")
    expect(store.needsInitialMayorElection, "Le premier jour issu de la nuit doit forcer l'élection")
}

// 10. Sorcière : une seule potion maximum par nuit, avec remplacement du choix avant validation.
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("Victime", .villager), player("Cible", .villager), player("Sorcière", .witch)]
    store.phase = .night
    store.pendingWolfTargetID = store.players[1].id
    store.moveToNightStep(.witch)
    store.showWitchChoices()
    store.chooseWitchAction(store.players[1].id)
    expect(store.witchWillSave && store.witchPoisonTargetID == nil, "Le sauvetage doit être le seul choix actif")
    store.chooseWitchAction(store.players[2].id)
    expect(!store.witchWillSave && store.witchPoisonTargetID == store.players[2].id, "Le poison doit remplacer le sauvetage")
    store.confirmWitch()
    expect(store.healingPotionAvailable && !store.poisonPotionAvailable, "Une seule potion doit être consommée")
}

// 11. Les morts de nuit sont annoncées une par une avec leur rôle avant les résolutions suivantes.
do {
    let store = WerewolfStore()
    store.players = [player("Wolf", .werewolf), player("A", .villager, lover: true), player("B", .seer, lover: true), player("C", .villager)]
    store.phase = .night; store.nightNumber = 1
    store.pendingWolfTargetID = store.players[1].id
    store.moveToNightStep(.dawn)
    store.wakeVillage()
    expect(store.deathAnnouncements.count == 2, "Les deux morts liées doivent être annoncées")
    expect(store.currentDeathAnnouncement?.role == .villager, "Le premier rôle doit être révélé")
    store.continueDeathAnnouncement()
    expect(store.currentDeathAnnouncement?.role == .seer, "Le second rôle doit être révélé")
    store.continueDeathAnnouncement()
    expect(!store.deathAnnouncementsActive, "Toutes les annonces doivent être terminées")
}

print("✅ Werewolf V3.3 targeted tests passed")
