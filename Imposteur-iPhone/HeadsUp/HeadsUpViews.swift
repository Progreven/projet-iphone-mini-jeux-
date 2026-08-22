import SwiftUI
import UniformTypeIdentifiers

struct HeadsUpModuleView: View {
    @StateObject private var store = HeadsUpStore()
    let onExit: () -> Void

    var body: some View {
        Group {
            switch store.screen {
            case .themes:
                HeadsUpThemesView(onExit: onExit)
            case .theme(let theme):
                HeadsUpThemeView(theme: theme)
            case .library(let theme):
                HeadsUpLibraryView(theme: theme)
            case .ready(let theme):
                HeadsUpReadyView(theme: theme)
            case .playing(let theme):
                HeadsUpPlayingView(theme: theme)
            case .result(let theme):
                HeadsUpResultView(theme: theme)
            }
        }
        .environmentObject(store)
        .animation(.easeInOut(duration: 0.18), value: store.screen)
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

private struct HeadsUpThemesView: View {
    @EnvironmentObject private var store: HeadsUpStore
    let onExit: () -> Void

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Heads Up", backAction: onExit)

            VStack(alignment: .leading, spacing: 5) {
                Text("Choisis un thème")
                    .font(.title.bold())
                Text("Le dernier mode mélange automatiquement toutes les bibliothèques.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(HeadsUpTheme.allCases) { theme in
                HeadsUpThemeCard(theme: theme) {
                    store.openTheme(theme)
                }
            }
        }
    }
}

private struct HeadsUpThemeCard: View {
    let theme: HeadsUpTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: theme.systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(theme.isCombined ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(17)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(theme.isCombined ? 0.14 : 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct HeadsUpThemeView: View {
    @EnvironmentObject private var store: HeadsUpStore
    let theme: HeadsUpTheme

    var body: some View {
        PartyPage {
            PartyHeaderView(title: theme.title, backAction: store.showThemes)

            PartyPanel {
                HStack(spacing: 12) {
                    Image(systemName: theme.systemImage)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.title).font(.headline)
                        Text("\(store.names(for: theme).count) cartes disponibles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Nouvelle partie") {
                    store.prepareRound(theme)
                }
                .buttonStyle(PartyPrimaryButtonStyle())
            }

            PartyPanel {
                Text("Durée de la manche")
                    .font(.headline)

                HStack {
                    Button {
                        store.setDuration(store.duration(for: theme) - 15, for: theme)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 42, height: 42)
                            .background(Color.gray.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.duration(for: theme) <= 30)

                    Spacer()

                    Text("\(store.duration(for: theme)) s")
                        .font(.title2.monospacedDigit().bold())

                    Spacer()

                    Button {
                        store.setDuration(store.duration(for: theme) + 15, for: theme)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 42, height: 42)
                            .background(Color.gray.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.duration(for: theme) >= 180)
                }

                Text("De 30 secondes à 3 minutes, par pas de 15 secondes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PartyPanel {
                Button {
                    store.openLibrary(theme)
                } label: {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                        Text("Bibliothèque")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(PartyPrimaryButtonStyle(secondary: true))

                if theme.isCombined {
                    Text("Cette bibliothèque est construite automatiquement à partir des cinq thèmes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct HeadsUpLibraryView: View {
    @EnvironmentObject private var store: HeadsUpStore
    let theme: HeadsUpTheme

    @State private var search = ""
    @State private var editingEntry: HeadsUpEntry?
    @State private var isAdding = false
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var confirmReset = false

    private var filteredEntries: [HeadsUpEntry] {
        guard !theme.isCombined else { return [] }
        let entries = store.entries(for: theme)
        let query = HeadsUpLogic.normalize(search)
        guard !query.isEmpty else { return entries }
        return entries.filter { HeadsUpLogic.normalize($0.name).contains(query) }
    }

    private var filteredCombinedNames: [String] {
        guard theme.isCombined else { return [] }
        let names = store.names(for: theme)
        let query = HeadsUpLogic.normalize(search)
        guard !query.isEmpty else { return names }
        return names.filter { HeadsUpLogic.normalize($0).contains(query) }
    }

    private var visibleCount: Int {
        theme.isCombined ? filteredCombinedNames.count : filteredEntries.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { store.closeLibrary(theme) } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Bibliothèque")
                        .font(.title2.bold())
                    Text("\(visibleCount) / \(store.names(for: theme).count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !theme.isCombined {
                    Button { isAdding = true } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            List {
                if theme.isCombined {
                    Section {
                        Text("Tous les thèmes mélange les cinq bibliothèques. Pour modifier une carte, ouvre son thème d'origine.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if theme.isCombined {
                        ForEach(filteredCombinedNames, id: \.self) { name in
                            Text(name)
                        }
                    } else {
                        ForEach(filteredEntries) { entry in
                            HStack {
                                Text(entry.name)
                                Spacer()
                                Button {
                                    editingEntry = entry
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)

                                Button(role: .destructive) {
                                    store.deleteEntry(id: entry.id, from: theme)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                Section("JSON") {
                    Button("Exporter la bibliothèque") { isExporting = true }
                    if !theme.isCombined {
                        Button("Importer un fichier JSON") { isImporting = true }
                        Button("Réinitialiser les 100 cartes d'origine", role: .destructive) { confirmReset = true }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $search, prompt: "Rechercher")
        }
        .sheet(isPresented: $isAdding) {
            HeadsUpEntryEditor(title: "Ajouter une carte", initialText: "") { text in
                if store.addEntry(text, to: theme) { isAdding = false }
            } onCancel: {
                isAdding = false
            }
        }
        .sheet(item: $editingEntry) { entry in
            HeadsUpEntryEditor(title: "Modifier la carte", initialText: entry.name) { text in
                if store.updateEntry(id: entry.id, text: text, in: theme) { editingEntry = nil }
            } onCancel: {
                editingEntry = nil
            }
        }
        .confirmationDialog("Réinitialiser cette bibliothèque ?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Réinitialiser", role: .destructive) { store.resetLibrary(theme) }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Tes modifications de ce thème seront remplacées par les 100 cartes d'origine.")
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                if let names = try? JSONDecoder().decode([String].self, from: data) {
                    _ = store.replaceLibrary(names, for: theme)
                } else if let entries = try? JSONDecoder().decode([HeadsUpEntry].self, from: data) {
                    _ = store.replaceLibrary(entries.map(\.name), for: theme)
                } else {
                    store.message = "Format JSON invalide. Utilise une liste de noms."
                }
            } catch {
                store.message = "Impossible de lire ce fichier JSON."
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: HeadsUpLibraryDocument(names: store.names(for: theme)),
            contentType: .json,
            defaultFilename: "headsup-\(theme.rawValue)"
        ) { result in
            if case .failure = result {
                store.message = "L'export du fichier a échoué."
            }
        }
    }
}

private struct HeadsUpEntryEditor: View {
    let title: String
    let initialText: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String

    init(title: String, initialText: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.initialText = initialText
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nom", text: $text)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { onSave(text) }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct HeadsUpReadyView: View {
    @EnvironmentObject private var store: HeadsUpStore
    let theme: HeadsUpTheme

    @State private var countdown: Int?
    @State private var countdownTask: Task<Void, Never>?

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Préparation", backAction: countdown == nil ? { store.cancelReady(theme) } : nil)

            PartyPanel {
                Image(systemName: "iphone")
                    .font(.system(size: 54))
                    .frame(maxWidth: .infinity)

                Text("Place l'iPhone sur ton front")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("Écran tourné vers les autres joueurs. Incline vers le haut quand tu trouves, vers le bas pour passer.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if let countdown {
                    Text(countdown == 0 ? "GO !" : "\(countdown)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Button("Lancer la manche") {
                        startCountdown()
                    }
                    .buttonStyle(PartyPrimaryButtonStyle())
                }
            }
        }
        .onDisappear {
            countdownTask?.cancel()
        }
    }

    private func startCountdown() {
        guard countdownTask == nil else { return }
        countdown = 3
        countdownTask = Task { @MainActor in
            for value in [3, 2, 1] {
                countdown = value
                try? await Task.sleep(nanoseconds: 700_000_000)
                guard !Task.isCancelled else { return }
            }
            countdown = 0
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            store.beginRound(theme)
        }
    }
}

private struct HeadsUpPlayingView: View {
    @EnvironmentObject private var store: HeadsUpStore
    @StateObject private var motion = HeadsUpMotionManager()
    @State private var confirmHome = false

    let theme: HeadsUpTheme

    private var borderColor: Color {
        switch store.feedback {
        case .neutral: return .white
        case .correct: return .green
        case .skipped: return .red
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Score")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                            Text("\(store.score)")
                                .font(.title2.monospacedDigit().bold())
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Text("\(store.timeRemaining)s")
                            .font(.title.monospacedDigit().bold())
                            .foregroundStyle(.white)

                        Spacer()

                        Button { confirmHome = true } label: {
                            Image(systemName: "house.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Accueil Heads Up")
                    }

                    Spacer(minLength: 4)

                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(borderColor, lineWidth: 6)
                            }

                        Text(store.currentCard)
                            .font(.system(size: min(max(proxy.size.shortestSide * 0.105, 34), 70), weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.45)
                            .padding(28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeOut(duration: 0.12), value: store.feedback)

                    HStack {
                        Label("↑ Trouvé", systemImage: "arrow.up")
                        Spacer()
                        Label("↓ Passer", systemImage: "arrow.down")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.72))

                    if !motion.isAvailable {
                        HStack(spacing: 12) {
                            Button("Trouvé") { store.handleTilt(.correct) }
                            Button("Passer") { store.handleTilt(.skip) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gray)
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            motion.start { action in
                store.handleTilt(action)
            }
        }
        .onDisappear {
            motion.stop()
        }
        .alert("Quitter la manche ?", isPresented: $confirmHome) {
            Button("Annuler", role: .cancel) { }
            Button("Retour à l'accueil", role: .destructive) { store.showThemes() }
        } message: {
            Text("La manche en cours sera abandonnée.")
        }
    }
}

private struct HeadsUpResultView: View {
    @EnvironmentObject private var store: HeadsUpStore
    let theme: HeadsUpTheme

    var body: some View {
        PartyPage {
            PartyHeaderView(title: "Manche terminée", homeAction: store.showThemes)

            PartyPanel {
                Text("Temps écoulé")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("\(store.score)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(store.score == 1 ? "bonne réponse" : "bonnes réponses")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                if store.skipped > 0 {
                    Text("\(store.skipped) passée\(store.skipped > 1 ? "s" : "")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Button("Rejouer") { store.replay(theme) }
                    .buttonStyle(PartyPrimaryButtonStyle())

                Button("Retour au thème") { store.openTheme(theme) }
                    .buttonStyle(PartyPrimaryButtonStyle(secondary: true))
            }
        }
    }
}

private extension CGSize {
    var shortestSide: CGFloat { min(width, height) }
}
