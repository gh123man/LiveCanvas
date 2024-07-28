//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct MoveHandle: View {
    
    @Binding var viewModel: ViewModel
    @State private var fingerPosition: CGPoint?
    var externalGeometry: GeometryProxy
    
    var size: CGSize {
        guard let size = viewModel.frame?.size else {
            return .zero
        }
        return size
    }
    
    var position: CGPoint {
        guard let origin = viewModel.frame?.origin else {
            return .zero
        }
        return origin
    }
    
    var offset: CGSize {
        return CGSize(width: size.width / 2, height: size.height / 2)
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
                            fingerPosition = CGPoint(x: pos.x - position.x, y: pos.y - position.y)
                        }

                        // Ensure stays within parent view bounds
                        pos.x = gesture.location.x < 0 ? 0 : pos.x
                        pos.y = gesture.location.y < 0 ? 0 : pos.y
                        pos.x = gesture.location.x > externalGeometry.size.width ? externalGeometry.size.width : pos.x
                        pos.y = gesture.location.y > externalGeometry.size.height ? externalGeometry.size.height : pos.y
                        
                        if let fingerPosition = fingerPosition {
                            pos.x -= fingerPosition.x
                            pos.y -= fingerPosition.y
                        }
                        
                        viewModel.frame?.origin = pos
                    }
                    .onEnded { _ in
                        fingerPosition = nil
                    }
            )
    }
}
