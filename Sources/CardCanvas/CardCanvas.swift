// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

//struct MovableView {
//    @State var offset = CGPoint.zero
//    
//    var moveHandle: some View {
//        MoveHandle(position: $offset)
//    }
//}

struct MoveHandle: View {
    
    @Binding var position: CGPoint
    var externalGeometry: GeometryProxy
    
    var body: some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(.red)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        var pos = gesture.location
                        print(externalGeometry.frame(in: .local).size)
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
                        position = pos
                    }
            )
    }
}

struct Editor: View {
    
    @State private var offset = CGPoint.zero
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
            
                Canvas(
                    opaque: true,
                    rendersAsynchronously: false
                ) { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    var path = Rectangle().path(in: rect)
                    context.fill(path, with: .color(.white))
                    
                    context.draw(Text("SwiftUI Canvas")
                        .bold()
                        .italic()
                        .foregroundColor(.green), at: offset)
                }
                
                MoveHandle(position: $offset, externalGeometry: geometry)
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
