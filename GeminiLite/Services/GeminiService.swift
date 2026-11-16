import Foundation
import UIKit

public enum GeminiServiceError: LocalizedError {
    case missingApiKey
    case invalidURL
    case networkError(String)
    case apiError(code: Int, message: String)
    case emptyResponse
    
    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Пожалуйста, укажите ваш Google Gemini API ключ в настройках (иконка ⚙️ вверху справа)."
        case .invalidURL:
            return "Не удалось сформировать адрес запроса к Gemini API."
        case .networkError(let details):
            return "Ошибка сети: \(details). Проверьте подключение к интернету или работу VPN/прокси."
        case .apiError(let code, let msg):
            if code == 400 && msg.contains("API key not valid") {
                return "Неверный API ключ (код 400). Проверьте правильность ключа в настройках."
            } else if code == 429 {
                return "Превышен лимит запросов (код 429). Подождите минуту перед следующим вопросом."
            } else if code == 404 {
                return "Модель не найдена (код 404). Проверьте название модели в настройках."
            }
            return "Ошибка Gemini API (код \(code)): \(msg)"
        case .emptyResponse:
            return "Модель вернула пустой ответ. Попробуйте переформулировать запрос."
        }
    }
}

public final class GeminiService {
    public static let shared = GeminiService()
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    private init() {}
    
    public func send(
        prompt: String,
        images: [UIImage],
        chatHistory: [ChatMessage],
        settings: AppSettings
    ) async throws -> String {
        let trimmedKey = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw GeminiServiceError.missingApiKey
        }
        
        let model = settings.effectiveModel
        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(trimmedKey)") else {
            throw GeminiServiceError.invalidURL
        }
        
        // Build conversation turns
        var contents: [GeminiContent] = []
        
        // Take recent history (up to last 10 messages for context, excluding error messages)
        let validHistory = chatHistory.filter { $0.role == .user || $0.role == .model }
        let recentHistory = validHistory.suffix(10)
        
        for msg in recentHistory {
            if msg.role == .user {
                var parts: [GeminiPart] = []
                if !msg.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parts.append(.text(msg.text))
                }
                for imgItem in msg.images {
                    if let base64 = compressAndEncode(image: imgItem.image) {
                        parts.append(.inlineData(mimeType: "image/jpeg", data: base64))
                    }
                }
                if !parts.isEmpty {
                    contents.append(GeminiContent(role: "user", parts: parts))
                }
            } else if msg.role == .model && !msg.text.isEmpty {
                contents.append(GeminiContent(role: "model", parts: [.text(msg.text)]))
            }
        }
        
        // Add current user message
        var currentParts: [GeminiPart] = []
        let actualPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (images.isEmpty ? "Привет!" : "Пожалуйста, подробно разбери и реши задание на прикрепленном изображении. Объясни решение по шагам.")
            : prompt
            
        currentParts.append(.text(actualPrompt))
        
        for img in images {
            if let base64 = compressAndEncode(image: img) {
                currentParts.append(.inlineData(mimeType: "image/jpeg", data: base64))
            }
        }
        
        contents.append(GeminiContent(role: "user", parts: currentParts))
        
        // System instruction (only if not empty)
        var systemInstruction: GeminiSystemInstruction? = nil
        let trimmedSystemPrompt = settings.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSystemPrompt.isEmpty {
            systemInstruction = GeminiSystemInstruction(text: trimmedSystemPrompt)
        }
        
        let config = GeminiGenerationConfig(temperature: settings.temperature)
        let requestBody = GeminiRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: config
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiServiceError.networkError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.networkError("Неверный ответ сервера")
        }
        
        if httpResponse.statusCode != 200 {
            if let errResp = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let err = errResp.error {
                throw GeminiServiceError.apiError(
                    code: err.code ?? httpResponse.statusCode,
                    message: err.message ?? "Неизвестная ошибка"
                )
            } else {
                let rawBody = String(data: data, encoding: .utf8) ?? ""
                throw GeminiServiceError.apiError(
                    code: httpResponse.statusCode,
                    message: rawBody.isEmpty ? "Код статуса: \(httpResponse.statusCode)" : rawBody
                )
            }
        }
        
        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw GeminiServiceError.networkError("Ошибка разбора ответа: \(error.localizedDescription)")
        }
        
        guard let candidate = geminiResponse.candidates?.first,
              let textParts = candidate.content?.parts else {
            throw GeminiServiceError.emptyResponse
        }
        
        let fullText = textParts.compactMap { $0.text }.joined()
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiServiceError.emptyResponse
        }
        
        return fullText
    }
    
    // Test API Key
    public func testApiKey(apiKey: String, model: String) async throws -> Bool {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GeminiServiceError.missingApiKey }
        
        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(trimmedKey)") else {
            throw GeminiServiceError.invalidURL
        }
        
        let body = GeminiRequest(
            contents: [GeminiContent(role: "user", parts: [.text("ping")])],
            systemInstruction: nil,
            generationConfig: GeminiGenerationConfig(temperature: 0.1, maxOutputTokens: 5)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 200 {
            return true
        }
        if let errResp = try? JSONDecoder().decode(GeminiResponse.self, from: data),
           let err = errResp.error {
            throw GeminiServiceError.apiError(code: err.code ?? 400, message: err.message ?? "Неверный ключ")
        }
        throw GeminiServiceError.apiError(code: (response as? HTTPURLResponse)?.statusCode ?? 500, message: "Ошибка проверки ключа")
    }
    
    // Helper to resize and compress image to keep request responsive on iPhone 7 Plus
    private func compressAndEncode(image: UIImage) -> String? {
        let maxDimension: CGFloat = 1600.0
        var targetImage = image
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let ratio = min(maxDimension / image.size.width, maxDimension / image.size.height)
            let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                targetImage = resized
            }
            UIGraphicsEndImageContext()
        }
        
        guard let jpegData = targetImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return jpegData.base64EncodedString()
    }
}
