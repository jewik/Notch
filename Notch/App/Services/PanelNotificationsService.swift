//
//  PanelNotificationsService.swift
//  Notch
//
//  Created by Usanin Ivan on 18.10.2026.
//


import Foundation
import Observation
import SwiftUI


protocol PanelNotification {
    var id: UUID { get }
    var priority: Int { get }
    var duration: TimeInterval { get }
    
    @ViewBuilder func makeView() -> AnyView
}


@MainActor
@Observable
final class PanelNotificationsService {
    
    static let shared = PanelNotificationsService()
    
    var currentNotification: PanelNotification?
    
    @ObservationIgnored
    private var dismissTask: Task<Void, Never>?
    
    private init() {}
    
    func post(_ notification: PanelNotification) {
        guard let current = currentNotification else {
            show(notification)
            return
        }
        
        if notification.priority >= current.priority {
            show(notification)
        }
    }
    
    private func show(_ notification: PanelNotification) {
        
        dismissTask?.cancel()
        
        withAnimation(.smooth) {
            currentNotification = notification
        }
        
        dismissTask = Task {
            
            let nanoseconds = UInt64(notification.duration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            
            
            if !Task.isCancelled {
                withAnimation(.smooth) {
                    currentNotification = nil
                }
            }
        }
    }
}
