//
//  File.swift
//
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct EditHandle<ViewContext>: View {
    
    @ObservedObject var viewModel: LiveCanvasViewModel<ViewContext>
    @Binding var selected: ViewState<ViewContext>
    @State var handlePos: CGPoint = .zero
    var externalGeometry: GeometryProxy
    
    let minSize = CGSize(width: 20, height: 20)
    
    
    func computePosition(frame: CGRect? = nil) {
        let frame = frame ?? selected.frame
        handlePos = boundsCheck(CGPoint(x: frame.origin.x, y: frame.origin.y))
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
            .overlay(Image(systemName: "pencil")
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
            .onTapGesture {
            }
    }
}
