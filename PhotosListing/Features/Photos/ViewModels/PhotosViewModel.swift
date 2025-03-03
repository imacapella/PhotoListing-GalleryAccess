import Photos
import SwiftUI

@MainActor
final class PhotosViewModel: ObservableObject {
    @Published private(set) var assets: [PhotoAsset] = []
    @Published var selectedSortOption: SortOption = .date
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = PhotoLibraryService.shared
    
    var sortedAssets: [PhotoAsset] {
        switch selectedSortOption {
        case .date:
            return assets.sorted { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
        case .size:
            return assets.sorted { $0.pixelSize > $1.pixelSize }
        case .name:
            return assets.sorted { $0.id < $1.id }
        }
    }
    
    func loadAssets() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let isAuthorized = await service.requestAuthorization()
                guard isAuthorized else {
                    errorMessage = "Fotoğraf erişim izni gerekli"
                    return
                }
                
                assets = await service.fetchAssets()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func filterAssets(startDate: Date, endDate: Date, minimumSize: Double) async {
        isLoading = true
        defer { isLoading = false }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startDate as NSDate, endDate as NSDate)
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let filteredAssets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))
            .map(PhotoAsset.init)
            .filter { asset in
                let sizeInMB = Double(asset.pixelSize) * 3 / (1024 * 1024)
                return sizeInMB >= minimumSize
            }
        
        self.assets = filteredAssets
    }
    
    func findAndRemoveDuplicates() async {
        // Duplicate bulma mantığı burada olacak
        // Şimdilik boş bırakıyoruz, daha sonra implement edeceğiz
    }
} 