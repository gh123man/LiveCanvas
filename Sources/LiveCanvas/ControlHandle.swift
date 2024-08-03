//
//  File.swift
//
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI

struct ControlHandle<OverlayContent: View, ViewContext>: View {
    @Binding var viewModel: Layer<ViewContext>
    var selected: Bool
    var externalGeometry: GeometryProxy
    @ViewBuilder var overlayControls: (Binding<Layer<ViewContext>>, Bool) -> OverlayContent
    
    var size: CGSize {
        return viewModel.frame.size
    }
    
    var position: CGPoint {
        return viewModel.frame.origin
    }
    
    var offset: CGSize {
        return CGSize(width: size.width / 2, height: size.height / 2)
    }
    
    var body: some View {
        overlayControls($viewModel, selected)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .offset(offset)
            .position(position)
    }
}
