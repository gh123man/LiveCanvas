//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI


struct TapHandle<ViewContext>: View {
    
    @Binding var viewModel: Layer<ViewContext>
    var externalGeometry: GeometryProxy
    var onTap: (Binding<Layer<ViewContext>>) -> ()
    let minTapSize = CGSize(width: 20, height: 20)
    
    var size: CGSize {
        return viewModel.presentedFrame.size
    }
    
    var position: CGPoint {
        return viewModel.presentedFrame.origin
    }
    
    var offset: CGSize {
        return CGSize(width: size.width / 2, height: size.height / 2)
    }
    
    var body: some View {
        Rectangle()
            .frame(width: max(size.width, minTapSize.width), height: max(size.height, minTapSize.height))
            .contentShape(Rectangle())
            .offset(offset)
            .foregroundColor(.clear)
            .position(position)
            .onTapGesture {
                onTap($viewModel)
            }
    }
}
