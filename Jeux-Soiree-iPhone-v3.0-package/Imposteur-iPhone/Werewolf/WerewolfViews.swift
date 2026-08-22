import SwiftUI

struct WerewolfModuleView: View {
    @StateObject private var store = WerewolfStore()
    @State private var showRules = false
    @State private var showCharacters = false
    let onExit: () -> Void

    var body: some View {
        Group {
            switch store.screen {
            case .home:
                WerewolfHomeView(onExit: onExit, showRules: { showRules = true }, showCharacters: { showCharacters = true })
            case .setup:
                WerewolfSetupView()
            case .names:
                WerewolfNamesView()
            case .reveal:
                WerewolfRevealView()
            case .passToGameMaster:
                WerewolfPassToGMView()
            case .game:
                WerewolfGameView(showRules: { showRules = true }, showCharacters: { showCharacters = true })
            }
        }
        .environmentObject(store)
        .sheet(isPresented: $showRules) {
            WerewolfRulesView { showRules = false }
        }
        .sheet(isPresented: $showCharacters) {
            WerewolfCharactersView { showCharacters = false }
        }
        .alert("Information", isPresented: Binding(
            get: { store.message != nil },
            set: { if !$0 { store.message = nil } }
        )) {
            Button("OK", role: .cancel) { store.message = nil }
        } message: {
            Text(store.message ?? "")
        }
    }
}

private struct WerewolfHomeView: View {
    @EnvironmentObject private var store: WerewolfStore
    let onExit: () -> Void
    let showRules: () -> Void
    let showCharacters: () -> Void

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Werewolf", backAction: onExit)

            VStack(alignment: .leading, spacing: 5) {
                Text("Loup-Garou")
                    .font(.largeTitle.bold())
                Text("Rôles secrets et assistant interactif du Maître du Jeu")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Nouvelle partie") { store.openSetup() }
                .buttonStyle(PartyPrimaryButtonStyle())

            Button(action: showRules) {
                HStack {
                    Image(systemName: "book.closed.fill")
                    Text("Règles")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PartyPrimaryButtonStyle(secondary: true))

            Button(action: showCharacters) {
                HStack {
                    Image(systemName: "person.crop.rectangle.stack.fill")
                    Text("Personnages")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PartyPrimaryButtonStyle(secondary: true))
        }
    }
}

private struct WerewolfSetupView: View {
    @EnvironmentObject private var store: WerewolfStore

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Nouvelle partie", backAction: store.returnHome)

