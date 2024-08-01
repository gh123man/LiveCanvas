//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI


struct TapHandle<ViewContext>: View {
    
    @Binding var viewModel: ViewState<ViewContext>
    var externalGeometry: GeometryProxy
    var onTap: (Binding<ViewState<ViewContext>>) -> ()
    
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
        Rectangle()
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .offset(offset)
            .foregroundColor(.clear)
            .position(position)
            .onTapGesture {
                onTap($viewModel)
            }
    }
}
