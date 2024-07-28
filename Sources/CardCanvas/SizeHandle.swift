//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct SizeHandle: View {
    
    @Binding var ViewModel: ViewModel
    @State var handlePos: CGPoint = .zero
    var externalGeometry: GeometryProxy
    
    let minSize = CGSize(width: 20, height: 20)
    
    var calcPosition: CGPoint {
        
        if let frame = ViewModel.frame {
            return CGPoint(x: ViewModel.position.x + frame.width, y: ViewModel.position.y + frame.height)
        }
        return CGPoint(x: ViewModel.position.x + 20, y: ViewModel.position.y + 20)
        
    }
    
    func computePosition() {
        if let frame = ViewModel.frame {
            handlePos = CGPoint(x: ViewModel.position.x + frame.width, y: ViewModel.position.y + frame.height)
        }
        
    }
    
    var body: some View {
        Circle()
            .foregroundColor(.white)
            .overlay(Image(systemName: "arrow.up.left.and.arrow.down.right")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.black
                    .opacity(0.6)))
            .frame(width: 24, height: 24)
            .position(handlePos)
            .shadow(radius: 5)
            .onChange(of: ViewModel.position) { _ in
                computePosition()
            }
            .onAppear {
                computePosition()
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        var pos = gesture.location
                        
                        // Ensure stays within parent view bounds
                        pos.x = gesture.location.x < 0 ? 0 : pos.x
                        pos.y = gesture.location.y < 0 ? 0 : pos.y
                        pos.x = gesture.location.x > externalGeometry.size.width ? externalGeometry.size.width : pos.x
                        pos.y = gesture.location.y > externalGeometry.size.height ? externalGeometry.size.height : pos.y
                        
                        var newFrame = CGSize(width: pos.x - ViewModel.position.x, height: pos.y - ViewModel.position.y)
                        
                        // Enfornce mininmum size
                        newFrame.width = newFrame.width < minSize.width ? minSize.width : newFrame.width
                        newFrame.height = newFrame.height < minSize.height ? minSize.height : newFrame.height

                        ViewModel.frame = newFrame
                        computePosition()
                    }
            )
    }
}
