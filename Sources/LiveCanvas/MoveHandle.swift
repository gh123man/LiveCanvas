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
    let minTapSize = CGSize(width: 20, height: 20)
    
    var size: CGSize {
        if let clipFrame = selected.clipFrame {
            return clipFrame.size
        }
        return selected.frame.size
    }
    
    var position: CGPoint {
        if let clipFrame = selected.clipFrame {
            return clipFrame.origin
        }
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
            .frame(width: max(size.width, minTapSize.width), height: max(size.height, minTapSize.height))
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
                            fingerPosition = CGPoint(x: pos.x - selected.frame.origin.x, y: pos.y - selected.frame.origin.y)
                        }

                        pos = boundsCheck(pos)
                        
                        // Correct movement to exact touch position
                        if let fingerPosition = fingerPosition {
                            pos.x -= fingerPosition.x
                            pos.y -= fingerPosition.y
                        }
                        
                        let deltax = pos.x - selected.frame.origin.x
                        let deltay = pos.y - selected.frame.origin.y
                        selected.frame.origin = selected.frame.origin.add(CGSize(width: deltax, height: deltay))
                        if let clipFrame = selected.clipFrame {
                            selected.clipFrame?.origin = clipFrame.origin.add(CGSize(width: deltax, height: deltay))
                        }
                    }
                    .onEnded { _ in
                        fingerPosition = nil
                    }
            )
    }
}
