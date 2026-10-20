
//
//  Untitled.swift
//  UITests
//
//  Created by Usanin Ivan on 24.07.2026.
//



import SwiftUI

struct NavigationRowView: View {
    
    
    var body: some View {
        HStack (alignment: .center, spacing: 4) {
            DotButton(
                color: .red,
                showUnsavedDot: true,
                action: {
                    AppContainer.shared.controller.showCollapsedPreset()
                    PanelNotificationsService.shared.post(ValedictionNotificationView())
                },
                innerContent: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                }
            )

            DotButton(
                color: .yellow,
                action: {
                    AppContainer.shared.controller.showExpandedPreset(.home)
                },
                innerContent: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.yellow)
                }
            )
            
            DotButton(
                color: .green,
                action: {
                    AppContainer.shared.panelState.useGlassPanelSurface.toggle()
                },
                innerContent: {
                    Image(systemName: "square.on.square.intersection.dashed")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                }
            )
            
            DotButton(
                color: .cyan,
                action: {},
                innerContent: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.cyan)
                }
            )
            
            Spacer()
            CustomTimeView()
            
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 30)
    }
}
