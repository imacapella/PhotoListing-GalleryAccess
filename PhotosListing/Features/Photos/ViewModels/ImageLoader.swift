import SwiftUI
import Photos

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var fileSize: String = "..."
    
    private let service = PhotoLibraryService.shared
    
    func load(asset: PHAsset) {
        Task {
            // Görsel yükleme
            if let image = await service.loadImage(for: asset, targetSize: CGSize(width: 300, height: 300)) {
                self.image = image
            }
            
            // Dosya boyutu hesaplama
            self.fileSize = await service.calculateFileSize(for: asset)
        }
    }
} 