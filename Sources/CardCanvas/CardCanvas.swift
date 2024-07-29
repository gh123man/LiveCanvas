// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation


struct LiveCanvas<Content: View, ViewContext>: View {
    
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
                    
                    for i in viewModel.views.indices {
                        if let symbol = context.resolveSymbol(id: viewModel.views[i].id) {
                            
                            if let frame = viewModel.views[i].frame {
                                context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                            } else {
                                
                                let frame =  CGRect(x: geometry.size.width / 2, y: geometry.size.height / 2, width: symbol.size.width, height: symbol.size.height)
                                DispatchQueue.main.async {
                                    
                                    // Set initial position
                                    viewModel.views[i].frame = CGRect(x: (geometry.size.width - symbol.size.width) / 2,
                                                                 y: (geometry.size.height - symbol.size.height) / 2,
                                                                 width: symbol.size.width,
                                                                 height: symbol.size.height)
                                }
                                context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                            }
                            
                            
                        }
                    }
                    
                } symbols: {
                    ForEach(viewModel.views) { viewModel in
                        viewBuilder(viewModel.context)
                        .tag(viewModel.id)
                    }
                }.onTapGesture {
                    viewModel.select(nil)
                }
                
                ForEach($viewModel.views) { $vm in
                    TapHandle(viewModel: $vm, externalGeometry: geometry) { val in
                        viewModel.selectedIndex = viewModel.views.firstIndex { $0.id == val.id } ?? 0
                    }
                }
                
                if let selected = viewModel.selected {
                    MoveHandle(selected: selected, externalGeometry: geometry)
                    SizeHandle(selected: selected, externalGeometry: geometry)
                }
//                EditHandle(viewModel: viewModel, selected: viewModel.selected, externalGeometry: geometry)
            }
        }
        .aspectRatio(0.77, contentMode: .fit)
    }
}


struct DemoView: View {
    
    enum MyViewContext {
        case text(String)
    }
    
    @State var edit = false
    @State var text = "foobar"
    
    @ObservedObject var vm = LiveCanvasViewModel<MyViewContext>(viewModels: [
        ViewState(.text("foo"))
    ])
    
    
    var body: some View {
        VStack(spacing: 20) {
            LiveCanvas(viewModel: vm) { context in
                switch context {
                case let .text(txt):
                    Text(txt)
                }
            }
            .contentShape(Rectangle())
            .shadow(radius: 20)
            
            HStack {
                if let selected = vm.selected {
                    Button("Edit") {
                        
                    }
                    Button("Delete") {
                        vm.remove(selected.wrappedValue)
                    }
                } else {
                    Spacer()
                    Text("Select something")
                }
                Spacer()

            }
            .padding()
            .frame(height: 50)
            .background(.white)
            .cornerRadius(15)
            .shadow(radius: 20)
            
            HStack {
                Button("Add Text") {
                    vm.add(ViewState(.text("bar")))
                }
            }
        }
        .padding()
    }
}
#Preview {
    DemoView()
}
