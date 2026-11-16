import SwiftUI
import UIKit

public struct MessageBubbleView: View {
    public let message: ChatMessage
    public var onRetry: (() -> Void)? = nil
    
    @State private var copiedWholeText = false
    @State private var selectedImageForFullView: UIImage? = nil
    @State private var showShareSheet = false
    
    public init(message: ChatMessage, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 44)
                userBubble
            } else {
                geminiBubble
                Spacer(minLength: 44)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .sheet(item: $selectedImageForFullView) { img in
            FullScreenImageView(image: img)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [message.text])
        }
    }
    
    // MARK: - User Message Bubble
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Attached images preview
            if !message.images.isEmpty {
                imageAttachmentGrid(images: message.images)
            }
            
            // Text
            if !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(message.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(SlateTheme.userBubbleGradient)
                    .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
            }
            
            // Time
            Text(message.formattedTime)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(SlateTheme.textTertiary)
                .padding(.trailing, 4)
        }
    }
    
    // MARK: - Gemini Assistant Bubble
    private var geminiBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            // Gemini Avatar Icon
            ZStack {
                Circle()
                    .fill(SlateTheme.surfaceRaised)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle().stroke(SlateTheme.border, lineWidth: 1)
                    )
                
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SlateTheme.geminiStarGradient)
            }
            .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                if message.role == .error {
                    errorCard
                } else if message.isPending {
                    pendingCard
                } else {
                    assistantCard
                }
                
                // Bottom info row
                HStack(spacing: 12) {
                    Text(message.formattedTime)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(SlateTheme.textTertiary)
                    
                    if message.role == .model && !message.isPending {
                        // Copy Button
                        Button(action: {
                            UIPasteboard.general.string = message.text
                            Haptics.notify(.success)
                            withAnimation(.spring()) {
                                copiedWholeText = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copiedWholeText = false }
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: copiedWholeText ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 10))
                                Text(copiedWholeText ? "Скопировано" : "Копия")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(copiedWholeText ? SlateTheme.success : SlateTheme.textSecondary)
                        }
                        
                        // Share Button
                        Button(action: {
                            Haptics.play(.light)
                            showShareSheet = true
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 10))
                                Text("Поделиться")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(SlateTheme.textSecondary)
                        }
                    }
                }
                .padding(.leading, 4)
                .padding(.top, 2)
            }
        }
    }
    
    // MARK: - Assistant Card Content with Code Block Support
    private var assistantCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            let blocks = MarkdownParser.parse(text: message.text)
            ForEach(blocks) { block in
                switch block {
                case .text(let str):
                    Text(LocalizedStringKey(str))
                        .font(.system(size: 15))
                        .foregroundColor(SlateTheme.textPrimary)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                case .codeBlock(let code, let lang):
                    CodeBlockCard(code: code, language: lang)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(SlateTheme.surface)
        .cornerRadius(18, corners: [.topRight, .bottomLeft, .bottomRight])
        .overlay(
            RoundedCorner(radius: 18, corners: [.topRight, .bottomLeft, .bottomRight])
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Error Card
    private var errorCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(SlateTheme.error)
                Text("Внимание")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(SlateTheme.error)
            }
            
            Text(message.text)
                .font(.system(size: 14))
                .foregroundColor(SlateTheme.textPrimary)
            
            if let retry = onRetry {
                Button(action: {
                    Haptics.play(.medium)
                    retry()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Повторить запрос")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SlateTheme.accent)
                    .cornerRadius(10)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(SlateTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SlateTheme.error.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Pending/Thinking Card
    private var pendingCard: some View {
        HStack(spacing: 8) {
            DotPulseView()
            Text("Gemini думает...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(SlateTheme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(SlateTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Image Grid for User
    private func imageAttachmentGrid(images: [AttachedImage]) -> some View {
        HStack(spacing: 6) {
            ForEach(images) { item in
                Button(action: {
                    selectedImageForFullView = item.image
                }) {
                    Image(uiImage: item.thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SlateTheme.border, lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Code Block View
struct CodeBlockCard: View {
    let code: String
    let language: String
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack {
                Text(language.isEmpty ? "code" : language.lowercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(SlateTheme.textSecondary)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = code
                    Haptics.notify(.success)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copied = false }
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(copied ? "Скопировано" : "Скопировать")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(copied ? SlateTheme.success : SlateTheme.accentHover)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(SlateTheme.surfaceRaised)
            
            Divider().background(SlateTheme.border)
            
            // Code text
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "E2E8F0"))
                    .lineSpacing(3)
                    .padding(12)
                    .textSelection(.enabled)
            }
            .background(Color(hex: "080C14"))
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(SlateTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Simple Markdown Block Parser
enum MarkdownBlock: Identifiable {
    case text(String)
    case codeBlock(code: String, language: String)
    
    var id: String {
        switch self {
        case .text(let str): return "t_\(str.hashValue)"
        case .codeBlock(let code, _): return "c_\(code.hashValue)"
        }
    }
}

enum MarkdownParser {
    static func parse(text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let pattern = "```(\\w*)\\n?([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [.text(text)]
        }
        
        let nsString = text as NSString
        var lastIndex = 0
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let beforeRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
            if beforeRange.length > 0 {
                let textChunk = nsString.substring(with: beforeRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !textChunk.isEmpty {
                    blocks.append(.text(textChunk))
                }
            }
            
            let lang = match.range(at: 1).location != NSNotFound ? nsString.substring(with: match.range(at: 1)) : ""
            let code = match.range(at: 2).location != NSNotFound ? nsString.substring(with: match.range(at: 2)) : ""
            blocks.append(.codeBlock(code: code.trimmingCharacters(in: .whitespacesAndNewlines), language: lang))
            
            lastIndex = match.range.location + match.range.length
        }
        
        if lastIndex < nsString.length {
            let remaining = nsString.substring(from: lastIndex).trimmingCharacters(in: .whitespacesAndNewlines)
            if !remaining.isEmpty {
                blocks.append(.text(remaining))
            }
        }
        
        return blocks.isEmpty ? [.text(text)] : blocks
    }
}

// MARK: - Animated Dot Pulse
struct DotPulseView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(SlateTheme.accent)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.0 : 0.4)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Helper Fullscreen Image Viewer
struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

extension UIImage: Identifiable {
    public var id: Int {
        return self.hash
    }
}

// MARK: - UIActivityViewController Wrapper for Sharing
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - RoundedCorner Helper for iOS 15
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
