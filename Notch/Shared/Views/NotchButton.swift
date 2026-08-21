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
    var disabled: Bool?
    let action: () -> Void

    
    @State private var isHovered = false

    private var isHighlighted: Bool {
        isActive || isHovered
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    if let systemName, !systemName.isEmpty {
                        ZStack (alignment: .center) {
                            Image(systemName: systemName)
                                .font(.system(size: textSize, weight: .semibold))
                                .foregroundStyle(color)
                        }
                        .frame(width: bgSize.height, height: bgSize.height)
                    }
                    
                    
                    if let title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: textSize, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(color)
                    }
                }
                
                RoundedRectangle(cornerRadius: bgSize.width / 2, style: .continuous)
                    .fill(isHighlighted ? color.opacity(0.14) : .clear)
                    .frame(width: bgSize.width, height: bgSize.height)
            }
            .frame(width: bgSize.width, height: bgSize.height, alignment: .leading)
            .clipShape(
                RoundedRectangle(cornerRadius: bgSize.width / 2, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? color : color.opacity(0.72))

        .onHover { hovering in
            withAnimation (.smooth(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .disabled(disabled ?? false)
    }
}


