// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

class LiveCanvasViewModel<ViewContext>: ObservableObject {
    
    @Published var viewModels: [ViewModel<ViewContext>]
    @Published var selectedIndex = 0
    
    var selected: Binding<ViewModel<ViewContext>> {
        Binding(
            get: {
                self.viewModels[self.selectedIndex]
            },
            set: { newValue in
                self.viewModels[self.selectedIndex] = newValue
            }
        )
    }
    
    init(viewModels: [ViewModel<ViewContext>] = []) {
        self.viewModels = viewModels
    }
    
    func add(_ viewModel: ViewModel<ViewContext>) {
        viewModels.append(viewModel)
    }
    
}

struct ViewModel<ViewContext>: Identifiable {
    var frame: CGRect?
    var id: UUID
    var context: ViewContext
//    var onEdit: ((ViewContext) -> ViewContext)?

//    init(_ context: ViewContext, onEdit: ((ViewContext) -> ViewContext)? = nil) {
    init(_ context: ViewContext) {
        self.id = UUID()
        self.context = context
//        self.onEdit = onEdit
    }
    
//    mutating func edit() {
//        self.context = onEdit?(context) ?? context
//   }
}


struct Editor<Content: View, ViewContext>: View {
    
    @State var selectedGeometry: GeometryProxy? = nil
    @ObservedObject var viewModel: LiveCanvasViewModel<ViewContext>
    
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
                    
                    for i in viewModel.viewModels.indices {
                        if let symbol = context.resolveSymbol(id: viewModel.viewModels[i].id) {
                            
                            if let frame = viewModel.viewModels[i].frame {
                                context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                            } else {
                                
                                let frame =  CGRect(x: geometry.size.width / 2, y: geometry.size.height / 2, width: symbol.size.width, height: symbol.size.height)
                                DispatchQueue.main.async {
                                    
                                    // Set initial position
                                    viewModel.viewModels[i].frame = CGRect(x: (geometry.size.width - symbol.size.width) / 2,
                                                                 y: (geometry.size.height - symbol.size.height) / 2,
                                                                 width: symbol.size.width,
                                                                 height: symbol.size.height)
                                }
                                context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                            }
                            
                            
                        }
                    }
                    
                } symbols: {
                    ForEach(viewModel.viewModels) { viewModel in
                        viewBuilder(viewModel.context)
                        .tag(viewModel.id)
                    }
                }
                
                ForEach($viewModel.viewModels) { $vm in
                    TapHandle(viewModel: $vm, externalGeometry: geometry) { val in
                        viewModel.selectedIndex = viewModel.viewModels.firstIndex { $0.id == val.id } ?? 0
                    }
                }
                
                MoveHandle(selected: viewModel.selected, externalGeometry: geometry)
                SizeHandle(selected: viewModel.selected, externalGeometry: geometry)
                EditHandle(viewModel: viewModel, selected: viewModel.selected, externalGeometry: geometry)
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
    
    @ObservedObject var vm = LiveCanvasViewModel<MyViewContext>(viewModels: [
        ViewModel(.text("foo"))
    ])
    
    
    var body: some View {
        VStack {
            Editor(viewModel: vm) { context in
                switch context {
                case let .text(txt):
                    Text(txt)
                }
            }
            .padding()
            .contentShape(Rectangle())
            .shadow(radius: 20)
            
            HStack {
                Button("Add Text") {
                    vm.add(ViewModel(.text("bar")))
                }
            }
        }
        
    }
}
#Preview {
    DemoView()
}
