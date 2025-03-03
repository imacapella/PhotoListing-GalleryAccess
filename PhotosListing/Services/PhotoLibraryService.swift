import Photos
import UIKit

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    private let imageManager = PHImageManager.default()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func fetchAssets() async -> [PhotoAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        return fetchResult.objects(at: IndexSet(0..<fetchResult.count))
            .map(PhotoAsset.init)
    }
    
    func loadImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func calculateFileSize(for asset: PHAsset) async -> String {
        if let resource = PHAssetResource.assetResources(for: asset).first {
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                let sizeOnDisk = Int64(unsignedInt64)
                let mbSize = Double(sizeOnDisk) / (1024 * 1024)
                return String(format: "%.1f MB", mbSize)
            }
        }
        
        // Tahmini boyut hesaplama
        let pixelSize = asset.pixelWidth * asset.pixelHeight
        let estimatedSize = Double(pixelSize) * 3 / (1024 * 1024)
        return String(format: "~%.1f MB", estimatedSize)
    }
    
    func deleteAssets(_ assets: [PHAsset]) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            }) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
} 