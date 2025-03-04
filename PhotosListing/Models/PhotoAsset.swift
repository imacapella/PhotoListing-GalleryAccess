import Photos
struct PhotoAsset: Identifiable {
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
} 
