import SwiftUI
import UIKit

public struct ChatView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var attachedImages: [AttachedImage] = []
    
    @State private var isLoading = false
    @State private var showSettings = false
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAttachMenu = false
    
    @FocusState private var isInputFocused: Bool
    
    public init() {}
    
    public var body: some View {
        ZStack {
            SlateTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                
                Divider().background(SlateTheme.border)
                
                // Message List or Welcome View
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                welcomeHeroView
                            } else {
                                ForEach(messages) { msg in
                                    MessageBubbleView(message: msg, onRetry: {
                                        retryLastMessage()
                                    })
                                    .id(msg.id)
                                }
                            }
                        }
                        .padding(.vertical, 14)
                    }
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: messages.last?.text) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Bottom Input Area
                VStack(spacing: 6) {
                    // Attached images thumbnail strip
                    if !attachedImages.isEmpty {
                        attachedImagesPreviewStrip
                    }
                    
                    // Quick Action Study Chips
                    QuickPromptBar { prompt in
                        inputText = prompt
                        isInputFocused = true
                    }
                    
                    // Chat Input Bar
                    inputBar
                }
                .padding(.bottom, 6)
                .background(SlateTheme.surface)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(SlateTheme.border),
                    alignment: .top
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, onClearHistory: {
                messages.removeAll()
            })
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType) { pickedImage in
                let attached = AttachedImage(image: pickedImage)
                attachedImages.append(attached)
                Haptics.notify(.success)
            }
        }
        .actionSheet(isPresented: $showAttachMenu) {
            ActionSheet(
                title: Text("Прикрепить фото или задание"),
                buttons: [
                    .default(Text("Сделать фото (Камера)")) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            imagePickerSourceType = .camera
                            showImagePicker = true
                        }
                    },
                    .default(Text("Выбрать из галереи")) {
                        imagePickerSourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel(Text("Отмена"))
                ]
            )
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            // App Icon / Logo
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(SlateTheme.surfaceRaised)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(SlateTheme.border, lineWidth: 1)
                    )
                
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SlateTheme.geminiStarGradient)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Gemini Lite")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(SlateTheme.textPrimary)
                    
                    Text(settings.effectiveModel.replacingOccurrences(of: "gemini-", with: ""))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(SlateTheme.accentHover)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(SlateTheme.surfaceRaised)
                        .cornerRadius(6)
                }
                
                Text(settings.hasValidApiKey ? "Готов к работе" : "Требуется API ключ")
                    .font(.system(size: 11))
                    .foregroundColor(settings.hasValidApiKey ? SlateTheme.success : SlateTheme.warning)
            }
            
            Spacer()
            
            // Settings Button
            Button(action: {
                Haptics.play(.light)
                showSettings = true
            }) {
                ZStack {
                    Circle()
                        .fill(SlateTheme.surfaceRaised)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(SlateTheme.border, lineWidth: 1)
                        )
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SlateTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(SlateTheme.surface)
    }
    
    // MARK: - Welcome Hero View
    private var welcomeHeroView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)
            
            ZStack {
                Circle()
                    .fill(SlateTheme.surfaceRaised)
                    .frame(width: 84, height: 84)
                    .overlay(
                        Circle().stroke(SlateTheme.accent.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(SlateTheme.geminiStarGradient)
            }
            
            VStack(spacing: 6) {
                Text("Gemini для учебы и задач")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(SlateTheme.textPrimary)
                
                Text("Отправляйте фото примеров, конспектов\nили задавайте любые вопросы")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(SlateTheme.textSecondary)
            }
            
            if !settings.hasValidApiKey {
                Button(action: {
                    showSettings = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                        Text("Укажите API ключ в настройках")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SlateTheme.accent)
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            
            // Feature cards
            VStack(spacing: 10) {
                heroCard(
                    icon: "camera.viewfinder",
                    title: "Фото задач и формул",
                    desc: "Сделайте фото страницы учебника или тетради — Gemini решит всё по шагам."
                )
                heroCard(
                    icon: "character.book.closed.fill",
                    title: "Школьные и ВУЗ предметы",
                    desc: "Математика, физика, химия, языки, история, обществознание и программирование."
                )
                heroCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Конспекты и проверка",
                    desc: "Проверит ваше решение, найдет ошибку или составит краткую выжимку."
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            Spacer(minLength: 20)
        }
    }
    
    private func heroCard(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(SlateTheme.accentHover)
                .frame(width: 32)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SlateTheme.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(SlateTheme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(12)
        .background(SlateTheme.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Attached Images Preview Strip
    private var attachedImagesPreviewStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachedImages) { item in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: item.thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(SlateTheme.accent, lineWidth: 1.5)
                            )
                        
                        Button(action: {
                            Haptics.play(.light)
                            if let idx = attachedImages.firstIndex(where: { $0.id == item.id }) {
                                attachedImages.remove(at: idx)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "EF4444"))
                                .background(Circle().fill(Color.white).padding(2))
                        }
                        .offset(x: 6, y: -6)
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Chat Input Bar
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Attach / Camera Button
            Button(action: {
                Haptics.play(.light)
                showAttachMenu = true
            }) {
                ZStack {
                    Circle()
                        .fill(SlateTheme.surfaceInput)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle().stroke(SlateTheme.border, lineWidth: 1)
                        )
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 17))
                        .foregroundColor(attachedImages.isEmpty ? SlateTheme.textSecondary : SlateTheme.accentHover)
                }
            }
            
            // Text Input Box
            HStack(spacing: 6) {
                TextField("Задайте вопрос или отправьте фото...", text: $inputText)
                    .font(.system(size: 14))
                    .foregroundColor(SlateTheme.textPrimary)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }
                
                if !inputText.isEmpty {
                    Button(action: {
                        inputText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SlateTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(SlateTheme.surfaceInput)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isInputFocused ? SlateTheme.borderFocus : SlateTheme.border, lineWidth: 1)
            )
            
            // Send Button
            Button(action: {
                sendMessage()
            }) {
                ZStack {
                    Circle()
                        .fill(canSend ? SlateTheme.accent : SlateTheme.surfaceRaised)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle().stroke(canSend ? SlateTheme.accentHover : SlateTheme.border, lineWidth: 1)
                        )
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(canSend ? .white : SlateTheme.textTertiary)
                    }
                }
            }
            .disabled(!canSend || isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
    
    private var canSend: Bool {
        return (!inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachedImages.isEmpty)
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard canSend && !isLoading else { return }
        
        let promptToSend = inputText
        let imagesToSend = attachedImages
        
        // Reset input fields
        inputText = ""
        attachedImages = []
        isInputFocused = false
        Haptics.play(.medium)
        
        // Add user message
        let userMsg = ChatMessage(
            role: .user,
            text: promptToSend,
            images: imagesToSend
        )
        messages.append(userMsg)
        
        // Add pending model message
        let pendingId = UUID()
        let pendingMsg = ChatMessage(
            id: pendingId,
            role: .model,
            text: "",
            isPending: true
        )
        messages.append(pendingMsg)
        isLoading = true
        
        Task {
            do {
                let reply = try await GeminiService.shared.send(
                    prompt: promptToSend,
                    images: imagesToSend.map { $0.image },
                    chatHistory: messages.dropLast(), // exclude the pending message
                    settings: settings
                )
                
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == pendingId }) {
                        messages[index].text = reply
                        messages[index].isPending = false
                    }
                    isLoading = false
                    Haptics.notify(.success)
                }
            } catch {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == pendingId }) {
                        messages[index] = ChatMessage(
                            role: .error,
                            text: error.localizedDescription
                        )
                    }
                    isLoading = false
                    Haptics.notify(.error)
                }
            }
        }
    }
    
    private func retryLastMessage() {
        guard let lastUserMsg = messages.last(where: { $0.role == .user }) else { return }
        // Remove error message if any
        if let last = messages.last, last.role == .error {
            messages.removeLast()
        }
        
        let pendingId = UUID()
        let pendingMsg = ChatMessage(
            id: pendingId,
            role: .model,
            text: "",
            isPending: true
        )
        messages.append(pendingMsg)
        isLoading = true
        
        Task {
            do {
                let reply = try await GeminiService.shared.send(
                    prompt: lastUserMsg.text,
                    images: lastUserMsg.images.map { $0.image },
                    chatHistory: messages.dropLast(),
                    settings: settings
                )
                
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == pendingId }) {
                        messages[index].text = reply
                        messages[index].isPending = false
                    }
                    isLoading = false
                    Haptics.notify(.success)
                }
            } catch {
                await MainActor.run {
                    if let index = messages.firstIndex(where: { $0.id == pendingId }) {
                        messages[index] = ChatMessage(
                            role: .error,
                            text: error.localizedDescription
                        )
                    }
                    isLoading = false
                    Haptics.notify(.error)
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = messages.last?.id {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}
