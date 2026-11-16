import SwiftUI

public struct QuickActionItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let icon: String
    public let prompt: String
}

public struct QuickPromptBar: View {
    public var onSelect: (String) -> Void
    
    private let actions: [QuickActionItem] = [
        QuickActionItem(
            title: "Реши задачу",
            icon: "function",
            prompt: "Пожалуйста, реши задачу на фото/в тексте подробно по шагам: 1. Дано; 2. Необходимые формулы; 3. Ход решения; 4. Ответ."
        ),
        QuickActionItem(
            title: "Найди ошибку",
            icon: "checkmark.seal",
            prompt: "Внимательно проверь решение или текст. Укажи, где допущена ошибка, объясни её причину и покажи правильный вариант."
        ),
        QuickActionItem(
            title: "Объясни просто",
            icon: "lightbulb.fill",
            prompt: "Объясни этот материал простыми и понятными словами с жизненными аналогиями, как будто объясняешь другу."
        ),
        QuickActionItem(
            title: "Конспект",
            icon: "list.bullet.rectangle",
            prompt: "Составь краткий и структурированный конспект: главные понятия, ключевые тезисы списком и важные формулы/выводы."
        ),
        QuickActionItem(
            title: "Перевод",
            icon: "character.book.closed.fill",
            prompt: "Переведи этот текст на грамотный русский язык с сохранением академического стиля и терминологии."
        ),
        QuickActionItem(
            title: "Разбор кода",
            icon: "chevron.left.forwardslash.chevron.right",
            prompt: "Напиши чистый код для решения этой задачи с подробными комментариями и объяснением алгоритма."
        )
    ]
    
    public init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(actions) { action in
                    Button(action: {
                        Haptics.play(.light)
                        onSelect(action.prompt)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: action.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(SlateTheme.accentHover)
                            Text(action.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(SlateTheme.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(SlateTheme.surfaceRaised)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SlateTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }
}
