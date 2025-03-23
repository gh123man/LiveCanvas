//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct DottedCropBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [3]))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
            )
    }
}

struct ClipHandle<ViewContext>: View {
    
    @Binding var selected: Layer<ViewContext>
    @State var handlePos: CGPoint = .zero
    @State var gestureOngoing = false
    @State private var fingerPosition: CGPoint?
    var externalGeometry: GeometryProxy
    var onStartMove: () -> ()
    
    let minSize = CGSize(width: 20, height: 20)
    
    var clipFrame: CGRect {
        if selected.clipFrame == nil || selected.clipFrame == .null {
            DispatchQueue.main.async {
                selected.clipFrame = selected.frame
            }
            return selected.frame
        }
        return selected.clipFrame!
    }
    
    var size: CGSize {
        return clipFrame.size
    }
    
    var position: CGPoint {
        return clipFrame.origin
    }
    
    var offset: CGSize {
        return CGSize(width: size.width / 2, height: size.height / 2)
    }
    
    var frameOffset: CGSize {
        return CGSize(width: selected.frame.width / 2, height: selected.frame.height / 2)
    }
    
    func computePosition(frame: CGRect? = nil) {
        let frame = frame ?? clipFrame
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
        ZStack {
            Rectangle()
                .modifier(DottedCropBorder())
                .frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .offset(offset)
                .foregroundColor(.clear)
                .position(position)
            Rectangle()
                .border(.blue)
                .frame(width: selected.frame.width, height: selected.frame.height)
                .contentShape(Rectangle())
                .offset(frameOffset)
                .foregroundColor(.clear)
                .position(selected.frame.origin)
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
                            
                            
                            // Leading bounds
                            if pos.x > position.x {
                                pos.x = selected.frame.origin.x
                            }
                            
                            // Trailing bounds
                            if pos.x + selected.frame.width < position.x + size.width {
                                pos.x = selected.frame.origin.x
                            }
                            
                            // Top bounds
                            if pos.y > position.y {
                                pos.y = selected.frame.origin.y
                            }
                            
                            // Bottom bounds
                            if pos.y + selected.frame.height < position.y + size.height {
                                pos.y = selected.frame.origin.y
                            }
                            
                            selected.frame.origin = pos
                        }
                        .onEnded { _ in
                            fingerPosition = nil
                        }
                )
            Circle()
                .foregroundColor(.white)
                .overlay(Image(systemName: "crop")
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.black
                        .opacity(0.6)))
                .frame(width: 24, height: 24)
                .position(handlePos)
                .shadow(radius: 5)
                .onChange(of: selected.clipFrame) { newValue in
                    computePosition(frame: newValue)
                }
                .onAppear {
                    computePosition()
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if !gestureOngoing {
                                self.gestureOngoing = true
                                onStartMove()
                            }
                            
                            var pos = boundsCheck(gesture.location)
                            
                            // Trailing bounds
                            if pos.x > selected.frame.origin.x + selected.frame.width {
                                pos.x = position.x + size.width
                            }
                        
                            // Bottom bounds
                            if pos.y > selected.frame.origin.y + selected.frame.height {
                                pos.y = position.y + size.height
                            }
                            
                            var newFrame = CGSize(width: pos.x - clipFrame .origin.x, height: pos.y - clipFrame .origin.y)
                            
                            // Enfornce min/max size
                            newFrame.width = newFrame.width < minSize.width ? minSize.width : newFrame.width
                            newFrame.height = newFrame.height < minSize.height ? minSize.height : newFrame.height
                            
                            selected.clipFrame?.size = newFrame
                            computePosition()
                        }
                        .onEnded { _ in
                            gestureOngoing = false
                        }
                )
        }
    }
}
