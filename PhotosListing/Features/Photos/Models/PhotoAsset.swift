import Photos
import Foundation

struct PhotoAsset: Identifiable, Equatable, Hashable {
    let asset: PHAsset
    let id: String
    
    init(asset: PHAsset) {
        self.asset = asset
        self.id = asset.localIdentifier
    }
    
    var pixelSize: Int {
        asset.pixelWidth * asset.pixelHeight
    }
    
    var creationDate: Date? {
        asset.creationDate
    }
    
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 