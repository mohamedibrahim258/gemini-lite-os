import Foundation

// MARK: - Gemini API Request Structures
public struct GeminiRequest: Encodable {
    public let contents: [GeminiContent]
    public let systemInstruction: GeminiSystemInstruction?
    public let generationConfig: GeminiGenerationConfig?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction = "system_instruction"
        case generationConfig
    }
}

public struct GeminiSystemInstruction: Encodable {
    public let parts: [GeminiTextPart]
    
    public init(text: String) {
        self.parts = [GeminiTextPart(text: text)]
    }
}

public struct GeminiContent: Encodable {
    public let role: String?
    public let parts: [GeminiPart]
    
    public init(role: String?, parts: [GeminiPart]) {
        self.role = role
        self.parts = parts
    }
}

public enum GeminiPart: Encodable {
    case text(String)
    case inlineData(mimeType: String, data: String)
    
    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }
    
    enum InlineDataKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let str):
            try container.encode(str, forKey: .text)
        case .inlineData(let mime, let data):
            var nested = container.nestedContainer(keyedBy: InlineDataKeys.self, forKey: .inlineData)
            try nested.encode(mime, forKey: .mimeType)
            try nested.encode(data, forKey: .data)
        }
    }
}

public struct GeminiTextPart: Encodable {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}

public struct GeminiGenerationConfig: Encodable {
    public let temperature: Double
    public let maxOutputTokens: Int?
    
    public init(temperature: Double, maxOutputTokens: Int? = 4096) {
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
    }
}

// MARK: - Gemini API Response Structures
public struct GeminiResponse: Decodable {
    public let candidates: [GeminiCandidate]?
    public let usageMetadata: GeminiUsageMetadata?
    public let error: GeminiErrorDetail?
}

public struct GeminiCandidate: Decodable {
    public let content: GeminiResponseContent?
    public let finishReason: String?
}

public struct GeminiResponseContent: Decodable {
    public let parts: [GeminiResponsePart]?
    public let role: String?
}

public struct GeminiResponsePart: Decodable {
    public let text: String?
}

public struct GeminiUsageMetadata: Decodable {
    public let promptTokenCount: Int?
    public let candidatesTokenCount: Int?
    public let totalTokenCount: Int?
}

public struct GeminiErrorDetail: Decodable {
    public let code: Int?
    public let message: String?
    public let status: String?
}
