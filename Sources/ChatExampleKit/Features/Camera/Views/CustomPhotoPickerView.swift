import SwiftUI
#if canImport(Photos)
import Photos
#endif

#if canImport(Photos) && canImport(UIKit)
internal struct CustomPhotoPickerView: View {
    @Binding var isPresented: Bool
    let onImagesSelected: ([UIImage]) -> Void
    
    @StateObject private var viewModel = PhotoPickerViewModel()
    @State private var selectedAssets: Set<String> = []
    @State private var showPhotoPreview = false
    @State private var previewAsset: PHAsset?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 照片網格
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.photos, id: \.localIdentifier) { asset in
                                PhotoThumbnailView(
                                    asset: asset,
                                    isSelected: selectedAssets.contains(asset.localIdentifier),
                                    onTap: {
                                        toggleSelection(for: asset)
                                    },
                                    onLongPress: {
                                        previewAsset = asset
                                        showPhotoPreview = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    
                    // 底部按鈕區域
                    bottomControlsView
                }
            }
            .navigationTitle("選擇照片")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Text("\(selectedAssets.count) 已選擇")
                    .foregroundColor(.white)
            )
        }
        .onAppear {
            viewModel.requestPhotosAccess()
        }
        .fullScreenCover(isPresented: $showPhotoPreview) {
            if let asset = previewAsset {
                PhotoPreviewCropView(
                    asset: asset,
                    isPresented: $showPhotoPreview,
                    onImageSelected: { croppedImage in
                        onImagesSelected([croppedImage])
                        isPresented = false
                    }
                )
            }
        }
    }
    
    private var bottomControlsView: some View {
        VStack(spacing: 0) {
            // 發送按鈕
            Button(action: {
                sendSelectedPhotos()
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedAssets.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(25)
            }
            .disabled(selectedAssets.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.black)
        }
    }
    
    private func toggleSelection(for asset: PHAsset) {
        if selectedAssets.contains(asset.localIdentifier) {
            selectedAssets.remove(asset.localIdentifier)
        } else {
            selectedAssets.insert(asset.localIdentifier)
        }
    }
    
    private func sendSelectedPhotos() {
        let selectedPhotos = viewModel.photos.filter { selectedAssets.contains($0.localIdentifier) }
        
        viewModel.loadImages(from: selectedPhotos) { images in
            DispatchQueue.main.async {
                onImagesSelected(images)
                isPresented = false
            }
        }
    }
}

internal struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        ZStack {
            PhotoAsyncImage(asset: asset, targetSize: CGSize(width: 200, height: 200)) { image in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(height: 100)
            .clipped()
            
            // 選擇狀態覆蓋層
            if isSelected {
                Color.blue.opacity(0.3)
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .padding(8)
                    }
                    Spacer()
                }
            } else {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .padding(8)
                    }
                    Spacer()
                }
            }
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

internal struct PhotoAsyncImage<Content: View>: View {
    let asset: PHAsset
    let targetSize: CGSize
    let content: (UIImage) -> Content
    
    @State private var image: UIImage?
    
    init(asset: PHAsset, targetSize: CGSize, @ViewBuilder content: @escaping (UIImage) -> Content) {
        self.asset = asset
        self.targetSize = targetSize
        self.content = content
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(image)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        ) { result, _ in
            DispatchQueue.main.async {
                self.image = result
            }
        }
    }
}

internal class PhotoPickerViewModel: ObservableObject {
    @Published var photos: [PHAsset] = []
    
    func requestPhotosAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    self.fetchPhotos()
                }
            }
        }
    }
    
    private func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        DispatchQueue.main.async {
            self.photos = assets
        }
    }
    
    func loadImages(from assets: [PHAsset], completion: @escaping ([UIImage]) -> Void) {
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        var images: [UIImage] = []
        let group = DispatchGroup()
        
        for asset in assets {
            group.enter()
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 1000, height: 1000),
                contentMode: .aspectFill,
                options: requestOptions
            ) { result, _ in
                if let image = result {
                    images.append(image)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(images)
        }
    }
}

#Preview {
    // 預覽中顯示佔位符而不是真實的照片選擇器
    VStack {
        Text("Custom Photo Picker View")
            .font(.title)
            .padding()
        
        Text("此組件需要照片庫權限")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
        
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("照片庫選擇器")
                .font(.headline)
            
            Text("在實際應用中運行以查看完整功能")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        
        Spacer()
    }
    .padding()
}
#endif

