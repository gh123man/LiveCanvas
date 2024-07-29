// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation


struct ViewModel<ViewContext>: Identifiable {
    var frame: CGRect?
    var id: UUID
    var context: ViewContext
    var onEdit: ((ViewContext) -> ViewContext)?

    init(_ context: ViewContext, onEdit: ((ViewContext) -> ViewContext)? = nil) {
        self.id = UUID()
        self.context = context
        self.onEdit = onEdit
    }
    
    mutating func edit() {
        self.context = onEdit?(context) ?? context
   }
}


struct Editor<Content: View, ViewContext>: View {
    
    @State var selectedGeometry: GeometryProxy? = nil
    @State var viewModels: [ViewModel<ViewContext>]
    @State var selectedIndex = 0
    
    var viewBuilder: (ViewContext) -> Content
    
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
                        viewBuilder(viewModel.context)
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


struct DemoView: View {
    
    enum MyViewContext {
        case text(String)
    }
    
    @State var edit = false
    @State var text = "foobar"
    
    @State var models: [ViewModel<MyViewContext>] = [
        ViewModel(.text("foo")) { context in
            return .text("boop")
        }
    ]
    
    
    var body: some View {
        VStack {
            Editor(viewModels: models ) { context in
                switch context {
                case let .text(txt):
                    Text(txt)
                }
            }
        }
    }
}
#Preview {
    DemoView()
}
