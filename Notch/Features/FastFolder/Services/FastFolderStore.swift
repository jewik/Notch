//
//  FastFolderStore.swift
//  Notch
//
//  Created by Usanin Ivan on 09.08.2026.
//

import Observation
import SwiftUI


@Observable
final class FastFolderStore {
    
    private(set) var folders: [FastFolder] = []
    
    private let storageKey = "fastFolders"
    
    init() {
        load()
    }
    
    func refreshFolders() {
            var updatedFolders: [FastFolder] = []
            var needsSave = false
            
            for folder in folders {
                do {
                    var isStale = false
                    // 1. Пытаемся разрешить закладку
                    let url = try URL(
                        resolvingBookmarkData: folder.bookmark,
                        options: [.withSecurityScope],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )
                    
                    // 2. Запрашиваем доступ к ресурсу
                    guard url.startAccessingSecurityScopedResource() else {
                        // Если доступ получить не удалось, сохраняем папку как есть до следующего раза
                        updatedFolders.append(folder)
                        continue
                    }
                    
                    // Используем defer, чтобы гарантированно закрыть доступ к ресурсу
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // 3. Проверяем, существует ли папка физически на диске
                    var isDirectory: ObjCBool = false
                    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    
                    // Если папка удалена, мы просто НЕ добавляем её в updatedFolders (пропускаем / удаляем из хранилища)
                    guard exists && isDirectory.boolValue else {
                        print("Папка \(folder.name) была удалена с диска. Удаляем из списка.")
                        needsSave = true
                        continue
                    }
                    
                    // 4. Считываем актуальные теги Finder с диска
                    let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
                    let currentTags = resourceValues.tagNames ?? []
                    
                    // 5. Проверяем, обновились ли теги или сама закладка (isStale)
                    var currentBookmark = folder.bookmark
                    if isStale {
                        // Пересоздаем закладку, если система пометила её как устаревшую (например, папку переместили)
                        if let newBookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                            currentBookmark = newBookmark
                            needsSave = true
                        }
                    }
                    
                    // Если теги изменились, фиксируем необходимость сохранения
                    if currentTags != folder.tags {
                        needsSave = true
                    }
                    
                    // Создаем обновленный экземпляр папки (если модель FastFolder — это struct)
                    let refreshedFolder = FastFolder(
                        id: folder.id,
                        name: url.lastPathComponent, // Имя тоже могло измениться, если папку переименовали
                        bookmark: currentBookmark,
                        tags: currentTags
                    )
                    
                    updatedFolders.append(refreshedFolder)
                    
                } catch {
                    // Если вызвана ошибка (например, исходный файл удален и закладка не разрешается)
                    print("Не удалось разрешить или обновить папку \(folder.name):", error)
                    // В случае критической ошибки (удаления) папка будет удалена из списка
                    needsSave = true
                }
            }
            
            // Перезаписываем массив папок и сохраняем в UserDefaults только если были изменения
            self.folders = updatedFolders
            if needsSave {
                save()
            }
        }
    
    func addFolder(url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // 1. Получаем теги Finder из URL
            let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
            let finderTags = resourceValues.tagNames ?? [] // Массив строк тегов
            
            let folder = FastFolder(
                id: UUID(),
                name: url.lastPathComponent,
                bookmark: bookmark,
                tags: finderTags // 2. Сохраняем теги
            )
            
            folders.append(folder)
            save()
            
        } catch {
            print("Failed to create bookmark:", error)
        }
    }
    
    func removeFolder(_ folder: FastFolder) {
        folders.removeAll {
            $0.id == folder.id
        }
        save()
    }
    
    func resolve(_ folder: FastFolder) -> URL? {
        do {
            var isStale = false
            
            let url = try URL(
                resolvingBookmarkData: folder.bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("Bookmark is stale:", folder.name)
            }
            
            return url
            
        } catch {
            print("Failed to resolve bookmark:", error)
            return nil
        }
    }
    
    func open(_ folder: FastFolder) {
        guard let url = resolve(folder) else {
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            return
        }
        
        NSWorkspace.shared.open(url)
        
        url.stopAccessingSecurityScopedResource()
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(folders)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save folders:", error)
        }
    }
    
    func clearFolders() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        folders.removeAll()
    }
    
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        
        do {
            folders = try JSONDecoder().decode(
                [FastFolder].self,
                from: data
            )
        } catch {
            print("Failed to load folders:", error)
        }
    }
}
