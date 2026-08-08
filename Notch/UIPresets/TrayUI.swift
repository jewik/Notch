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
        VStack(spacing: ui(2)){
            
            NavigationRowView()

            HStack(alignment: .center, spacing: 0) {
                
                AirDropZoneView()
                
            }
        }
        .frame(width: ui(500), height: ui(150 + 34))

    }
}



#Preview {
    
    ZStack {
        PanelShape(uiScale: 1)
            .fill(.black)
        TrayUI()
            .background(Color.cyan.opacity(0.1))
    }
.frame(width: 500, height: 150 + 34, alignment: .top)


}
