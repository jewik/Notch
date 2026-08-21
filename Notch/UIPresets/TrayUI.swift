//
//  TrayUI.swift
//  UITests
//
//  Created by Usanin Ivan on 03.08.2026.
//
import SwiftUI


struct TrayUI: View {
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
                
//            AirDropView()
                
        }
        .frame(height: ui(150))

    }
}



#Preview {
    
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)
        TrayUI()
            .background(Color.cyan.opacity(0.1))
            .environment(AppContainer())
    }
.frame(width: 500, height: 150, alignment: .top)


}
