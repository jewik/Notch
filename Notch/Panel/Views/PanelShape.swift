//
//  ContiniusShape.swift
//  UITests
//
//  Created by Usanin Ivan on 17.07.2026.
//


import SwiftUI

struct UnionPanelShape: Shape {
    
    let uiScale: CGFloat
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * uiScale
    }
    
    private var botMaxRadius: CGFloat { ui(60) }
    private var topMaxRadius: CGFloat { ui(30) }
    
    func path(in rect: CGRect) -> Path {
        var path: Path = Path()
        
        let width: CGFloat = rect.size.width
        let height: CGFloat = rect.size.height
        
        let topRadius: CGFloat = min(height / 4, topMaxRadius)
        let botRadius: CGFloat = min(height / 2, botMaxRadius)
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 1))
        ContinuousCornerPath.add(
            addTo: &path,
            startPoint: CGPoint(x: -topRadius, y: topRadius + 1),
            radius: topRadius,
            angleType: .bottomLeft,
            inversion: true
        )
        
        ContinuousCornerPath.add(
            addTo: &path,
            startPoint: CGPoint(x: topRadius, y: height - botRadius + 1),
            radius: botRadius,
            angleType: .bottomLeft
        )
        
        ContinuousCornerPath.add(
            addTo: &path,
            startPoint: CGPoint(x: width - botRadius - topRadius, y: height + 1),
            radius: botRadius,
            angleType: .bottomRight
        )
        
        ContinuousCornerPath.add(
            addTo: &path,
            startPoint: CGPoint(x: width, y: 1),
            radius: topRadius,
            angleType: .topLeft,
            inversion: true
        )
        path.addLine(to: CGPoint(x: width, y: 0))

        path.closeSubpath()
        
        return path
    }
}

struct PanelShape: Shape {
    
    let uiScale: CGFloat
    
    private func ui(_ value: CGFloat) -> CGFloat {
        value * uiScale
    }
    
    private var botMaxRadius: CGFloat { ui(60) }
    
    func path(in rect: CGRect) -> Path {
        var path: Path = Path()
        
        let width: CGFloat = rect.size.width
        let height: CGFloat = rect.size.height
        
        let botRadius: CGFloat = min(height / 2, botMaxRadius)
                
        path.move(to: CGPoint(x: 0, y: 0))
        
        ContinuousCornerPath.add(
            addTo: &path,
            startPoint: CGPoint(x: 0, y: height - botRadius),
            radius: botRadius,
            angleType: .bottomLeft
        )
        ContinuousCornerPath.add(
            addTo: &path,
            startPoint: CGPoint(x: width - botRadius, y: height),
            radius: botRadius,
            angleType: .bottomRight
        )
        path.addLine(to: CGPoint(x: width, y: 0))
        
        
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack () {
        ZStack (alignment: .top) {
            UnionPanelShape(uiScale: 1)
                .fill(Color.teal)
                .shadow(color: Color.teal.opacity(0.8), radius: 20)
        }
        .frame(width: 400, height: 100)
    }
    .frame(width: 600, height: 300, alignment: .top)
    
}
