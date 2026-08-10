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
    
    func addFolder(url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            let folder = FastFolder(
                id: UUID(),
                name: url.lastPathComponent,
                bookmark: bookmark
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
