// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation


struct ViewModel: Identifiable {
    var view: AnyView
    var frame: CGRect?
    var id: UUID
    var onEdit: (() -> ())?
    
    init(viewBuilder: () -> some View, onEdit: (() -> ())? = nil) {
        self.view = AnyView(erasing: viewBuilder())
        self.id = UUID()
        self.onEdit = onEdit
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
                                    viewModels[i].frame = CGRect(x: (geometry.size.width - symbol.size.width) / 2,
                                                                 y: (geometry.size.height - symbol.size.height) / 2,
                                                                 width: symbol.size.width,
                                                                 height: symbol.size.height)
                                }
                                context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                            }
                            
                        }
                    }
                    
                } symbols: {
                    ForEach(viewModels) { viewModel in
                        VStack {
                            viewModel.view
                                .fixedSize()
                        }
                        .tag(viewModel.id)
                    }
                }
                
                ForEach($viewModels) { $viewModel in
                    TapHandle(viewModel: $viewModel, externalGeometry: geometry) { val in
                        selectedIndex = viewModels.firstIndex { $0.id == val.id } ?? 0
                    }
                }
                
                MoveHandle(viewModel: $viewModels[selectedIndex], externalGeometry: geometry)
                SizeHandle(viewModel: $viewModels[selectedIndex], externalGeometry: geometry)
                EditHandle(viewModel: $viewModels[selectedIndex], externalGeometry: geometry)
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
            } onEdit: {
                print("edit")
                
            },
            ViewModel {
                Text("🌴")
            },
            ViewModel {
                Image(systemName: "photo.artframe")
                    .resizable()
                    .frame(width: 200, height: 200)
                
            },
            
        ])
            .padding()
            .contentShape(Rectangle())
            .shadow(radius: 20)
    }
}
