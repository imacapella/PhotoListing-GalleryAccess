import SwiftUI
import Photos

struct PhotoPreviewView: View {
    let asset: PhotoAsset
    @Environment(\.dismiss) var dismiss
    @State private var previewImage: UIImage?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LoadingView()
                }
            }
            .navigationBarItems(trailing: Button("Kapat") { dismiss() })
        }
        .onAppear {
            loadFullResolutionImage()
        }
    }
    
    private func loadFullResolutionImage() {
        Task {
            if let image = await PhotoLibraryService.shared.loadImage(
                for: asset.asset,
                targetSize: PHImageManagerMaximumSize
            ) {
                await MainActor.run {
                    previewImage = image
                }
            }
        }
    }
} 