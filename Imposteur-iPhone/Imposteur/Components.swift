import SwiftUI

struct RoundedPanel<Content: View>: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct MainButtonStyle: ButtonStyle {
    var secondary = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(secondary ? Color.gray.opacity(0.16) : Color.accentColor)
            .foregroundStyle(secondary ? Color.primary : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct HeaderView: View {
    let title: String
    var backAction: (() -> Void)?
    var homeAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if let backAction {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .background(Color.gray.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text(title)
                .font(.title2.bold())

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
                .accessibilityLabel("Retour à l'accueil")
            }
        }
    }
}

struct GameModeButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 8)
            .background(isActive ? Color.white : Color.black)
            .foregroundStyle(isActive ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black, lineWidth: isActive ? 1.5 : 0)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
