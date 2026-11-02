import SwiftUI

/// Phase 0 placeholder for the Matches tab. 1.19 builds My Matches (H27, H28).
struct MyMatchesView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("My Matches", systemImage: "sportscourt", description: Text("Coming in 1.19"))
                .navigationTitle("My Matches")
        }
    }
}

#Preview {
    MyMatchesView()
}
