import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Yükleniyor...")
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
} 