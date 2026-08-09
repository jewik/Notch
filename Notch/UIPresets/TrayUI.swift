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
        VStack(alignment: .center, spacing: ui(2)){
            
            NavigationRowView()

            HStack(alignment: .center, spacing: 0) {
                
                AirDropView()
                
            }
        }
        .frame(width: ui(500), height: ui(150 + 32))

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
.frame(width: 500, height: 150 + 32, alignment: .top)


}
