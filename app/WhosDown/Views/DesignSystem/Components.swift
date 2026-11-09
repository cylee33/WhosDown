import SwiftUI

/// Full-width green button, e.g. "Send join request", "Publish Match".
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = .brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(tint.opacity(configuration.isPressed ? 0.8 : 1), in: .rect(cornerRadius: Radius.button))
    }
}

/// Full-width white button with a border, e.g. "Keep my spot", "Back to Discover".
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.surface.opacity(configuration.isPressed ? 0.7 : 1), in: .rect(cornerRadius: Radius.button))
            .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(Color.border))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var destructive: PrimaryButtonStyle { PrimaryButtonStyle(tint: .destructive) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// Small rounded label, e.g. "All Levels", "Free", "12/14".
struct Chip: View {
    let text: String
    var foreground: Color = .brand
    var background: Color = .brandSoft

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.xs + Spacing.xxs)
            .padding(.vertical, Spacing.xxs)
            .background(background, in: .capsule)
    }
}

/// White rounded card on the grey background.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))
            .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(Color.border))
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
}

/// The one layout for every bottom sheet (1.26 rule 3): title, one-line explanation,
/// optional content, then the main action above the secondary one.
struct SheetContainer<Content: View>: View {
    let title: String
    let message: String
    var content: Content
    let primaryTitle: String
    var isDestructive = false
    var primaryEnabled = true
    let primaryAction: () -> Void
    let secondaryTitle: String
    let secondaryAction: () -> Void

    init(
        title: String,
        message: String,
        primaryTitle: String,
        isDestructive: Bool = false,
        primaryEnabled: Bool = true,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String,
        secondaryAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.content = content()
        self.primaryTitle = primaryTitle
        self.isDestructive = isDestructive
        self.primaryEnabled = primaryEnabled
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title).font(.title2.bold()).foregroundStyle(Color.textPrimary).fixedSize(horizontal: false, vertical: true)
                    Text(message).font(.subheadline).foregroundStyle(Color.textSecondary).fixedSize(horizontal: false, vertical: true)
                }
                content.fixedSize(horizontal: false, vertical: true)
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(isDestructive ? .destructive : .primary)
                    .disabled(!primaryEnabled)
                Button(secondaryTitle, action: secondaryAction).buttonStyle(.secondary)
            }.padding(Spacing.m)
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Components") {
    VStack(spacing: Spacing.s) {
        HStack { Chip(text: "All Levels"); Chip(text: "12/14", foreground: .info, background: .info.opacity(0.1)) }
        Text("Card content").card()
        Button("Send join request") {}.buttonStyle(.primary)
        Button("Keep my spot") {}.buttonStyle(.secondary)
        Button("Leave Match") {}.buttonStyle(.destructive)
    }
    .padding(Spacing.s)
    .background(Color.background)
}

#Preview("Sheet") {
    Color.background.sheet(isPresented: .constant(true)) {
        SheetContainer(
            title: "Leave this Match?",
            message: "Your spot will immediately reopen for another Player.",
            primaryTitle: "Leave Match",
            isDestructive: true,
            primaryAction: {},
            secondaryTitle: "Keep my spot",
            secondaryAction: {}
        )
    }
}
