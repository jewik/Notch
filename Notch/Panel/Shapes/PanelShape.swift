//
//  ContiniusShape.swift
//  UITests
//
//  Created by Usanin Ivan on 17.07.2026.
//


import SwiftUI

struct UnionPanelShape: Shape {
    
    
    private var botMaxRadius: CGFloat { 50 }
    private var topMaxRadius: CGFloat { 30 }
    
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
    
    private var botMaxRadius: CGFloat { 50 }
    
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
            UnionPanelShape()
                .fill(Color.teal)
                .shadow(color: Color.teal.opacity(0.8), radius: 20)
        }
        .frame(width: 400, height: 100)
    }
    .frame(width: 600, height: 300, alignment: .top)
    
}
