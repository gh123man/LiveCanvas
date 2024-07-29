//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

import Foundation
import SwiftUI


struct TapHandle: View {
    
    @Binding var viewModel: ViewModel
    var externalGeometry: GeometryProxy
    var onTap: (Binding<ViewModel>) -> ()
    
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
