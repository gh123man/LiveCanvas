//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct SizeHandle<ViewContext>: View {
    
    @Binding var selected: Layer<ViewContext>
    @State var handlePos: CGPoint = .zero
    var externalGeometry: GeometryProxy
    
    let minSize = CGSize(width: 20, height: 20)
    
    func computePosition(frame: CGRect? = nil) {
        let frame = frame ?? selected.frame
        handlePos = boundsCheck(CGPoint(x: frame.origin.x + frame.width, y: frame.origin.y + frame.height))
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
            .onChange(of: selected.frame) { newValue in
                computePosition(frame: newValue)
            }
            .onAppear {
                computePosition()
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        
                        let pos = boundsCheck(gesture.location)
                        var newFrame: CGSize
                        
                        switch selected.resize {
                        case .any:
                            newFrame = CGSize(width: pos.x - selected.frame .origin.x, height: pos.y - selected.frame .origin.y)
                            
                            selected.frame.size = newFrame
                        case .proportional:
                            let frame = selected.frame
                            
                            let wChange = pos.x - frame.origin.x
                            let hChange = pos.y - frame.origin.y
                            let wProportin = wChange / frame.width
                            let hProportin = hChange / frame.height

                            if wProportin > hProportin {
                                newFrame = CGSize(width: wChange, height: frame.height * wProportin)
                            } else {
                                newFrame = CGSize(width: frame.width * hProportin, height: hChange)
                            }
                            
                        default: return
                            
                        }
                        
                        // Enfornce mininmum size
                        newFrame.width = newFrame.width < minSize.width ? minSize.width : newFrame.width
                        newFrame.height = newFrame.height < minSize.height ? minSize.height : newFrame.height
                        selected.frame.size = newFrame
                        computePosition()
                    }
            )
    }
}
