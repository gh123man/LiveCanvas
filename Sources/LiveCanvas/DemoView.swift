//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/29/24.
//

import Foundation
import SwiftUI

struct DemoView: View {
    
    enum MyViewContext {
        case text(String)
        case image
        case recursiveSnapshot(UIImage)
        case fullScreen
    }
    
    @State var edit = false
    @State var editText = ""
    @State var showEditText = false
    @State var background: Binding<Layer<MyViewContext>>?
    @State var lastView: Binding<Layer<MyViewContext>>?

    @ObservedObject var vm = LiveCanvasViewModel<MyViewContext>(viewModels: [
        Layer(.text("Nora Rocks 🐱"))
    ])
    
    
    var body: some View {
        VStack(spacing: 20) {
            LiveCanvas(viewModel: vm) { context in
                switch context {
                case let .text(txt):
                    Text(txt)
                case .image:
                    Text("🖕")
                case .recursiveSnapshot(let img):
                    Image(uiImage: img)
                case .fullScreen:
                    Image(systemName: "pencil.and.ruler")
                }
            }
            .aspectRatio(0.77, contentMode: .fit)
            .contentShape(Rectangle())
            .shadow(radius: 20)
            
            ScrollView(.horizontal) {
                HStack {
                    if let selected = vm.selected {
                        if case let .text(val) = selected.wrappedValue.context {
                            Button(action: {
                                showEditText.toggle()
                                
                                editText = val
                            }, label: {
                                Image(systemName: "pencil.circle.fill")
                            })
                        }
                        // Delete
                        Button(action: {
                            vm.remove(selected)
                        }, label: {
                            Image(systemName: "trash.fill")
                        })
                        
                        // Alignment
                        Button(action: {
                            vm.align(selected, to: .center)
                        }, label: {
                            Image(systemName: "rectangle.center.inset.filled")
                        })
                        Button(action: {
                            vm.align(selected, to: .horizontal)
                        }, label: {
                            Image(systemName: "align.horizontal.center.fill")
                        })
                        Button(action: {
                            vm.align(selected, to: .vertical)
                        }, label: {
                            Image(systemName: "align.vertical.center.fill")
                        })
                        Button(action: {
                            vm.align(selected, to: .left)
                        }, label: {
                            Image(systemName: "align.horizontal.left.fill")
                        })
                        Button(action: {
                            vm.align(selected, to: .right)
                        }, label: {
                            Image(systemName: "align.horizontal.right.fill")
                        })
                        Button(action: {
                            vm.align(selected, to: .top)
                        }, label: {
                            Image(systemName: "align.vertical.top.fill")
                        })
                        Button(action: {
                            vm.align(selected, to: .bottom)
                        }, label: {
                            Image(systemName: "align.vertical.bottom.fill")
                        })
                        
                        // Layers
                        Button(action: {
                            vm.moveLayer(selected, position: .up)
                        }, label: {
                            Image(systemName: "square.2.layers.3d.top.filled")
                        })
                        Button(action: {
                            vm.moveLayer(selected, position: .down)
                        }, label: {
                            Image(systemName: "square.2.layers.3d.bottom.filled")
                        })
                        Button(action: {
                            vm.moveLayer(selected, position: .top)
                        }, label: {
                            Image(systemName: "square.3.layers.3d.top.filled")
                        })
                        Button(action: {
                            vm.moveLayer(selected, position: .bottom)
                        }, label: {
                            Image(systemName: "square.3.layers.3d.bottom.filled")
                        })
                        
                        
                        
                    } else {
                        Spacer()
                        Text("Select something")
                    }
                    Spacer()
                }
                .padding()
            }
            .frame(height: 50)
            .background(.white)
            .cornerRadius(15)
            .shadow(radius: 20)
            
            HStack(spacing: 20) {
                Button("Add Text") {
                    lastView = vm.add(Layer(.text("bar 123123")))
                }
                Button("Add Emoji") {
                    vm.add(Layer(.image, resize: .proportional))
                }
                Button("Render Snapshot") {
                    if let img = vm.render(to: CGSize(width: 100, height: 100)) {
                        vm.add(Layer(.recursiveSnapshot(img),
                                     resize: .proportional))
                    }
                }
                if let lastView = lastView {
                    Button("Delete last view") {
                        vm.remove(lastView)
                        self.lastView = nil
                    }
                }
            }
            
            // handle specific layers in their own way - like the background.
            HStack(spacing: 20) {
                if let background = background {
                    Button("mutate background") {
                        // Can change the type of a layer at any time
                        background.wrappedValue.context = .text("Foo")
                    }
                    Button("Delete background") {
                        vm.remove(background)
                        self.background = nil
                    }
                } else {
                    Button("Add background") {
                        if background == nil {
                            // Store a mutable reference to the background
                            background = vm.add(Layer(.fullScreen,
                                                      initialSize: .fill,
                                                      selectable: false,
                                                      movable: false,
                                                      resize: .disabled),
                                                at: .back)
                        }
                    }
                }
            }
        }
        .padding()
        .alert("Edit", isPresented: $showEditText) {
            TextField("", text: $editText)
            Button("OK") {
                vm.selected?.wrappedValue.context = .text(editText)
            }
        } message: {
        }
    }
}
#Preview {
    DemoView()
}
