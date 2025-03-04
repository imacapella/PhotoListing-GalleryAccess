import Foundation
import Photos
import SwiftUI

class PhotoLibraryViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var isLoading = false
    
    private let service = PhotoLibraryService.shared
    
    func sortAssets(_ assets: [PhotoAsset], by option: SortOption) -> [PhotoAsset] {
        switch option {
        case .date:
            return assets.sorted { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
        case .size:
            return assets.sorted { $0.pixelSize > $1.pixelSize }
        case .name:
            return assets.sorted { $0.id < $1.id }
        }
    }
    
    func requestAuthorization() {
        service.requestAuthorization { [weak self] isAuthorized in
            if isAuthorized {
                self?.fetchAssets()
            }
        }
    }
    
    func fetchAssets() {
        isLoading = true
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var newAssets: [PHAsset] = []
        fetchResult.enumerateObjects { (asset, _, _) in
            newAssets.append(asset)
        }
        
        DispatchQueue.main.async {
            self.assets = newAssets
            self.isLoading = false
        }
    }
    
    func deleteAsset(_ asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
        }) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.assets.removeAll { $0.localIdentifier == asset.localIdentifier }
                }
            }
        }
    }
    
    func findAndRemoveDuplicates() {
        // ... duplicate silme mantığı ...
    }
    
    func filterAssets(startDate: Date, endDate: Date, minimumSize: Double) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startDate as NSDate, endDate as NSDate)
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var filteredAssets: [PHAsset] = []
        fetchResult.enumerateObjects { (asset, _, _) in
            let sizeInMB = Double(asset.pixelWidth * asset.pixelHeight) * 3 / (1024 * 1024)
            if sizeInMB >= minimumSize {
                filteredAssets.append(asset)
            }
        }
        
        DispatchQueue.main.async {
            self.assets = filteredAssets
        }
    }
} 
