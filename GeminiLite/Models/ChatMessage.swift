import SwiftUI
import UIKit

public enum MessageRole: String, Codable {
    case user
    case model
    case error
}

public struct AttachedImage: Identifiable {
    public let id: UUID
    public let image: UIImage
    public let thumbnail: UIImage
    
    public init(id: UUID = UUID(), image: UIImage) {
        self.id = id
        self.image = image
        // Generate small thumbnail for smooth UI scrolling
        let size = CGSize(width: 240, height: 240)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        self.thumbnail = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
    }
}

public struct ChatMessage: Identifiable {
    public let id: UUID
    public let role: MessageRole
    public var text: String
    public var images: [AttachedImage]
    public let timestamp: Date
    public var isPending: Bool
    
    public init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String,
        images: [AttachedImage] = [],
        timestamp: Date = Date(),
        isPending: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.images = images
        self.timestamp = timestamp
        self.isPending = isPending
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}
