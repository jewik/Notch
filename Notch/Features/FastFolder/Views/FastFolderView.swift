//
//  FastFolderView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//

import SwiftUI

struct FastFolderView: View {
    
    @Environment(\.uiScale)
    private var scale: CGFloat

    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    private let projectsUrl = URL(fileURLWithPath: "/Users/ivan/Projects")
    private let downloadsUrl = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Downloads")
    
    var body: some View {
        VStack {
            
            Text("Open Downloads")
                .onTapGesture {tap in
                    NSWorkspace.shared.open(downloadsUrl)
                }
            Text("Open Projects")
                .onTapGesture {tap in
                    NSWorkspace.shared.open(projectsUrl)
                }
            
        }
        .frame(width: ui(300), height: ui(150))
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
