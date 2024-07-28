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
//                        print(externalGeometry.frame(in: .local).size)
                        if gesture.location.x < 0 {
                            pos.x = 0
                        }
                        if gesture.location.y < 0 {
                            pos.y = 0
                        }
                        if gesture.location.x > externalGeometry.size.width {
                            pos.x = externalGeometry.size.width
                        }
                        if gesture.location.y > externalGeometry.size.height {
                            pos.y = externalGeometry.size.height
                        }
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
    
    var body: some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(.green)
            .position(calcPosition)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        var pos = gesture.location
                        if gesture.location.x < 0 {
                            pos.x = 0
                        }
                        if gesture.location.y < 0 {
                            pos.y = 0
                        }
                        if gesture.location.x > externalGeometry.size.width {
                            pos.x = externalGeometry.size.width
                        }
                        if gesture.location.y > externalGeometry.size.height {
                            pos.y = externalGeometry.size.height
                        }
                        handlePos = pos
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
                        DispatchQueue.main.async {
                            if textModel.frame == nil {
                                textModel.frame = symbol.size
                            }
                        }
                        context.draw(symbol, in: CGRect(origin: textModel.position, size: symbol.size))
                    }
                    
                    
                } symbols: {
                    Text("foo bar")
                        .foregroundColor(.red)
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
