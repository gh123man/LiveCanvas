//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct MoveHandle<ViewContext>: View {
    @Binding var selected: Layer<ViewContext>
    @State private var fingerPosition: CGPoint?
    var externalGeometry: GeometryProxy
    var onStartMove: () -> ()
    
    var size: CGSize {
        return selected.frame.size
    }
    
    var position: CGPoint {
        return selected.frame.origin
    }
    
    var offset: CGSize {
        return CGSize(width: size.width / 2, height: size.height / 2)
    }
    
    func boundsCheck(_ inpt: CGPoint) -> CGPoint {
        var pos = inpt
        pos.x = pos.x < 0 ? 0 : pos.x
        pos.y = pos.y < 0 ? 0 : pos.y
        pos.x = pos.x > externalGeometry.size.width ? externalGeometry.size.width : pos.x
        pos.y = pos.y > externalGeometry.size.height ? externalGeometry.size.height : pos.y
        return pos
    }
    
    var body: some View {
        Rectangle()
            .border(.blue)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .offset(offset)
            .foregroundColor(.clear)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        var pos = gesture.location
                        if fingerPosition == nil {
                            onStartMove()
                            fingerPosition = CGPoint(x: pos.x - position.x, y: pos.y - position.y)
                        }

                        pos = boundsCheck(pos)
                        
                        // Correct movement to exact touch position
                        if let fingerPosition = fingerPosition {
                            pos.x -= fingerPosition.x
                            pos.y -= fingerPosition.y
                        }
                        
                        selected.frame.origin = pos
                    }
                    .onEnded { _ in
                        fingerPosition = nil
                    }
            )
    }
}
