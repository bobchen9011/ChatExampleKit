import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

// MARK: - 相機預覽組件
#if canImport(AVFoundation) && canImport(UIKit)
internal struct CameraPreviewComponent: UIViewRepresentable {
    let viewModel: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        DispatchQueue.main.async {
            let previewLayer = viewModel.previewLayer
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
        DispatchQueue.main.async {
            if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                layer.frame = uiView.bounds
            }
        }
    }
}
#endif

#Preview {
    VStack {
        Text("Camera Preview Component")
            .font(.title)
            .padding()
        
        Text("此組件需要在真實設備上運行")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
        
        // 預覽中顯示佔位符而不是真實的相機組件
        Rectangle()
            .fill(Color.black)
            .frame(height: 400)
            .cornerRadius(12)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("相機預覽")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
            .padding()
    }
}

