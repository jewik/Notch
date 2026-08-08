//
//  HomePlayerUI.swift
//  UITests
//
//  Created by Usanin Ivan on 29.07.2026.
//


import SwiftUI

// 6 (50) points of width 300 UIs in total
struct PlayerView: View {
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        HStack(spacing: ui(10)) {
            PlayerCoverView()
            VStack(alignment: .leading, spacing: ui(22)){
                PlayerInfoView()
                PlayerButtonRowView()
            }
//            .background(Color.gray.opacity(0.5))
        }
        .padding(.horizontal , ui(10))
        .frame(width: ui(300), height: ui(150), alignment: .leading)
        
    }
}

struct PlayerCoverView: View {
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: ui(30))
                .fill(Color.gray.opacity(0.3))
                .frame(width: ui(130), height: ui(130))
//                .background(Color.blue.opacity(0.5))
        }
    }
}

struct PlayerInfoView: View {
    
    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            Text("The Silence")
                .font(.system(size: ui(16), weight: .bold, design: .rounded))
            Text("The Universe")
                .font(.system(size: ui(14), weight: .regular, design: .rounded)).opacity(0.8)
            Text("The Void")
                .font(.system(size: ui(14), weight: .regular, design: .rounded)).opacity(0.5)
        }
//        .background(Color.gray.opacity(0.5))
        
        
    }
}

struct PlayerButtonRowView : View{

    @Environment(\.uiScale)
    private var scale
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }
    
    var body: some View {
        
        HStack(spacing: ui(16)) {
            Button(action: {}) {
                Image(systemName: "star")
            }
            .buttonStyle(.plain)
            
            Button(action: {}) {
                Image(systemName: "backward.end.fill")
            }
            .buttonStyle(.plain)
            
            Button(action: {}) {
                Image(systemName: "play.fill")
            }
            .buttonStyle(.plain)
            
            Button(action: {}) {
                Image(systemName: "forward.end.fill")
            }
            .buttonStyle(.plain)
            
            Button(action: {}) {
                Image(systemName: "airplayaudio")
            }
            .buttonStyle(.plain)
        }
    }
}


#Preview{
    PlayerView()
        .background(Color.green.opacity(0.1))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
