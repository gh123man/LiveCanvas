// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

public struct LiveCanvas<Content: View, ViewContext>: View {
    
    @ObservedObject public var viewModel: LiveCanvasViewModel<ViewContext>
    @ViewBuilder public var viewBuilder: (ViewContext) -> Content
    
    public init(viewModel: LiveCanvasViewModel<ViewContext>, @ViewBuilder viewBuilder: @escaping (ViewContext) -> Content) {
        self.viewModel = viewModel
        self.viewBuilder = viewBuilder
        self.viewModel.snapshotFunc = snapshot
    }
    
    func canvas(originSize: CGSize, renderSize: CGSize, onPaint: (() -> ())? = nil) -> some View {
        Canvas(
            opaque: true,
            rendersAsynchronously: false
        ) { context, size in
            
            onPaint?()
            
            let offset = CGSize(width: renderSize.width / originSize.width, 
                                height: renderSize.height / originSize.height)
            
            let rect = CGRect(origin: .zero, size: size.mul(offset))
            let path = Rectangle().path(in: rect)
            context.fill(path, with: .color(.white))
            
            for i in viewModel.layers.indices {
                
                if let symbol = context.resolveSymbol(id: viewModel.layers[i].id) {
                    if viewModel.layers[i].frame != .null {
                        let frame = viewModel.layers[i].frame
                        context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size).mul(offset))
                        
                    } else {
                        
                        let frame: CGRect
                        switch viewModel.layers[i].initialSize {
                        case .fill:
                            // Fill the frame
                            frame = CGRect(origin: .zero, size: size)
                        case .intrinsic:
                            // Use the views intrinsic size and center it
                            frame = CGRect(origin: CGPoint(x: (size.width - symbol.size.width) / 2, y: (size.height - symbol.size.height) / 2),
                                           size: symbol.size)
                        }
                        
                        DispatchQueue.main.async {
                            // Set initial position
                            viewModel.layers[i].frame = frame
                        }
                        context.draw(symbol, in: frame.mul(offset))
                    }
                }
            }
            
        } symbols: {
            ForEach(viewModel.layers) { viewModel in
                viewBuilder(viewModel.context)
                .tag(viewModel.id)
            }
        }.onTapGesture {
            viewModel.select(nil)
        }
    }
    
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                canvas(originSize: geometry.size, renderSize: geometry.size) {
                    DispatchQueue.main.async {
                        viewModel.size = geometry.size
                    }
                }
                
                ForEach($viewModel.layers) { $vm in
                    TapHandle(viewModel: $vm, externalGeometry: geometry) { val in
                        viewModel.select(val)
                    }
                }
                
                if let selected = viewModel.selected {
                    if selected.wrappedValue.movable {
                        MoveHandle(selected: selected, externalGeometry: geometry)
                    }
                    if selected.wrappedValue.resize != .disabled {
                        SizeHandle(selected: selected, externalGeometry: geometry)
                    }
                }
                // Not needed?
//                EditHandle(viewModel: viewModel, selected: viewModel.selected, externalGeometry: geometry)
            }
        }
    }
    
    @MainActor
    func snapshot(to renderSize: CGSize?) -> UIImage? {
        guard let size = viewModel.size else {
            return nil
        }
        let controller = UIHostingController(rootView:
                                                canvas(originSize: size, renderSize: renderSize ?? size)
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea())
        
        let view = controller.view
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: renderSize ?? size)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

