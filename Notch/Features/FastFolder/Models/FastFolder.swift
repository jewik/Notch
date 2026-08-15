//
//  FastFolder.swift
//  Notch
//
//  Created by Usanin Ivan on 09.08.2026.
//

import Foundation
import SwiftUI


struct FastFolder: Identifiable, Codable {
    let id: UUID
    var name: String
    var bookmark: Data
    var tags: [String]
}

extension FastFolder {
    var folderColor: Color {
        // Берем первый тег папки, если он есть
        guard let firstTag = tags.first else {
            return Color.blue // Стандартный цвет папки в macOS
        }
        
        // Finder возвращает локализованные имена или стандартные цвета.
        // Проверяем по ключевым словам:
        switch firstTag.lowercased() {
        case "red", "красный": return .red
        case "orange", "оранжевый": return .orange
        case "yellow", "желтый": return .yellow
        case "green", "зеленый": return .green
        case "blue", "синий": return .blue
        case "purple", "фиолетовый": return .purple
        case "gray", "серый": return .gray
        default:
            return .blue // Если тег кастомный текстовый, оставляем синий или выберите другой
        }
    }
}
