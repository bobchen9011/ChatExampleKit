import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 相機管理器
internal class CameraManager: NSObject, ObservableObject {
    // MARK: - Properties
    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    @Published var isFlashOn = false
    @Published var isSessionRunning = false
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    
    // MARK: - Callbacks
    private var photoCaptureCompletionHandler: ((UIImage?) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCamera()
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession.sessionPreset = .photo
        previewLayer.session = captureSession
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("❌ 無法設置相機")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            videoDeviceInput = input
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }
    
    // MARK: - Session Control
    func startSession() {
        guard !captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
            
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Photo Capture
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCaptureCompletionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Camera Controls
    func switchCamera() {
        guard let currentInput = videoDeviceInput else { return }
        
        let currentPosition = currentInput.device.position
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            print("❌ 無法切換相機")
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)
        
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
            videoDeviceInput = newInput
            cameraPosition = newPosition
        } else {
            // 如果失敗，恢復原來的輸入
            captureSession.addInput(currentInput)
        }
        
        captureSession.commitConfiguration()
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    // MARK: - Camera Authorization
    static func checkCameraPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            photoCaptureCompletionHandler = nil
        }
        
        if let error = error {
            print("❌ 拍照錯誤: \(error.localizedDescription)")
            photoCaptureCompletionHandler?(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ 無法處理照片數據")
            photoCaptureCompletionHandler?(nil)
            return
        }
        
        print("✅ 照片拍攝成功，尺寸: \(image.size)")
        photoCaptureCompletionHandler?(image)
    }
}