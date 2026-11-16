import SwiftUI
import Combine

public struct ModelOption: Identifiable, Hashable {
    public let id: String
    public let displayName: String
    public let description: String
    public let badge: String
}

public struct SystemPromptPreset: Identifiable {
    public let id: String
    public let title: String
    public let icon: String
    public let prompt: String
}

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    // Available Preset Models
    public static let availableModels: [ModelOption] = [
        ModelOption(
            id: "gemini-2.0-flash",
            displayName: "Gemini 2.0 Flash",
            description: "Самый быстрый и умный, идеален для задач и уроков",
            badge: "NEW"
        ),
        ModelOption(
            id: "gemini-2.0-flash-lite",
            displayName: "Gemini 2.0 Flash Lite",
            description: "Мгновенные ответы, экономия трафика",
            badge: "LITE"
        ),
        ModelOption(
            id: "gemini-1.5-flash",
            displayName: "Gemini 1.5 Flash",
            description: "Проверенная стабильная модель общего назначения",
            badge: "FAST"
        ),
        ModelOption(
            id: "gemini-1.5-pro",
            displayName: "Gemini 1.5 Pro",
            description: "Глубокий анализ сложных формул, эссе и олимпиад",
            badge: "PRO"
        )
    ]
    
    // System Prompt Presets
    public static let promptPresets: [SystemPromptPreset] = [
        SystemPromptPreset(
            id: "tutor",
            title: "Умный Репетитор",
            icon: "graduationcap.fill",
            prompt: "Ты опытный, внимательный персональный репетитор по всем школьным и университетским предметам. Твоя задача: понятно, наглядно и пошагово разобрать задачу или тему. При решении задач с фото: 1) Сформулируй кратко дано/условие; 2) Опиши используемые формулы и правила; 3) По шагам распиши ход вычислений; 4) Выдели жирным итоговый ответ. Поощряй понимание материала."
        ),
        SystemPromptPreset(
            id: "check",
            title: "Проверка решений",
            icon: "checkmark.seal.fill",
            prompt: "Ты строгий и добросовестный проверяющий преподаватель. Внимательно проанализируй присланное решение или текст. Если есть ошибка, укажи точное место ошибки, объясни почему это неверно и покажи правильный вариант."
        ),
        SystemPromptPreset(
            id: "summary",
            title: "Краткий конспект",
            icon: "doc.text.fill",
            prompt: "Ты специалист по структурированию учебного материала. Сделай из присланного текста или фото лекции четкий конспект: ключевые термины, тезисы в виде маркеров и списков, важные формулы/даты. Без лишней воды."
        ),
        SystemPromptPreset(
            id: "coding",
            title: "IT-Ментор & Код",
            icon: "chevron.left.forwardslash.chevron.right",
            prompt: "Ты Senior-разработчик и преподаватель информатики. Пиши чистый, читаемый код с понятными комментариями на русском языке. Объясняй логику алгоритма построчно и предлагай оптимальные решения."
        ),
        SystemPromptPreset(
            id: "empty",
            title: "Без инструкций",
            icon: "circle.slash",
            prompt: ""
        )
    ]
    
    // Keys
    private enum Keys {
        static let apiKey = "gemini_api_key"
        static let selectedModel = "gemini_selected_model"
        static let customModel = "gemini_custom_model"
        static let useCustomModel = "gemini_use_custom_model"
        static let systemPrompt = "gemini_system_prompt"
        static let temperature = "gemini_temperature"
    }
    
    // Published Properties
    @Published public var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Keys.apiKey) }
    }
    
    @Published public var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: Keys.selectedModel) }
    }
    
    @Published public var customModel: String {
        didSet { UserDefaults.standard.set(customModel, forKey: Keys.customModel) }
    }
    
    @Published public var useCustomModel: Bool {
        didSet { UserDefaults.standard.set(useCustomModel, forKey: Keys.useCustomModel) }
    }
    
    @Published public var systemPrompt: String {
        didSet { UserDefaults.standard.set(systemPrompt, forKey: Keys.systemPrompt) }
    }
    
    @Published public var temperature: Double {
        didSet { UserDefaults.standard.set(temperature, forKey: Keys.temperature) }
    }
    
    public init() {
        self.apiKey = UserDefaults.standard.string(forKey: Keys.apiKey) ?? ""
        self.selectedModel = UserDefaults.standard.string(forKey: Keys.selectedModel) ?? "gemini-2.0-flash"
        self.customModel = UserDefaults.standard.string(forKey: Keys.customModel) ?? ""
        self.useCustomModel = UserDefaults.standard.bool(forKey: Keys.useCustomModel)
        self.systemPrompt = UserDefaults.standard.string(forKey: Keys.systemPrompt) ?? AppSettings.promptPresets[0].prompt
        
        let savedTemp = UserDefaults.standard.double(forKey: Keys.temperature)
        self.temperature = savedTemp > 0 ? savedTemp : 0.7
    }
    
    public var effectiveModel: String {
        if useCustomModel && !customModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customModel.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedModel
    }
    
    public var hasValidApiKey: Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count > 10
    }
}
