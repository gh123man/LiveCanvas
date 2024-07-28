// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

struct TextModel {
    var text: String
    var position: CGPoint
    var frame: CGSize?
    var id: UUID
}

struct MoveHandle: View {
    
    @Binding var textModel: TextModel
    var externalGeometry: GeometryProxy
    
    var body: some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(.red)
            .position(textModel.position)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        var pos = gesture.location
                        
                        pos.x = gesture.location.x < 0 ? 0 : pos.x
                        pos.y = gesture.location.y < 0 ? 0 : pos.y
                        pos.x = gesture.location.x > externalGeometry.size.width ? externalGeometry.size.width : pos.x
                        pos.y = gesture.location.y > externalGeometry.size.height ? externalGeometry.size.height : pos.y
                        textModel.position = pos
                    }
            )
    }
}

struct SizeHandle: View {
    
    @Binding var textModel: TextModel
    @State var handlePos: CGPoint = .zero
    var externalGeometry: GeometryProxy
    
    var calcPosition: CGPoint {
        
        if let frame = textModel.frame {
            return CGPoint(x: textModel.position.x + frame.width, y: textModel.position.y + frame.height)
        }
        return CGPoint(x: textModel.position.x + 20, y: textModel.position.y + 20)
        
    }
    
    func computePosition() {
        if let frame = textModel.frame {
            handlePos = CGPoint(x: textModel.position.x + frame.width, y: textModel.position.y + frame.height)
        }
        
    }
    
    var body: some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(.green)
            .position(handlePos)
            .onChange(of: textModel.position) { _ in
                computePosition()
            }
            .onAppear {
                computePosition()
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        var pos = gesture.location
                        pos.x = gesture.location.x < 0 ? 0 : pos.x
                        pos.y = gesture.location.y < 0 ? 0 : pos.y
                        pos.x = gesture.location.x > externalGeometry.size.width ? externalGeometry.size.width : pos.x
                        pos.y = gesture.location.y > externalGeometry.size.height ? externalGeometry.size.height : pos.y
                        
                        
                        textModel.frame = CGSize(width: pos.x - textModel.position.x, height: pos.y - textModel.position.y)
                        computePosition()
                    }
            )
    }
}


struct Editor: View {
    
    @State var selectedGeometry: GeometryProxy? = nil
    @State var textModel = TextModel(text: "foobar", position: CGPoint(), id: UUID())
    
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
                    
                    if let symbol = context.resolveSymbol(id: textModel.id) {
                        
                        if let frame = textModel.frame {
                            context.draw(symbol, in: CGRect(origin: textModel.position, size: frame))
                        } else {
                            DispatchQueue.main.async {
                                textModel.frame = symbol.size
                            }
                            context.draw(symbol, in: CGRect(origin: textModel.position, size: symbol.size))
                        }
                        
                    }
                    
                    
                } symbols: {
                    VStack {
                        Text("foo bar")
                            .foregroundColor(.red)
//                            .rotationEffect(.degrees(30))
                    }
                    .tag(textModel.id)
                }
                
                MoveHandle(textModel: $textModel, externalGeometry: geometry)
                if textModel.frame != nil {
                    SizeHandle(textModel: $textModel, externalGeometry: geometry)
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
