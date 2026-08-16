//
//  GlobalViews.swift
//  Notch
//
//  Created by Usanin Ivan on 14.08.2026.
//

import SwiftUI

struct NotchButton: View {
    let systemName: String?
    var title: String?
    let color: Color
    let bgSize: CGSize
    let textSize: CGFloat
    let isActive: Bool
    let action: () -> Void
    
    private var scale : CGFloat {1.0}
    
    @State private var isHovered = false

    private func ui(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var isHighlighted: Bool {
        isActive || isHovered
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .center) {
                HStack(spacing: ui(2)) {
                    if let systemName {
                        Image(systemName: systemName)
                            .font(.system(size: ui(textSize), weight: .semibold))
                            .foregroundStyle(color)
                    }
                    if let title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: ui(textSize), weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(color)
                    }
                }
                RoundedRectangle(cornerRadius: ui(bgSize.width / 2), style: .continuous)
                    .fill(isHighlighted ? color.opacity(0.14) : .clear)
                    .frame(width: ui(bgSize.width), height: ui(bgSize.height))
//                BlickShape()
//                    .fill(isHighlighted ? color.opacity(0.14) : .clear)
//                    .shadow(color: color, radius: bgSize.height / 2)
//                    .padding(.leading , ui(bgSize.height / 3 * 2))
//                    .frame(width: ui(bgSize.width), height: ui(bgSize.height))
//                    .transition(.collapseExpandTransition)
                
                
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? color : color.opacity(0.72))
        .onHover { hovering in
            withAnimation (.smooth(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}


