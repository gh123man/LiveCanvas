// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

struct ViewModel: Identifiable {
    var view: AnyView
    var frame: CGRect?
    var id: UUID
    
    init(viewBuilder: () -> some View) {
        self.view = AnyView(erasing: viewBuilder())
        self.id = UUID()
    }
}


struct Editor: View {
    
    @State var selectedGeometry: GeometryProxy? = nil
    @State var viewModels: [ViewModel]
    @State var selectedIndex = 0
    
    
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
                    
                    for i in viewModels.indices {
                        
                        if let symbol = context.resolveSymbol(id: viewModels[i].id) {
                            
                            if let frame = viewModels[i].frame {
                                context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                            } else {
                                
                                let frame =  CGRect(x: geometry.size.width / 2, y: geometry.size.height / 2, width: symbol.size.width, height: symbol.size.height)
                                DispatchQueue.main.async {
                                    
                                    // Set initial position
                                    viewModels[i].frame = CGRect(x: geometry.size.width / 2, y: geometry.size.height / 2, width: symbol.size.width, height: symbol.size.height)
                                }
                                context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                            }
                            
                        }
                    }
                    
                } symbols: {
                    ForEach(viewModels) { viewModel in
                        VStack {
                            viewModel.view
                        }
                        .tag(viewModel.id)
                    }
                }
                
                MoveHandle(viewModel: $viewModels[selectedIndex], externalGeometry: geometry)
                if viewModels[selectedIndex].frame != nil {
                    SizeHandle(viewModel: $viewModels[selectedIndex], externalGeometry: geometry)
                }
            }
        }
        .aspectRatio(0.77, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#Preview {
    VStack {
        Editor(viewModels: [
            ViewModel {
                Text("foobar")
                    .foregroundColor(.red)
            },
            ViewModel {
                Text("test")
                    .foregroundColor(.blue)
            },
            
        ])
            .padding()
            .contentShape(Rectangle())
            .shadow(radius: 20)
    }
}
