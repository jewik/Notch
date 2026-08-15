//
//  FastFolderView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//

import SwiftUI

struct FastFolderView: View {
    
    @Environment(AppContainer.self)
    private var container: AppContainer
    
    @Environment(\.uiScale)
    private var scale: CGFloat
    
    @State private var isEditMode: Bool = false

    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        VStack (alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                
                Text("FastFolders")
                    .font(.system(size: ui(20), weight: .semibold, design: .rounded))
                    .lineLimit(1)
                
                Spacer()
                
                if isEditMode {
                    NotchButton(
                        systemName: "trash",
                        title: "All",
                        color: .red,
                        bgSize: CGSize(width: ui(50), height: ui(26)),
                        textSize: ui(14),
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
                    bgSize: CGSize(width: ui(60), height: ui(26)),
                    textSize: ui(14),
                    isActive: false,
                    action: {
                        withAnimation (.smooth) {
                            isEditMode.toggle()
                        }
                    }
                )

            }
            .padding(.horizontal , ui(16))
            .frame(height: ui(30))
            
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
                                bgSize: CGSize(width: ui(20), height: ui(20)),
                                textSize: ui(12),
                                isActive: true,
                                action: {
                                    withAnimation(.smooth){
                                        container.fastFolderStore.removeFolder(folder)
                                    }
                                }
                            )
                            .offset(x: ui(-8), y: ui(8))
                        }
                    }
                                        
                    
                    
                    
//                    .background(.red)
                }
                if container.fastFolderStore.folders.count < 3 {
                    Button (action: selectFolder) {
                        ZStack (alignment: .center) {
                            Image(systemName: "plus")
                                .font(.system(size: ui(20), weight: .semibold))
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                                .padding(ui(10))
                                .frame(width: ui(100), height: ui(80))

                        }
                    }
                    .padding(.top ,ui(4))
                    .buttonStyle(.plain)
                }
                
                
            }
            
            
            
        }
        .padding(.top, ui(10))
        .frame(width: ui(300), height: ui(150), alignment: .top)
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
    
    @Environment(\.uiScale)
    private var scale: CGFloat

    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    func colorForTagName(_ name: String) -> Color {
        switch name.lowercased() {
        case "red", "красный": return .red
        case "orange", "оранжевый": return .orange
        case "yellow", "желтый": return .yellow
        case "green", "зеленый": return .green
        case "blue", "синий": return .blue
        case "purple", "фиолетовый": return .purple
        case "gray", "серый": return .gray
        default: return .clear // Неизвестные теги игнорируем
        }
    }
    
    var body: some View {

        Button(action: action){
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .topLeading) { // Точки будут внизу справа
                    Image(nsImage: folderIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: ui(70), height: ui(70))
                    
                    // 2. Ряд цветных точек (теги)
                    if !tags.isEmpty {
                        VStack(spacing: ui(2)) {

                            ForEach(tags.prefix(3), id: \.self) { tagName in
                                let tagColor = colorForTagName(tagName)
                                if tagColor != .clear {
                                    Circle()
                                        .fill(tagColor)
                                        .frame(width: ui(10), height: ui(10))
                                        .shadow(color: .black.opacity(0.3), radius: ui(2))
                                }
                            }
                        }

                        .padding(.leading, ui(7))
                        .padding(.top, ui(23))
                    }
                }
                
                Text(folderName)
                    .font(.system(size: ui(12), weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .frame(width: ui(100), height: ui(100))
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)
        
        FastFolderView()
            .background(Color.blue.opacity(0.2))
            .environment(AppContainer())

    }
    .frame(width: 300, height: 150)
    .frame(width: 400, height: 300, alignment: .top)
}