            PartyPanel {
                Text("Nombre de joueurs")
                    .font(.headline)
                HStack {
                    SmallStepButton(systemName: "minus") { store.updatePlayerCount(-1) }
                    Spacer()
                    Text("\(store.setup.playerCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Spacer()
                    SmallStepButton(systemName: "plus") { store.updatePlayerCount(1) }
                }
                Text("Le Maître du Jeu n’est pas compté parmi les joueurs. Le jeu de base est recommandé à partir de 8 joueurs, mais l’app accepte 4 à 30 joueurs pour vos variantes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PartyPanel {
                Text("Composition des rôles")
                    .font(.headline)

                WerewolfRoleCounterRow(role: .villager)
                WerewolfRoleCounterRow(role: .werewolf)

                Divider()

                ForEach(WerewolfRole.allCases.filter { !$0.repeatable }) { role in
                    WerewolfSpecialRoleRow(role: role)
                }

                Divider()
                HStack {
                    Text("Rôles sélectionnés")
                        .font(.headline)
                    Spacer()
                    Text("\(store.setup.roleCount) / \(store.setup.playerCount)")
                        .font(.headline.monospacedDigit())
                }

                if let error = store.setupError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Button("Choisir les noms") { store.prepareNames() }
                    .buttonStyle(PartyPrimaryButtonStyle())
                    .disabled(store.setupError != nil)
                    .opacity(store.setupError == nil ? 1 : 0.45)
            }
        }
    }
}

private struct SmallStepButton: View {
    let systemName: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(Color.gray.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct WerewolfRoleCounterRow: View {
    @EnvironmentObject private var store: WerewolfStore
    let role: WerewolfRole

    var body: some View {
        HStack(spacing: 12) {
            Image(role.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 55)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(role.title)
                .font(.headline)
            Spacer()
            SmallStepButton(systemName: "minus") { store.updateRole(role, delta: -1) }
            Text("\(store.setup.count(role))")
                .font(.headline.monospacedDigit())
                .frame(width: 28)
            SmallStepButton(systemName: "plus") { store.updateRole(role, delta: 1) }
        }
    }
}

private struct WerewolfSpecialRoleRow: View {
    @EnvironmentObject private var store: WerewolfStore
    let role: WerewolfRole

    var body: some View {
        Button { store.toggleSpecialRole(role) } label: {
            HStack(spacing: 12) {
                Image(role.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(role.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Rôle unique")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: store.setup.count(role) == 1 ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(store.setup.count(role) == 1 ? Color.accentColor : Color.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct WerewolfNamesView: View {
    @EnvironmentObject private var store: WerewolfStore

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Noms des joueurs", backAction: { store.screen = .setup })

            PartyPanel {
                ForEach(0..<store.setup.playerCount, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Joueur \(index + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Prénom", text: Binding(
                            get: { index < store.names.count ? store.names[index] : "" },
                            set: { value in
                                guard index < store.names.count else { return }
                                store.names[index] = String(value.prefix(24))
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                    }
                }

                Button("Attribuer les rôles au hasard") { store.assignRoles() }
                    .buttonStyle(PartyPrimaryButtonStyle())
                    .disabled(!store.allNamesFilled)
                    .opacity(store.allNamesFilled ? 1 : 0.45)
            }
        }
    }
}

private struct WerewolfRevealView: View {
    @EnvironmentObject private var store: WerewolfStore

    var body: some View {
        PartyPage {
            Text("Carte secrète")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            if let player = store.currentRevealPlayer {
                PartyPanel {
                    if !store.revealVisible {
                        Text("Passe le téléphone à")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(player.name)
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Personne d’autre ne doit regarder.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Button("Voir ma carte") { store.showRevealCard() }
                            .buttonStyle(PartyPrimaryButtonStyle())
                    } else {
                        Text(player.name)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Image(player.role.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 285)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .frame(maxWidth: .infinity)

                        Text(player.role.title)
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text(player.role.shortDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Button(store.revealIndex == store.players.count - 1 ? "Masquer et terminer" : "Masquer et passer") {
                            store.hideRevealAndAdvance()
                        }
                        .buttonStyle(PartyPrimaryButtonStyle())
                    }
                }
            }
        }
    }
}

private struct WerewolfPassToGMView: View {
    @EnvironmentObject private var store: WerewolfStore

    var body: some View {
        PartyPage {
            PartyPanel {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 50))
                    .frame(maxWidth: .infinity)
                Text("Passez le téléphone au Maître du Jeu")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text("À partir de maintenant, l’écran contient toutes les informations secrètes de la partie. Aucun joueur ne doit le regarder.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Button("Commencer la partie") { store.beginGameMasterMode() }
                    .buttonStyle(PartyPrimaryButtonStyle())
            }
        }
    }
}

private struct WerewolfGameView: View {
    @EnvironmentObject private var store: WerewolfStore
    @State private var confirmHome = false
    let showRules: () -> Void
    let showCharacters: () -> Void

    var body: some View {
        Group {
            switch store.phase {
            case .night:
                WerewolfNightView(homeAction: { confirmHome = true })
            case .day:
                WerewolfDayView(homeAction: { confirmHome = true }, showRules: showRules, showCharacters: showCharacters)
            case .gameOver:
                WerewolfGameOverView(homeAction: { confirmHome = true })
            }
        }
        .confirmationDialog("Revenir à l’accueil de Werewolf ?", isPresented: $confirmHome, titleVisibility: .visible) {
            Button("Abandonner la partie", role: .destructive) { store.returnHome() }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("La partie en cours sera abandonnée.")
        }
    }
}

private struct WerewolfNightView: View {
    @EnvironmentObject private var store: WerewolfStore
    let homeAction: () -> Void

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Nuit \(store.nightNumber)", homeAction: homeAction)

            switch store.nightStep {
            case .villageSleeps:
                NightIntroPanel(
                    systemImage: "moon.stars.fill",
                    title: "Le village s’endort",
                    text: "Demande à tous les joueurs de fermer les yeux et de rester silencieux.",
                    button: "Le village s’est endormi",
                    action: store.continueFromVillageSleeps
                )

            case .thief:
                WerewolfThiefNightView()
            case .cupid:
                WerewolfCupidNightView()
            case .loversWake:
                NightIntroPanel(
                    systemImage: "heart.fill",
                    title: "Réveillez les Amoureux",
                    text: "Les deux personnes choisies par Cupidon ouvrent les yeux, se reconnaissent, puis se rendorment.",
                    button: "Les Amoureux se rendorment",
                    action: store.continueAfterLoversWake
                )
            case .seer:
                WerewolfSeerNightView()
            case .wolves:
                WerewolfWolvesNightView()
            case .witch:
                WerewolfWitchNightView()
            case .dawn:
                NightIntroPanel(
                    systemImage: "sun.max.fill",
                    title: "Le village se réveille",
                    text: "Les décisions de la nuit vont maintenant être appliquées.",
                    button: "Réveiller le village",
                    action: store.wakeVillage
                )
            }
        }
    }
}

private struct NightIntroPanel: View {
    let systemImage: String
    let title: String
    let text: String
    let button: String
    let action: () -> Void

    var body: some View {
        PartyPanel {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .frame(maxWidth: .infinity)
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(text)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Button(button, action: action)
                .buttonStyle(PartyPrimaryButtonStyle())
        }
    }
}

private struct WerewolfThiefNightView: View {
    @EnvironmentObject private var store: WerewolfStore

    var body: some View {
        RoleNightPanel(role: .thief, title: "Réveillez le Voleur", instruction: "Sélectionnez le Voleur lui-même et la personne avec laquelle il souhaite échanger son rôle.") {
            WerewolfActionGrid(
                players: store.alivePlayers,
                selectedIDs: store.selectedIDs,
                accent: .cyan,
                maxSelection: 2,
                onTap: { store.toggleSelection($0, maximum: 2) }
            )

            if let thief = store.currentThief {
                Text("Le Voleur actuel est \(thief.name). Sa case doit faire partie des deux sélections.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Valider l’échange") { store.confirmThiefSwap() }
                .buttonStyle(PartyPrimaryButtonStyle())
                .disabled(store.selectedIDs.count != 2 || (store.currentThief.map { !store.selectedIDs.contains($0.id) } ?? true))
                .opacity(store.selectedIDs.count == 2 ? 1 : 0.45)

            SkipNightButton(action: store.skipCurrentNightAction)
        }
    }
}

private struct WerewolfCupidNightView: View {
    @EnvironmentObject private var store: WerewolfStore

    var body: some View {
        RoleNightPanel(role: .cupid, title: "Réveillez Cupidon", instruction: "Choisissez les deux personnes qui vont devenir Amoureuses.") {
            WerewolfActionGrid(
                players: store.alivePlayers,
                selectedIDs: store.selectedIDs,
                accent: .pink,
                maxSelection: 2,
                onTap: { store.toggleSelection($0, maximum: 2) }
            )
            Button("Valider les deux Amoureux") { store.confirmCupid() }
                .buttonStyle(PartyPrimaryButtonStyle())
                .disabled(store.selectedIDs.count != 2)
                .opacity(store.selectedIDs.count == 2 ? 1 : 0.45)
            SkipNightButton(action: store.skipCurrentNightAction)
        }
    }
}

private struct WerewolfSeerNightView: View {
    @EnvironmentObject private var store: WerewolfStore
    @State private var confirmReveal = false

    var body: some View {
        RoleNightPanel(role: .seer, title: "Réveillez la Voyante", instruction: store.seerRevealedPlayer == nil ? "Choisissez la carte que la Voyante souhaite découvrir." : "Montrez cette carte uniquement à la Voyante.") {
            if let revealed = store.seerRevealedPlayer {
                Image(revealed.role.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(maxWidth: .infinity)
                Text(revealed.name)
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                Text(revealed.role.title)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity)
                Button("Suite") { store.continueAfterSeerReveal() }
                    .buttonStyle(PartyPrimaryButtonStyle())
            } else {
                WerewolfActionGrid(
                    players: store.alivePlayers,
                    selectedIDs: store.selectedIDs,
                    accent: .blue,
                    maxSelection: 1,
                    onTap: { store.toggleSelection($0, maximum: 1) }
                )
                Button("Révéler cette carte") { confirmReveal = true }
                    .buttonStyle(PartyPrimaryButtonStyle())
                    .disabled(store.selectedIDs.count != 1)
                    .opacity(store.selectedIDs.count == 1 ? 1 : 0.45)
                SkipNightButton(action: store.skipCurrentNightAction)
            }
        }
        .confirmationDialog("Êtes-vous sûr de vouloir révéler cette carte ?", isPresented: $confirmReveal, titleVisibility: .visible) {
            Button("Révéler") { store.confirmSeerSelection() }
            Button("Annuler", role: .cancel) { }
        }
    }
}

private struct WerewolfWolvesNightView: View {
    @EnvironmentObject private var store: WerewolfStore
    @State private var confirmTarget = false

    private var selectedName: String {
        guard let id = store.selectedIDs.first else { return "cette personne" }
        return store.players.first(where: { $0.id == id })?.name ?? "cette personne"
    }

    var body: some View {
        RoleNightPanel(role: .werewolf, title: "Réveillez les Loups-Garous", instruction: "Les Loups-Garous choisissent une victime. Votre règle maison autorise aussi à viser un autre Loup-Garou.") {
            if store.players.contains(where: { $0.alive && $0.role == .littleGirl }) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "eye.fill")
                        Text("La Petite Fille peut tenter d’observer discrètement les Loups-Garous pendant cette étape.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Button { store.toggleLittleGirlCaught() } label: {
                        HStack {
                            Image(systemName: store.littleGirlCaughtThisNight ? "exclamationmark.triangle.fill" : "eye.slash")
                            Text(store.littleGirlCaughtThisNight ? "Petite Fille repérée" : "Signaler si la Petite Fille est repérée")
                            Spacer()
                        }
                    }
                    .buttonStyle(PartyPrimaryButtonStyle(secondary: !store.littleGirlCaughtThisNight))
                }
                .padding(12)
                .background(Color.gray.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            WerewolfActionGrid(
                players: store.alivePlayers,
                selectedIDs: store.selectedIDs,
                accent: .red,
                maxSelection: 1,
                onTap: { store.toggleSelection($0, maximum: 1) }
            )
            Button("Valider la victime") { confirmTarget = true }
                .buttonStyle(PartyPrimaryButtonStyle())
                .disabled(store.selectedIDs.count != 1)
                .opacity(store.selectedIDs.count == 1 ? 1 : 0.45)
            SkipNightButton(action: store.skipCurrentNightAction)
        }
        .confirmationDialog("Confirmer la cible ?", isPresented: $confirmTarget, titleVisibility: .visible) {
            Button("Oui, viser \(selectedName)", role: .destructive) { store.confirmWolfTarget() }
            Button("Annuler", role: .cancel) { }
        }
    }
}

private struct WerewolfWitchNightView: View {
    @EnvironmentObject private var store: WerewolfStore

    var body: some View {
        RoleNightPanel(role: .witch, title: "Réveillez la Sorcière", instruction: store.witchIntroSeen ? "Choisissez les potions que la Sorcière souhaite utiliser." : "Montrez à la Sorcière la personne visée par les Loups-Garous.") {
            if !store.witchIntroSeen {
                if let target = store.wolfTarget {
                    Text(target.name)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                    Text("a été visé(e) par les Loups-Garous")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Aucune personne n’a été visée cette nuit.")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                }
                Button("Suite") { store.showWitchChoices() }
                    .buttonStyle(PartyPrimaryButtonStyle())
                SkipNightButton(action: store.skipCurrentNightAction)
            } else {
                if store.healingPotionAvailable {
                    Button {
                        store.toggleWitchSave()
                    } label: {
                        HStack {
                            Image(systemName: store.witchWillSave ? "checkmark.circle.fill" : "cross.case.fill")
                            VStack(alignment: .leading) {
                                Text("Potion de vie").font(.headline)
                                Text(store.wolfTarget == nil ? "Aucune victime à sauver" : "Sauver \(store.wolfTarget?.name ?? "la victime")")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(PartyPrimaryButtonStyle(secondary: !store.witchWillSave))
                    .disabled(store.wolfTarget == nil)
                } else {
                    Text("Potion de vie déjà utilisée")
                        .foregroundStyle(.secondary)
                }

                Divider()
                Text(store.poisonPotionAvailable ? "Potion de mort : choisissez éventuellement une cible." : "Potion de mort déjà utilisée")
                    .font(.headline)

                if store.poisonPotionAvailable {
                    WerewolfWitchGrid()
                }

                Button("Valider les choix") { store.confirmWitch() }
                    .buttonStyle(PartyPrimaryButtonStyle())
                SkipNightButton(action: store.skipCurrentNightAction)
            }
        }
    }
}

private struct WerewolfWitchGrid: View {
    @EnvironmentObject private var store: WerewolfStore
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(store.alivePlayers) { player in
                let isWolfVictim = store.pendingWolfTargetID == player.id
                let isPoison = store.witchPoisonTargetID == player.id
                Button { store.chooseWitchPoisonTarget(player.id) } label: {
                    VStack(spacing: 5) {
                        Text(player.name)
                            .font(.headline)
                            .lineLimit(1)
                        if isWolfVictim {
                            Text("Visé par les Loups")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                        if isPoison {
                            Text("Poison")
                                .font(.caption.bold())
                                .foregroundStyle(.purple)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .padding(10)
                    .background(isWolfVictim ? Color.red.opacity(0.18) : Color.gray.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isPoison ? Color.purple : (isWolfVictim ? Color.red : Color.clear), lineWidth: isPoison ? 3 : 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct RoleNightPanel<Content: View>: View {
    let role: WerewolfRole
    let title: String
    let instruction: String
    let content: Content

    init(role: WerewolfRole, title: String, instruction: String, @ViewBuilder content: () -> Content) {
        self.role = role
        self.title = title
        self.instruction = instruction
        self.content = content()
    }

    var body: some View {
        PartyPanel {
            HStack(spacing: 14) {
                Image(role.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2.bold())
                    Text(instruction)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
    }
}

private struct SkipNightButton: View {
    let action: () -> Void
    var body: some View {
        Button("Passer cette étape", action: action)
            .buttonStyle(PartyPrimaryButtonStyle(secondary: true))
    }
}

private struct WerewolfActionGrid: View {
    let players: [WerewolfPlayer]
    let selectedIDs: Set<UUID>
    let accent: Color
    let maxSelection: Int
    let onTap: (UUID) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(players) { player in
                let selected = selectedIDs.contains(player.id)
                Button { onTap(player.id) } label: {
                    HStack {
                        Text(player.name)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(accent)
                        }
                    }
                    .padding(13)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(selected ? accent.opacity(0.15) : Color.gray.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(selected ? accent : Color.clear, lineWidth: 2.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WerewolfDayView: View {
    @EnvironmentObject private var store: WerewolfStore
    @State private var showEliminate = false
    @State private var showMayor = false
    let homeAction: () -> Void
    let showRules: () -> Void
    let showCharacters: () -> Void

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Jour \(store.dayNumber)", homeAction: homeAction)

            HStack(spacing: 12) {
                Button(action: showRules) {
                    Label("Règles", systemImage: "book.closed.fill")
                }
                .buttonStyle(PartyPrimaryButtonStyle(secondary: true))

                Button(action: showCharacters) {
                    Label("Personnages", systemImage: "person.crop.rectangle.stack.fill")
                }
                .buttonStyle(PartyPrimaryButtonStyle(secondary: true))
            }

            if let text = store.lastEventText {
                PartyPanel {
                    Text(text)
                        .font(.headline)
                }
            }

            if let resolution = store.pendingResolution {
                WerewolfPendingResolutionView(resolution: resolution)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tableau de bord du Maître du Jeu")
                        .font(.title2.bold())
                    Text("Écran secret : ne le montre à aucun joueur.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                WerewolfDashboardGrid(players: store.players)

                if store.mayor == nil && !store.alivePlayers.isEmpty {
                    Button("Élire le Maire") { showMayor = true }
                        .buttonStyle(PartyPrimaryButtonStyle(secondary: true))
                }

                Button("Éliminer un joueur") { showEliminate = true }
                    .buttonStyle(PartyPrimaryButtonStyle())
                    .disabled(store.alivePlayers.isEmpty)

                Button("Commencer la nuit suivante") { store.startNextNight() }
                    .buttonStyle(PartyPrimaryButtonStyle(secondary: true))
            }
        }
        .sheet(isPresented: $showEliminate) {
            WerewolfDayPickerSheet(
                title: "Éliminer un joueur",
                players: store.alivePlayers,
                destructive: true,
                confirmLabel: "Éliminer",
                onConfirm: { id in
                    store.eliminateByVote(id)
                    showEliminate = false
                },
                onCancel: { showEliminate = false }
            )
        }
        .sheet(isPresented: $showMayor) {
            WerewolfDayPickerSheet(
                title: "Élire le Maire",
                players: store.alivePlayers,
                destructive: false,
                confirmLabel: "Nommer Maire",
                onConfirm: { id in
                    store.appointMayor(id)
                    showMayor = false
                },
                onCancel: { showMayor = false }
            )
        }
    }
}

private struct WerewolfPendingResolutionView: View {
    @EnvironmentObject private var store: WerewolfStore
    let resolution: WerewolfPendingResolution
    @State private var selectedID: UUID?

    var body: some View {
        PartyPanel {
            switch resolution {
            case .hunter:
                Image("WWChasseur")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .frame(maxWidth: .infinity)
                Text("Le Chasseur est mort")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity)
                Text("Il doit désigner une personne à emporter avec lui.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                ResolutionChoiceGrid(players: store.alivePlayers, selectedID: $selectedID)
                Button("Valider le tir") {
                    if let selectedID { store.resolveHunterShot(targetID: selectedID) }
                }
                .buttonStyle(PartyPrimaryButtonStyle())
                .disabled(selectedID == nil)
                .opacity(selectedID == nil ? 0.45 : 1)

            case .mayorSuccessor:
                Image("WWMaire")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .frame(maxWidth: .infinity)
                Text("Le Maire est mort")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity)
                Text("Choisissez son successeur parmi les joueurs encore en vie.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                ResolutionChoiceGrid(players: store.alivePlayers, selectedID: $selectedID)
                Button("Nommer le nouveau Maire") {
                    if let selectedID { store.appointMayor(selectedID) }
                }
                .buttonStyle(PartyPrimaryButtonStyle())
                .disabled(selectedID == nil)
                .opacity(selectedID == nil ? 0.45 : 1)
            }
        }
        .onChange(of: resolution) { _ in selectedID = nil }
    }
}

private struct ResolutionChoiceGrid: View {
    let players: [WerewolfPlayer]
    @Binding var selectedID: UUID?
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(players) { player in
                Button { selectedID = selectedID == player.id ? nil : player.id } label: {
                    Text(player.name)
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .padding(.horizontal, 8)
                        .background(selectedID == player.id ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedID == player.id ? Color.accentColor : Color.clear, lineWidth: 2))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WerewolfDashboardGrid: View {
    let players: [WerewolfPlayer]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(players) { player in
                WerewolfDashboardTile(player: player)
            }
        }
    }
}

private struct WerewolfDashboardTile: View {
    let player: WerewolfPlayer

    private var campColor: Color {
        player.role.camp == .wolves ? .red : .green
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 5) {
                Text(player.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(player.role.title)
                    .font(.caption.bold())
                    .foregroundStyle(player.alive ? Color.primary : Color.secondary)
                if !player.alive {
                    Text("Éliminé")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 78)
            .padding(10)

            HStack(spacing: 4) {
                if player.isLover {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                }
                if player.isMayor {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .padding(8)
        }
        .background(campColor.opacity(player.alive ? 0.22 : 0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(campColor.opacity(player.alive ? 0.95 : 0.25), lineWidth: 2)
        )
        .overlay {
            if player.isLover {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.pink.opacity(player.alive ? 0.95 : 0.35), lineWidth: 3)
                    .padding(-3)
            }
        }
        .shadow(color: campColor.opacity(player.alive ? 0.45 : 0), radius: 8)
        .shadow(color: player.isLover && player.alive ? Color.pink.opacity(0.45) : .clear, radius: 11)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .opacity(player.alive ? 1 : 0.58)
        .saturation(player.alive ? 1 : 0.25)
    }
}

private struct WerewolfDayPickerSheet: View {
    let title: String
    let players: [WerewolfPlayer]
    let destructive: Bool
    let confirmLabel: String
    let onConfirm: (UUID) -> Void
    let onCancel: () -> Void
    @State private var selectedID: UUID?
    @State private var confirmFinal = false

    private var selectedName: String {
        guard let id = selectedID else { return "cette personne" }
        return players.first(where: { $0.id == id })?.name ?? "cette personne"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ResolutionChoiceGrid(players: players, selectedID: $selectedID)
                    Button(confirmLabel) { confirmFinal = true }
                        .buttonStyle(PartyPrimaryButtonStyle())
                        .disabled(selectedID == nil)
                        .opacity(selectedID == nil ? 0.45 : 1)
                }
                .padding(20)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", action: onCancel)
                }
            }
        }
        .confirmationDialog(destructive ? "Êtes-vous sûr de vouloir éliminer \(selectedName) ?" : "Confirmer \(selectedName) comme Maire ?", isPresented: $confirmFinal, titleVisibility: .visible) {
            if let selectedID {
                if destructive {
                    Button(confirmLabel, role: .destructive) { onConfirm(selectedID) }
                } else {
                    Button(confirmLabel) { onConfirm(selectedID) }
                }
            }
            Button("Annuler", role: .cancel) { }
        }
    }
}

private struct WerewolfGameOverView: View {
    @EnvironmentObject private var store: WerewolfStore
    let homeAction: () -> Void

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Partie terminée", homeAction: homeAction)

            PartyPanel {
                Text(store.winner?.title ?? "Partie terminée")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(store.winner?.subtitle ?? "")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Divider()
                Text("Survivants")
                    .font(.headline)
                if store.alivePlayers.isEmpty {
                    Text("Aucun")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.alivePlayers) { player in
                        HStack {
                            Text(player.name)
                            Spacer()
                            Text(player.role.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Nouvelle partie") { store.restartFromSetup() }
                    .buttonStyle(PartyPrimaryButtonStyle())
                Button("Accueil Werewolf") { store.returnHome() }
                    .buttonStyle(PartyPrimaryButtonStyle(secondary: true))
            }
        }
    }
}
