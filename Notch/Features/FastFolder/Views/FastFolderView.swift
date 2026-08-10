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

    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    
    var body: some View {
        VStack {
            HStack(spacing: ui(20)) {
                ForEach(container.fastFolderStore.folders) { folder in
                    FastFolderButtonView(
                        folderName: folder.name,
                        action: {
                            container.fastFolderStore.open(folder)
                        }
                    )
//                    .background(.red)
                }
            }
            HStack {
                Button {
                    selectFolder()
                } label: {
                    Label("Add Folder", systemImage: "plus")
                }
                
                Button("kill folders") {
                    container.fastFolderStore.clearFolders()
                }
            }
            
        }
        .frame(width: ui(300), height: ui(150))
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
    let action: () -> Void
    
    @Environment(\.uiScale)
    private var scale: CGFloat

    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {

        Button(action: action){
            VStack(alignment: .center, spacing: 0) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: NSHomeDirectory()))
                    .resizable()
                    .scaledToFit()
                    .frame(width: ui(60), height: ui(60))
                
                Text(folderName)
                    .font(.system(size: ui(12), weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .frame(width: ui(70), height: ui(80))
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
