//
//  GreetingView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//

import SwiftUI

struct GreetingNotificationView: View {
    
    var body: some View {
        
        ZStack (alignment: .center) {
            
                Text("Hola!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .onTapGesture {tap in
//                        container.controller.showExpandedPreset(.home)
                }
        }
        .frame(width: 220, height: 140)

    }
    
    
}

#Preview {
    ZStack {
        PanelShape()
            .fill(.black)

        
        GreetingNotificationView()
            .background(Color.blue.opacity(0.2))
//            .environment(AppContainer())

    }
    .frame(width: 220, height: 140)
    .frame(width: 400, height: 300, alignment: .top)
}
