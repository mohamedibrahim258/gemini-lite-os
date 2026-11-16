import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    public var onClearHistory: () -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showApiKey = false
    @State private var isTestingKey = false
    @State private var testResult: String? = nil
    @State private var testSuccess = false
    @State private var showClearConfirm = false
    
    public init(settings: AppSettings, onClearHistory: @escaping () -> Void) {
        self.settings = settings
        self.onClearHistory = onClearHistory
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SlateTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        apiKeySection
                        modelSection
                        systemPromptSection
                        generationConfigSection
                        dataManagementSection
                        appInfoSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SlateTheme.accentHover)
                        Text("Настройки")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(SlateTheme.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        Haptics.play(.light)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SlateTheme.accentHover)
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert(isPresented: $showClearConfirm) {
            Alert(
                title: Text("Очистить историю?"),
                message: Text("Все сообщения текущего диалога будут удалены."),
                primaryButton: .destructive(Text("Очистить")) {
                    Haptics.notify(.warning)
                    onClearHistory()
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
    }
    
    // MARK: - API Key Section
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Google Gemini API Ключ", systemImage: "key.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SlateTheme.textPrimary)
                Spacer()
                Button(action: {
                    showApiKey.toggle()
                }) {
                    Image(systemName: showApiKey ? "eye.slash" : "eye")
                        .foregroundColor(SlateTheme.textSecondary)
                }
            }
            
            HStack(spacing: 8) {
                if showApiKey {
                    TextField("AIzaSy...", text: $settings.apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(SlateTheme.textPrimary)
                } else {
                    SecureField("Вставьте ваш API ключ...", text: $settings.apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(SlateTheme.textPrimary)
                }
                
                if !settings.apiKey.isEmpty {
                    Button(action: {
                        settings.apiKey = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(SlateTheme.textTertiary)
                    }
                }
            }
            .padding(12)
            .background(SlateTheme.surfaceInput)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(settings.hasValidApiKey ? SlateTheme.border : SlateTheme.accent.opacity(0.5), lineWidth: 1)
            )
            
            // Test Key Button & Link
            HStack {
                Button(action: testApiKeyAction) {
                    HStack(spacing: 4) {
                        if isTestingKey {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "bolt.fill")
                        }
                        Text(isTestingKey ? "Проверка..." : "Проверить ключ")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SlateTheme.accent)
                    .cornerRadius(8)
                }
                .disabled(isTestingKey || settings.apiKey.isEmpty)
                .opacity(settings.apiKey.isEmpty ? 0.5 : 1.0)
                
                Spacer()
                
                Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                    HStack(spacing: 4) {
                        Text("Получить ключ бесплатно")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SlateTheme.accentHover)
                }
            }
            
            if let result = testResult {
                Text(result)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(testSuccess ? SlateTheme.success : SlateTheme.error)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(SlateTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Model Selection
    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Модель нейросети", systemImage: "cpu.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SlateTheme.textPrimary)
                Spacer()
                Text(settings.effectiveModel)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(SlateTheme.accentHover)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(SlateTheme.surfaceRaised)
                    .cornerRadius(6)
            }
            
            // Preset Buttons
            VStack(spacing: 8) {
                ForEach(AppSettings.availableModels) { model in
                    Button(action: {
                        Haptics.play(.light)
                        settings.useCustomModel = false
                        settings.selectedModel = model.id
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(model.displayName)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(SlateTheme.textPrimary)
                                    
                                    Text(model.badge)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(SlateTheme.accentHover)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(SlateTheme.accent.opacity(0.15))
                                        .cornerRadius(4)
                                }
                                Text(model.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(SlateTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if !settings.useCustomModel && settings.selectedModel == model.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(SlateTheme.accent)
                                    .font(.system(size: 18))
                            } else {
                                Circle()
                                    .stroke(SlateTheme.border, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                            }
                        }
                        .padding(12)
                        .background(!settings.useCustomModel && settings.selectedModel == model.id ? SlateTheme.surfaceRaised : SlateTheme.surfaceInput)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(!settings.useCustomModel && settings.selectedModel == model.id ? SlateTheme.accent : SlateTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
            
            // Custom Model Option
            Toggle(isOn: $settings.useCustomModel) {
                Text("Ввести модель вручную")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(SlateTheme.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: SlateTheme.accent))
            .padding(.top, 4)
            
            if settings.useCustomModel {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Например: gemini-2.5-flash", text: $settings.customModel)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(SlateTheme.textPrimary)
                        .padding(10)
                        .background(SlateTheme.surfaceInput)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(SlateTheme.accent, lineWidth: 1)
                        )
                    
                    Text("Можно указать любую экспериментальную или кастомную модель Google.")
                        .font(.system(size: 11))
                        .foregroundColor(SlateTheme.textTertiary)
                }
            }
        }
        .padding(14)
        .background(SlateTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - System Prompt Section
    private var systemPromptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Системный промпт (Инструкция)", systemImage: "theatermasks.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SlateTheme.textPrimary)
                Spacer()
                if !settings.systemPrompt.isEmpty {
                    Button("Очистить") {
                        Haptics.play(.light)
                        settings.systemPrompt = ""
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SlateTheme.error)
                }
            }
            
            Text("Задает роль, тон и стиль ответов нейросети. Можно оставить пустым.")
                .font(.system(size: 11))
                .foregroundColor(SlateTheme.textSecondary)
            
            // Preset Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AppSettings.promptPresets) { preset in
                        Button(action: {
                            Haptics.play(.light)
                            settings.systemPrompt = preset.prompt
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 10))
                                Text(preset.title)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(settings.systemPrompt == preset.prompt ? SlateTheme.accent : SlateTheme.surfaceRaised)
                            .foregroundColor(settings.systemPrompt == preset.prompt ? .white : SlateTheme.textPrimary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(SlateTheme.border, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Text Editor for System Prompt
            ZStack(alignment: .topLeading) {
                if settings.systemPrompt.isEmpty {
                    Text("Без системной инструкции (нейросеть работает в стандартном режиме)...")
                        .font(.system(size: 13))
                        .foregroundColor(SlateTheme.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $settings.systemPrompt)
                    .font(.system(size: 13))
                    .foregroundColor(SlateTheme.textPrimary)
                    .lineSpacing(3)
                    .frame(minHeight: 90)
                    .padding(6)
                    .background(Color.clear)
            }
            .background(SlateTheme.surfaceInput)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SlateTheme.border, lineWidth: 1)
            )
        }
        .padding(14)
        .background(SlateTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Generation Config
    private var generationConfigSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Температура генерации", systemImage: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SlateTheme.textPrimary)
                Spacer()
                Text(String(format: "%.1f", settings.temperature))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(SlateTheme.accentHover)
            }
            
            Slider(value: $settings.temperature, in: 0.0...1.0, step: 0.1)
                .accentColor(SlateTheme.accent)
            
            HStack {
                Text("0.0 (Точно, для формул)")
                    .font(.system(size: 10))
                    .foregroundColor(SlateTheme.textTertiary)
                Spacer()
                Text("1.0 (Креативно, эссе)")
                    .font(.system(size: 10))
                    .foregroundColor(SlateTheme.textTertiary)
            }
        }
        .padding(14)
        .background(SlateTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Data Management
    private var dataManagementSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                showClearConfirm = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Очистить историю диалога")
                    Spacer()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(SlateTheme.error)
                .padding(12)
                .background(SlateTheme.surfaceRaised)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SlateTheme.error.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(14)
        .background(SlateTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - App Info
    private var appInfoSection: some View {
        VStack(spacing: 6) {
            Text("Gemini Lite v1.0.0")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(SlateTheme.textSecondary)
            Text("Оптимизировано для iPhone 7 Plus • iOS 15.8.7")
                .font(.system(size: 11))
                .foregroundColor(SlateTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    private func testApiKeyAction() {
        isTestingKey = true
        testResult = nil
        Haptics.play(.medium)
        
        Task {
            do {
                let success = try await GeminiService.shared.testApiKey(
                    apiKey: settings.apiKey,
                    model: settings.effectiveModel
                )
                await MainActor.run {
                    self.isTestingKey = false
                    self.testSuccess = success
                    self.testResult = "✓ Ключ активен! Соединение с Gemini успешно."
                    Haptics.notify(.success)
                }
            } catch {
                await MainActor.run {
                    self.isTestingKey = false
                    self.testSuccess = false
                    self.testResult = "✗ Ошибка проверки: \(error.localizedDescription)"
                    Haptics.notify(.error)
                }
            }
        }
    }
}
