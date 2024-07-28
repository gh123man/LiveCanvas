//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct MoveHandle: View {
    
    @Binding var ViewModel: ViewModel
    @State private var fingerPosition: CGPoint?
    var externalGeometry: GeometryProxy
    
    var frame: CGSize {
        guard let frame = ViewModel.frame else {
            return .zero
        }
        return frame
    }
    
    var offset: CGSize {
        return CGSize(width: frame.width / 2, height: frame.height / 2)
    }
    
    var body: some View {
        Rectangle()
            .border(.blue)
            .frame(width: frame.width, height: frame.height)
            .contentShape(Rectangle())
            .offset(offset)
            .foregroundColor(.clear)
            .position(ViewModel.position)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        var pos = gesture.location
                        if fingerPosition == nil {
                            fingerPosition = CGPoint(x: pos.x - ViewModel.position.x, y: pos.y - ViewModel.position.y)
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
                        
                        ViewModel.position = pos
                    }
                    .onEnded { _ in
                        fingerPosition = nil
                    }
            )
    }
}
