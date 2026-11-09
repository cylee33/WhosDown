import SwiftUI

/// A tappable chip that is green when selected, e.g. skill levels on H42 and play styles on H04.
struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.brand : Color.textPrimary)
                .padding(.horizontal, Spacing.s - Spacing.xxs)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.brandSoft : Color.clear, in: .capsule)
                .overlay(Capsule().stroke(isSelected ? Color.brand : Color.clear))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Segments keep the wireframe layout at normal sizes; a menu preserves full labels at accessibility sizes.
private struct AdaptiveSegmentedPicker: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize { content.pickerStyle(.menu) }
        else { content.pickerStyle(.segmented) }
    }
}

extension View {
    func adaptiveSegmentedPicker() -> some View { modifier(AdaptiveSegmentedPicker()) }
}

/// A Player's photo, or their initials on a soft green circle when there's no photo (1.4 rule 4).
struct AvatarView: View {
    let photoURL: String?
    let initials: String
    var size: CGFloat = 64
    /// A just-picked photo that isn't uploaded yet.
    var localImage: UIImage?

    var body: some View {
        Group {
            if let localImage {
                Image(uiImage: localImage).resizable().scaledToFill()
            } else if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }

    private var initialsView: some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .semibold))
            .foregroundStyle(Color.brand)
            .frame(width: size, height: size)
            .background(Color.brandSoft)
    }
}

/// Lays out chips in rows, wrapping to the next line when a row is full.
struct WrappingHStack: Layout {
    var spacing: CGFloat = Spacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil))
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.m) {
        WrappingHStack {
            ForEach(SkillLevel.allCases) { level in
                SelectableChip(title: level.displayName, isSelected: level == .allLevels) {}
            }
        }
        HStack {
            AvatarView(photoURL: nil, initials: "AM")
            AvatarView(photoURL: nil, initials: "JM", size: 40)
        }
    }
    .padding(Spacing.m)
}
