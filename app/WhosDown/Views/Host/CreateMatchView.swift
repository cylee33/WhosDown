import SwiftUI

/// Phase 0 placeholder for the Create tab. 1.11 builds Create Match (H17–H19, H45).
struct CreateMatchView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Create Match", systemImage: "plus.circle", description: Text("Coming in 1.11"))
                .navigationTitle("Create Match")
        }
    }
}

#Preview {
    CreateMatchView()
}
