import SwiftUI

internal struct MessageInputView: View {
    @Binding var inputText: String
    @Binding var showPhotoButtons: Bool
    @Binding var showCameraInterface: Bool
    @Binding var showPhotoLibrary: Bool
    @Binding var selectedImage: UIImage?
    @FocusState.Binding var isTextFieldFocused: Bool
    
    let onSend: () -> Void
    let onImageSelected: (UIImage) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(alignment: .bottom, spacing: 8) {
                // 左側按鈕區域
                buttonArea
                
                // 輸入框
                textInputField
                
                // 發送按鈕
                sendButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(minHeight: 60)
        .background(Color.appBackgroundGreen)
        .fullScreenCover(isPresented: $showCameraInterface) {
            CustomCameraView(
                isPresented: $showCameraInterface,
                capturedImage: $selectedImage
            )
            .onDisappear {
                if let image = selectedImage {
                    onImageSelected(image)
                    selectedImage = nil
                }
            }
        }
        .fullScreenCover(isPresented: $showPhotoLibrary) {
            PhotoLibraryPicker(
                isPresented: $showPhotoLibrary,
                onImagesSelected: { images in
                    showPhotoLibrary = false
                    for image in images {
                        onImageSelected(image)
                    }
                }
            )
        }
    }
    
    // MARK: - 按鈕區域
    private var buttonArea: some View {
        HStack(spacing: 8) {
            // 加號按鈕
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showPhotoButtons.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.appCardGreen)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: showPhotoButtons ? "xmark" : "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(showPhotoButtons ? 45 : 0))
                }
            }
            
            // 相機和照片按鈕
            if showPhotoButtons {
                photoButtons
            }
        }
    }
    
    // MARK: - 照片按鈕組
    private var photoButtons: some View {
        HStack(spacing: 8) {
            // 相機按鈕
            Button(action: {
                showCameraInterface = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showPhotoButtons = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0x32/255, green: 0xCD/255, blue: 0x32/255).opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.appPrimaryGreen)
                }
            }
            
            // 照片按鈕
            Button(action: {
                showPhotoLibrary = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showPhotoButtons = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0x32/255, green: 0xCD/255, blue: 0x32/255).opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.appPrimaryGreen)
                }
            }
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .leading)),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    // MARK: - 文字輸入框
    private var textInputField: some View {
        View.textFieldCompat("輸入訊息...", text: $inputText, axis: .vertical)
            .textFieldStyle(PlainTextFieldStyle())
            .focused($isTextFieldFocused)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appLightCardGreen)
            )
            .lineLimitCompat(1...5)
            .onTapGesture {
                if showPhotoButtons {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showPhotoButtons = false
                    }
                }
            }
    }
    
    // MARK: - 發送按鈕
    private var sendButton: some View {
        Button(action: onSend) {
            ZStack {
                Circle()
                    .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                          Color.appCardGreen : Color(red: 0x32/255, green: 0xCD/255, blue: 0x32/255))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

#Preview {
    @State var inputText = ""
    @State var showPhotoButtons = false
    @State var showCameraInterface = false
    @State var showPhotoLibrary = false
    @State var selectedImage: UIImage? = nil
    @FocusState var isTextFieldFocused: Bool
    
    return MessageInputView(
        inputText: $inputText,
        showPhotoButtons: $showPhotoButtons,
        showCameraInterface: $showCameraInterface,
        showPhotoLibrary: $showPhotoLibrary,
        selectedImage: $selectedImage,
        isTextFieldFocused: $isTextFieldFocused,
        onSend: {
            print("發送訊息: \(inputText)")
            inputText = ""
        },
        onImageSelected: { image in
            print("選擇了圖片")
        }
    )
    .padding()
}