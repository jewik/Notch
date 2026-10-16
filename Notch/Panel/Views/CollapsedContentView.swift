//
//  CollapsedPanelView.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//


import SwiftUI


struct CollapsedContentView: View {
    
    @State private var contentSize: CGSize = .zero
    
    
    var body: some View {
        VStack(spacing: 4) {
            
            ZStack(alignment: .top) {
                
                //                            CollapsedPlayerView()
                
                ZStack {
                    PanelShape()
                        .fill(.black)
                }
                .frame(width: 184, height: 30, alignment: .top)
                .onTapGesture {tap in
                    print("tapped")
                    AppContainer.shared.controller.showExpandedPreset(.home)
//                    container.panelController.showExpandedPreset(.home)
                }
            }
            
            if AppContainer.shared.panelState.isNotificationTime {
                notificationView
            }
        }
    }
    
    @ViewBuilder
    private var notificationView: some View {
        
        switch AppContainer.shared.panelState.notification {
        case .greeting:
            GreetingNotificationView().transition(.collapseExpandTransition)
            
        case .valediction:
            ValedictionNotificationView().transition(.collapseExpandTransition)
            
        case .airdrop:
            AirDropNotificationView().transition(.collapseExpandTransition)
            
        case .HUD:
            HUDNotificationView(
                systemName: AppContainer.shared.HUDViewmodel.kind.symbolName,
                progress: AppContainer.shared.HUDViewmodel.value
            ).transition(.collapseExpandTransition)

        case .bluetooth:
            BluetoothNotificationView(
                systemName: AppContainer.shared.bluetoothNotificationViewModel.symbolName,
                deviceName: AppContainer.shared.bluetoothNotificationViewModel.deviceName,
                message: AppContainer.shared.bluetoothNotificationViewModel.message
            ).transition(.collapseExpandTransition)
        }
    }
}


#Preview {
    CollapsedContentView()
        .background(Color.red.opacity(0.1))
        .frame(width: 300, height: 140, alignment: .top)
        .environment(AppContainer())
}
