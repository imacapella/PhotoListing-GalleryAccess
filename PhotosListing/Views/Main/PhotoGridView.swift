import SwiftUICore
import SwiftUI
import Photos

struct PhotoGridView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    let columns: [GridItem]
    
    private let imageSize = CGSize(width: 300, height: 300)
    
    var body: some View {
        ScrollView {
            photoGrid
            
            if viewModel.isLoading {
                loadingIndicator
            }
        }
    }
    
    private var photoGrid: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(viewModel.sortedAssets, id: \.localIdentifier) { asset in
                photoGridItem(for: asset)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    private func photoGridItem(for asset: PHAsset) -> some View {
        PhotoGridItem(asset: asset, onDelete: {
            viewModel.deleteAsset(asset)
        })
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if asset == viewModel.sortedAssets.last {
                viewModel.fetchNextPage()
            }
        }
    }
    
    private var loadingIndicator: some View {
        ProgressView()
            .padding()
    }
} 
