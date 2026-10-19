//
//  TrayUI.swift
//  UITests
//
//  Created by Usanin Ivan on 03.08.2026.
//
import SwiftUI


struct TrayUI: View {

    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
                
//            AirDropView()
                
        }
        .frame(height: 150)

    }
}



#Preview {
    
    ZStack {
        PanelShape()
            .fill(.black)
        TrayUI()
            .background(Color.cyan.opacity(0.1))
//            .environment(AppContainer())
    }
.frame(width: 500, height: 150, alignment: .top)


}
