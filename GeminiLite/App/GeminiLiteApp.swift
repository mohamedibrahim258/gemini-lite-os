import SwiftUI

@main
struct GeminiLiteApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
                .preferredColorScheme(.dark) // Slate dark aesthetic matches OLED & iPhone 7 Plus retina screen perfectly
        }
    }
}
