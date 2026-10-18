//
//  SliderBarNotificationView.swift
//  Notch
//
//  Created by Usanin Ivan on 11.10.2026.
//

import SwiftUI

struct HUDNotificationView: PanelNotification {
    
    let id = UUID()
    let priority = 1 // Высокий приоритет
    let duration: TimeInterval = 1.5
    
    var systemName: String
    var progress: Float

    
    func makeView() -> AnyView {
        AnyView(HUDNotificationContentView(
            systemName: systemName,
            progress: progress
        ))
    }
}


struct HUDNotificationContentView: View {
    
    var systemName: String
    var progress: Float
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 40)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(width: geometry.size.width)
                        .opacity(0.3)
                    Capsule()
                        .frame(width: geometry.size.width * CGFloat(self.progress))
                        .shadow(color: .white.opacity(Double(self.progress)), radius: 10)
                }
                
            }
            .frame(height: 6)
            
            Text(Int(round(progress * 100)), format: .number)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(progress)))
                .frame(width: 40)
            
        }
            .frame(width: 240, height: 40)
            .animation(.smooth(duration: 0.2), value: progress)
            .animation(.smooth(duration: 0.2), value: systemName)
    }
}
