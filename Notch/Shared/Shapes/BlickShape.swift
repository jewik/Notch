//
//  BlickShape.swift
//  Notch
//
//  Created by Usanin Ivan on 15.08.2026.
//
import SwiftUI

struct BlickShape: Shape {
    
    func path(in rect: CGRect) -> Path {
        var path: Path = Path()
        
        let width: CGFloat = rect.size.width
        let height: CGFloat = rect.size.height
        
                
        path.move(to: CGPoint(x: width / 2 - height / 2 + height * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width / 2 - height / 2 + height * 0.1, y: height))
        path.addLine(to: CGPoint(x: width / 2 - height / 2 + height * 0.2, y: height))
        path.addLine(to: CGPoint(x: width / 2 - height / 2 + height * 0.6, y: 0))
        
        path.move(to: CGPoint(x: width / 2 - height / 2 + height * 0.7, y: 0))
        path.addLine(to: CGPoint(x: width / 2 - height / 2 + height * 0.3, y: height))
        path.addLine(to: CGPoint(x: width / 2 - height / 2 + height * 0.5, y: height))
        path.addLine(to: CGPoint(x: width / 2 - height / 2 + height * 0.9, y: 0))
        
        path.closeSubpath()
        
        return path
    }
}

#Preview {

        ZStack {
            BlickShape()
                .fill(.white)
                .shadow(color: .red, radius: 10)
        }
        .frame(width: 300, height: 200)
        .background(.indigo.opacity(0.1))
        .frame(width: 600, height: 300, alignment: .top)
        .background(.green.opacity(0.1))


    
}
