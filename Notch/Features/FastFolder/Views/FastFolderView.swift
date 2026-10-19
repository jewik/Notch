//
//  FastFolderView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//

import SwiftUI

struct FastFolderView: View {
    
    private var container = AppContainer.shared

    @State private var isEditMode: Bool = false
    
    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                
                Text("FastFolders")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                
                Spacer()
                
                if isEditMode {
                    NotchButton(
                        systemName: "trash",
                        title: "All",
                        color: .red,
                        bgSize: CGSize(width: 50, height: 26),
                        textSize: 14,
                        isActive: false,
                        action: {
                            container.fastFolderStore.clearFolders()
                            isEditMode = false
                        }
                    )
                }
                
                NotchButton(
                    systemName: isEditMode ? "checkmark" : "square.and.pencil",
                    title: isEditMode ? "Done" : "Edit",
                    color: isEditMode ? .green : .indigo,
                    bgSize: CGSize(width: isEditMode ? 66: 60, height: 26),
                    textSize: 14,
                    isActive: false,
                    action: {
                        withAnimation (.smooth) {
                            isEditMode.toggle()
                        }
                    }
                )
                
            }
            .padding(.horizontal , 16)
            .frame(height: 30)
            
            HStack (alignment: .top ,spacing: 0) {
                ForEach(container.fastFolderStore.folders) { folder in
                    
                    ZStack (alignment: .topTrailing) {
                        FastFolderButtonView(
                            folderName: folder.name,
                            tags: folder.tags,
                            action: {
                                container.fastFolderStore.open(folder)
                            }
                        )
                        
                        if isEditMode {
                            NotchButton(
                                systemName: "xmark",
                                title: "",
                                color: .white,
                                bgSize: CGSize(width: 20, height: 20),
                                textSize: 12,
                                isActive: true,
                                action: {
                                    withAnimation(.smooth){
                                        container.fastFolderStore.removeFolder(folder)
                                    }
                                }
                            )
                            .offset(x: -8, y: 8)
                        }
                    }
                    
                }
                if container.fastFolderStore.folders.count < 3 {
                    Button (action: selectFolder) {
                        ZStack (alignment: .center) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                                .padding(10)
                                .frame(width: 100, height: 80)
                            
                        }
                    }
                    .padding(.top ,4)
                    .buttonStyle(.plain)
                }
            }
            
        }
        .padding(.top, 10)
        .frame(width: 300, height: 150, alignment: .top)
        .onAppear {
            container.fastFolderStore.refreshFolders()
        }
        .onDisappear {
            isEditMode = false
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }
        
        container.fastFolderStore.addFolder(url: url)
    }
}


struct FastFolderButtonView: View {
    
    let folderName: String
    let tags: [String]
    let action: () -> Void
    
    private let folderIcon = NSWorkspace.shared.icon(forFile: NSHomeDirectory())
    
    
    func colorForTagName(_ name: String) -> Color {
        switch name.lowercased() {
        case "red", "красный": return .red
        case "orange", "оранжевый": return .orange
        case "yellow", "желтый": return .yellow
        case "green", "зеленый": return .green
        case "blue", "синий": return .blue
        case "purple", "фиолетовый": return .purple
        case "gray", "серый": return .gray
            default: return .clear        }
    }
    
    var body: some View {
        
        Button(action: action){
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Image(nsImage: folderIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                    
                    if !tags.isEmpty {
                        VStack(spacing: 2) {
                            
                            ForEach(tags.prefix(3), id: \.self) { tagName in
                                let tagColor = colorForTagName(tagName)
                                if tagColor != .clear {
                                    Circle()
                                        .fill(tagColor)
                                        .frame(width: 10, height: 10)
                                        .shadow(color: .black.opacity(0.3), radius: 2)
                                }
                            }
                        }
                        
                        .padding(.leading, 7)
                        .padding(.top, 23)
                    }
                }
                
                Text(folderName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .frame(width: 100, height: 100)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ZStack {
        PanelShape()
            .fill(.black)
        
        FastFolderView()
            .background(Color.blue.opacity(0.2))
//            .environment(AppContainer())
        
    }
    .frame(width: 300, height: 150)
    .frame(width: 400, height: 300, alignment: .top)
}
