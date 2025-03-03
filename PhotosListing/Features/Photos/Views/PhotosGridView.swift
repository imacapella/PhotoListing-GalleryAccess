import SwiftUI
import Photos

struct PhotosGridView: View {
    @StateObject private var viewModel = PhotosViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingFilterSheet = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    photoGrid
                }
            }
            .navigationTitle("Fotoğraflar")
            .toolbar { toolbarItems }
            .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear { viewModel.loadAssets() }
        .sheet(isPresented: $showingFilterSheet) {
            PhotoFilterView(viewModel: viewModel)
        }
    }
    
    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(viewModel.sortedAssets) { asset in
                    PhotoGridItemView(asset: asset)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                settingsMenu
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                sortMenu
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                filterButton
            }
        }
    }
    
    private var settingsMenu: some View {
        Menu {
            Button {
                isDarkMode.toggle()
            } label: {
                Label(
                    isDarkMode ? "Light Tema" : "Dark Tema",
                    systemImage: isDarkMode ? "sun.max.fill" : "moon.fill"
                )
            }
            
            Button {
                Task {
                    await viewModel.findAndRemoveDuplicates()
                }
            } label: {
                Label("Duplicate Sil", systemImage: "doc.on.doc")
            }
        } label: {
            Image(systemName: "gear")
        }
    }
    
    private var sortMenu: some View {
        Menu {
            Picker("Sıralama", selection: $viewModel.selectedSortOption) {
                ForEach(SortOption.allCases) { option in
                    Label(option.rawValue, systemImage: option.icon)
                        .tag(option)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
    }
} 