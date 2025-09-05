import Foundation
import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

// MARK: - 相機 ViewModel
@MainActor
internal class CameraViewModel: ObservableObject {
    // MARK: - Properties
    @Published var capturedImage: UIImage?
    @Published var showImagePreview = false
    @Published var isSessionRunning = false
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var isFlashOn = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showPhotoLibrary = false
    
    // MARK: - Dependencies
    private let cameraManager: CameraManager
    
    // MARK: - Initialization
    init(cameraManager: CameraManager = CameraManager()) {
        self.cameraManager = cameraManager
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // 綁定 CameraManager 的狀態到 ViewModel
        cameraManager.$isSessionRunning
            .assign(to: &$isSessionRunning)
        
        cameraManager.$cameraPosition
            .assign(to: &$cameraPosition)
        
        cameraManager.$isFlashOn
            .assign(to: &$isFlashOn)
    }
    
    // MARK: - Camera Control Methods
    func startCameraSession() {
        // 檢查相機權限
        let authStatus = CameraManager.checkCameraPermission()
        
        switch authStatus {
        case .authorized:
            cameraManager.startSession()
            
        case .notDetermined:
            CameraManager.requestCameraPermission { [weak self] granted in
                if granted {
                    self?.cameraManager.startSession()
                } else {
                    self?.showCameraError("需要相機權限才能使用此功能")
                }
            }
            
        case .denied, .restricted:
            showCameraError("請在設定中允許相機權限")
            
        @unknown default:
            showCameraError("未知的相機權限狀態")
        }
    }
    
    func stopCameraSession() {
        cameraManager.stopSession()
    }
    
    func capturePhoto() {
        cameraManager.capturePhoto { [weak self] image in
            guard let self = self else { return }
            
            if let image = image {
                self.capturedImage = image
                self.showImagePreview = true
            } else {
                self.showCameraError("拍照失敗，請重試")
            }
        }
    }
    
    func switchCamera() {
        cameraManager.switchCamera()
    }
    
    func toggleFlash() {
        cameraManager.toggleFlash()
    }
    
    // MARK: - Photo Library Methods
    
    func selectPhotosFromLibrary(_ images: [UIImage]) {
        showPhotoLibrary = false
        
        if let firstImage = images.first {
            // 只取第一張照片
            capturedImage = firstImage
            showImagePreview = true
        }
    }
    
    // MARK: - Photo Preview Methods
    func sendPhoto(_ image: UIImage, completion: @escaping (UIImage) -> Void) {
        completion(image)
        resetToCamera()
    }
    
    
    func cancelPhotoPreview() {
        resetToCamera()
    }
    
    
    private func resetToCamera() {
        capturedImage = nil
        showImagePreview = false
    }
    
    // MARK: - Error Handling
    private func showCameraError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    
    // MARK: - Camera Manager Access
    var previewLayer: AVCaptureVideoPreviewLayer {
        return cameraManager.previewLayer
    }
    
    // MARK: - Cleanup
    deinit {
        // 在 deinit 中不能呼叫 main actor 方法，直接停止相機
        cameraManager.stopSession()
    }
}