// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

struct ViewModel {
    var text: String
    var position: CGPoint
    var frame: CGSize?
    var id: UUID
}


struct Editor: View {
    
    @State var selectedGeometry: GeometryProxy? = nil
    @State var viewModel = ViewModel(text: "foobar", position: CGPoint(), id: UUID())
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
            
                Canvas(
                    opaque: true,
                    rendersAsynchronously: false
                ) { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    let path = Rectangle().path(in: rect)
                    context.fill(path, with: .color(.white))
                    
                    if let symbol = context.resolveSymbol(id: viewModel.id) {
                        
                        if let frame = viewModel.frame {
                            context.draw(symbol, in: CGRect(origin: viewModel.position, size: frame))
                        } else {
                            DispatchQueue.main.async {
                                viewModel.frame = symbol.size
                            }
                            context.draw(symbol, in: CGRect(origin: viewModel.position, size: symbol.size))
                        }
                        
                    }
                    
                    
                } symbols: {
                    VStack {
                        Text("foo bar")
                            .foregroundColor(.red)
//                            .rotationEffect(.degrees(30))
                    }
                    .tag(viewModel.id)
                }
                
                MoveHandle(ViewModel: $viewModel, externalGeometry: geometry)
                if viewModel.frame != nil {
                    SizeHandle(ViewModel: $viewModel, externalGeometry: geometry)
                }
            }
        }
        .aspectRatio(0.77, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#Preview {
    VStack {
        Editor()
            .padding()
            .contentShape(Rectangle())
            .shadow(radius: 20)
    }
}
