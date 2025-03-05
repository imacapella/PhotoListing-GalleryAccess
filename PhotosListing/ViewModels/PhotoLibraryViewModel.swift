import Foundation
import Photos
import SwiftUI

class PhotoLibraryViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var isLoading = false
    @Published var selectedSortOption: SortOption = .date
    @Published var assetSizes: [String: Double] = [:] // Dosya boyutlarını cache'lemek için
    
    private let service = PhotoLibraryService.shared
    private var currentPage = 0
    private let pageSize = 20 // Her sayfada 20 görsel
    private var hasMorePhotos = true
    
    var sortedAssets: [PHAsset] {
        switch selectedSortOption {
        case .date:
            return assets.sorted { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
        case .size:
            return assets.sorted { asset1, asset2 in
                let size1 = assetSizes[asset1.localIdentifier] ?? 0
                let size2 = assetSizes[asset2.localIdentifier] ?? 0
                return size1 > size2
            }
        case .name:
            return assets.sorted { $0.localIdentifier < $1.localIdentifier }
        }
    }
    
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
                self?.fetchInitialAssets()
            }
        }
    }
    
    func fetchInitialAssets() {
        currentPage = 0
        assets.removeAll()
        hasMorePhotos = true
        fetchNextPage()
    }
    
    func fetchNextPage() {
        guard !isLoading && hasMorePhotos else { return }
        
        isLoading = true
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let startIndex = currentPage * pageSize
        
        guard startIndex < fetchResult.count else {
            hasMorePhotos = false
            isLoading = false
            return
        }
        
        let endIndex = min(startIndex + pageSize, fetchResult.count)
        var newAssets: [PHAsset] = []
        
        let dispatchGroup = DispatchGroup()
        
        for index in startIndex..<endIndex {
            let asset = fetchResult.object(at: index)
            newAssets.append(asset)
            
            // Her asset için boyut hesaplama
            dispatchGroup.enter()
            calculateAssetSize(asset) { [weak self] size in
                self?.assetSizes[asset.localIdentifier] = size
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.assets.append(contentsOf: newAssets)
            self?.currentPage += 1
            self?.isLoading = false
            self?.hasMorePhotos = endIndex < fetchResult.count
            self?.objectWillChange.send() // UI'ı güncelle
        }
    }
    
    private func calculateAssetSize(_ asset: PHAsset, completion: @escaping (Double) -> Void) {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                let sizeInMB = Double(unsignedInt64) / (1024 * 1024)
                completion(sizeInMB)
            } else {
                // Dosya boyutu alınamazsa piksel boyutundan tahmin et
                let pixelSize = asset.pixelWidth * asset.pixelHeight
                let estimatedSizeInMB = Double(pixelSize) * 3 / (1024 * 1024)
                completion(estimatedSizeInMB)
            }
        } else {
            completion(0)
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
        isLoading = true
        
        let fetchOptions = PHFetchOptions()
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let endOfEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", 
                                           startOfStartDate as NSDate, 
                                           endOfEndDate as NSDate)
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var filteredAssets: [PHAsset] = []
        let dispatchGroup = DispatchGroup()
        
        fetchResult.enumerateObjects { [weak self] (asset, _, _) in
            dispatchGroup.enter()
            self?.calculateAssetSize(asset) { size in
                if size >= minimumSize {
                    filteredAssets.append(asset)
                    self?.assetSizes[asset.localIdentifier] = size
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.assets = filteredAssets
            self?.isLoading = false
            self?.objectWillChange.send()
        }
    }
} 
