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
        case fullScreen
    }
    
    @State var edit = false
    @State var editText = ""
    @State var showEditText = false
    
    @ObservedObject var vm = LiveCanvasViewModel<MyViewContext>(viewModels: [
        ViewState(.text("foo"))
    ])
    
    
    var body: some View {
        VStack(spacing: 20) {
            LiveCanvas(viewModel: vm) { context in
                switch context {
                case let .text(txt):
                    Text(txt)
                case .image:
                    Text("🖕")
                case .fullScreen:
                    Image(systemName: "pencil.and.ruler")
                }
            }
            .aspectRatio(0.77, contentMode: .fit)
            .contentShape(Rectangle())
            .shadow(radius: 20)
            
            HStack {
                if let selected = vm.selected {
                    if case let .text(val) = selected.wrappedValue.context {
                        Button("Edit") {
                            showEditText.toggle()
                            
                            editText = val
                        }
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
            
            HStack(spacing: 20) {
                Button("Add Text") {
                    vm.add(ViewState(.text("bar 123123")))
                }
                Button("Add Image") {
                    vm.add(ViewState(.image, resize: .proportional))
                }
                Button("Add background") {
                    vm.add(ViewState(.fullScreen,
                                     initialSize: .fill,
                                     movable: false,
                                     resize: .disabled),
                           at: .bottom)
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
