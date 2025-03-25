//
//  File.swift
//
//
//  Created by Brian Floersch on 7/29/24.
//

import Foundation
import SwiftUI
import LiveCanvas

struct DemoView: View {
    enum MyViewContext {
        case text(String)
        case fixedSizeText(String)
        case image
        case recursiveSnapshot(UIImage)
        case fullScreen
    }
    
    @State var edit = false
    @State var editText = ""
    @State var showEditText = false
    
    @State var background: LayerID?

    @ObservedObject var vm = LiveCanvasViewModel<MyViewContext>(layers: .absolute([
        Layer(.text("Nora Rocks 🐱"))
    ]))
    
    let alignmentButtons: [(String, LiveCanvasViewModel<MyViewContext>.Alignment)] = [
        ("rectangle.center.inset.filled", .center),
        ("align.horizontal.center.fill", .horizontal),
        ("align.vertical.center.fill", .vertical),
        ("align.horizontal.left.fill", .left),
        ("align.horizontal.right.fill", .right),
        ("align.vertical.top.fill", .top),
        ("align.vertical.bottom.fill", .bottom)
    ]
    
    let layerButtons: [(String, LiveCanvasViewModel<MyViewContext>.LayerPosition)] = [
        ("square.2.layers.3d.top.filled", .up),
        ("square.2.layers.3d.bottom.filled", .down),
        ("square.3.layers.3d.top.filled", .front),
        ("square.3.layers.3d.bottom.filled", .back)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 20) {
                    Button(action: {
                        vm.undo()
                    }, label: {
                        Image(systemName: "arrow.uturn.backward")
                    })
                    .disabled(!vm.canUndo)
                    Button(action: {
                        vm.redo()
                    }, label: {
                        Image(systemName: "arrow.uturn.forward")
                    })
                    .disabled(!vm.canRedo)
                    
                }
                .padding(5)
                .background(.white)
                .cornerRadius(20)
                .shadow(radius: 20)
                Spacer()
            }
            
            LiveCanvas(viewModel: vm) { layer in
                switch layer.context {
                case let .text(txt):
                    Text(txt)
                case let .fixedSizeText(txt):
                    TextEditor(text: .constant(txt))
                        .frame(width: layer.frame.width < 20 ? 20 : layer.frame.width,
                               height: layer.frame.height < 20 ? 20 : layer.frame.height)
                case .image:
                    Image("nora2")
                case .recursiveSnapshot(let img):
                    Image(uiImage: img)
                case .fullScreen:
                    Image("nora1")
                }
            } controlOverlay: { layer, selected in
                if case let .fixedSizeText(txt) = layer.wrappedValue.context, selected {
                    TextEditor(text: $editText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: layer.wrappedValue.frame.width,
                               height: layer.wrappedValue.frame.height,
                               alignment: .top)
                        .onAppear {
                            editText = txt
                        }
                        .onChange(of: editText) {
                            layer.wrappedValue.context = .fixedSizeText(editText)
                        }
                        .background(.clear)
                    
                }
            } clipShape: { layer in
                Circle()
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
                        Button(action: { vm.remove(selected.id) }, label: {
                            Image(systemName: "trash.fill")
                        })
                        
                        if selected.wrappedValue.croppable {
                            Button(action: {
                                vm.cropSelected()
                            }) {
                                Image(systemName: "crop")
                            }
                        }
                        
                        ForEach(alignmentButtons, id: \.0) { imageName, alignment in
                            Button(action: { vm.align(selected.wrappedValue.id, to: alignment) }) {
                                Image(systemName: imageName)
                            }
                        }

                        ForEach(layerButtons, id: \.0) { imageName, position in
                            Button(action: { vm.moveLayer(selected.wrappedValue.id, position: position) }) {
                                Image(systemName: imageName)
                            }
                        }
                        
                        
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
                    vm.add(Layer(.text("bar 123123")))
                }
                Button("Add Paragraph") {
                    vm.add(Layer(.fixedSizeText("Paragraph"),
                                            initialSize: .size(CGSize(width: 100,
                                                                      height: 100))))
                }
                Button("Add Nora") {
                    vm.add(Layer(.image,
                                 minSize: CGSize(width: 1, height: 20),
                                 initialSize: .size(CGSize(width: 250, height: 180)),
                                 resize: .any,
                                 croppable: true
                                ))
                }
                Button("Render Snapshot") {
                    if let img = vm.render(to: CGSize(width: 100,
                                                      height: 100)) {
                        vm.add(Layer(.recursiveSnapshot(img),
                                     resize: .proportional))
                    }
                }
            }
            
            // handle specific layers in their own way - like the background.
            HStack(spacing: 20) {
                if let background = background, vm.layers[id: background] != nil {
                    Button("Chnage background") {
                        // Have to manually checkpoint if we change the content
                        vm.undoCheckpoint()
                        
                        // Can change the type of a layer at any time
                        vm.layers[id: background]?.context = .text("Foo")
                    }
                    Button("Delete background") {
                        vm.remove(background)
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
