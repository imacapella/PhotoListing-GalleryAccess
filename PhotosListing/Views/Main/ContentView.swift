import SwiftUICore
import SwiftUI
import Photos

// Eğer FilterView ayrı bir modülde ise:
// import PhotosListingFilter // veya FilterView'ın bulunduğu modül adı

struct ContentView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @State private var showingFilterSheet = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 24) {
                    ForEach(viewModel.sortedAssets, id: \.localIdentifier) { asset in
                        PhotoGridItem(asset: asset)
                            .aspectRatio(1, contentMode: .fit)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteAsset(asset)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                            .onAppear {
                                if asset == viewModel.sortedAssets.last {
                                    viewModel.fetchNextPage()
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Fotoğraflar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                            viewModel.findAndRemoveDuplicates()
                        } label: {
                            Label("Duplicate Sil", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sıralama", selection: $viewModel.selectedSortOption) {
                            Label("Tarih", systemImage: "calendar").tag(SortOption.date)
                            Label("Boyut", systemImage: "photo").tag(SortOption.size)
                            Label("İsim", systemImage: "textformat").tag(SortOption.name)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.requestAuthorization()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
} 
