import SwiftUI
import Photos

struct PhotoPreviewView: View {
    let asset: PHAsset
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
                    ProgressView()
                }
            }
            .navigationBarItems(trailing: Button("Kapat") { dismiss() })
        }
        .onAppear {
            loadFullResolutionImage()
        }
    }
    
    private func loadFullResolutionImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            previewImage = result
        }
    }
} 