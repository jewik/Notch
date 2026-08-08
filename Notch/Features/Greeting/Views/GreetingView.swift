//
//  GreetingView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//

import SwiftUI

struct GreetingView: View {
    
    @Environment(AppContainer.self)
    private var container
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    @State private var showGreeting: Bool = false
    
    
    
    
    var body: some View {
        
        ZStack (alignment: .center) {
            
            if showGreeting {
                Text("Hola!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .onTapGesture {tap in
                        container.expandedContentController.setPreset(.home)
                    }
            }
        }
        .frame(width: ui(220), height: ui(140))
        .animation(
            .smooth(duration: 0.5),
            value: showGreeting
        )
        .task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation {
                showGreeting = true
            }
        }

        
    }
    
    
}

#Preview {
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)

        
        GreetingView()
            .background(Color.blue.opacity(0.2))
            .environment(AppContainer())

    }
    .frame(width: 220, height: 140)
    .frame(width: 400, height: 300, alignment: .top)
}
