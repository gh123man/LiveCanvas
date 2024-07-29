//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct SizeHandle<ViewContext>: View {
    
    @Binding var viewModel: ViewModel<ViewContext>
    @State var handlePos: CGPoint = .zero
    var externalGeometry: GeometryProxy
    
    let minSize = CGSize(width: 20, height: 20)
    
    func computePosition(frame: CGRect? = nil) {
        if let frame = frame ?? viewModel.frame  {
            handlePos = boundsCheck(CGPoint(x: frame.origin.x + frame.width, y: frame.origin.y + frame.height))
        }
        
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
            .onChange(of: viewModel.frame) { newValue in
                computePosition(frame: newValue)
            }
            .onAppear {
                computePosition()
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        
                        let pos = boundsCheck(gesture.location)
                        
                        var newFrame: CGSize = .zero
                        if let frame = viewModel.frame {
                            newFrame = CGSize(width: pos.x - frame.origin.x, height: pos.y - frame.origin.y)
                        }
                        
                        // Enfornce mininmum size
                        newFrame.width = newFrame.width < minSize.width ? minSize.width : newFrame.width
                        newFrame.height = newFrame.height < minSize.height ? minSize.height : newFrame.height

                        viewModel.frame?.size = newFrame
                        computePosition()
                    }
            )
    }
}
