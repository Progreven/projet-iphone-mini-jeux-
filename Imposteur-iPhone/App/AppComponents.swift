import SwiftUI

struct PartyHeaderView: View {
    let title: String
    var backAction: (() -> Void)?
    var homeAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if let backAction {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Retour")
            }

            Text(title)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            if let homeAction {
                Button(action: homeAction) {
                    Image(systemName: "house.fill")
                        .font(.headline)
                        .frame(width: 42, height: 42)
                        .background(Color.gray.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Accueil du jeu")
            }
        }
    }
}

struct PartyPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct PartyPrimaryButtonStyle: ButtonStyle {
    var secondary = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(secondary ? Color.gray.opacity(0.16) : Color.accentColor)
            .foregroundStyle(secondary ? Color.primary : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct PartyPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                content
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
