// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

extension LiveCanvas {
    public init(viewModel: LiveCanvasViewModel<ViewContext>,
                @ViewBuilder viewBuilder: @escaping (Layer<ViewContext>) -> Content) 
    where OverlayContent.Type == EmptyView.Type {
        self.init(viewModel: viewModel, viewBuilder: viewBuilder, overlayControls: { _, _ in })
    }
}

public struct LiveCanvas<Content: View, OverlayContent: View, ViewContext>: View {
    
    @ObservedObject public var viewModel: LiveCanvasViewModel<ViewContext>
    @ViewBuilder public var viewBuilder: (Layer<ViewContext>) -> Content
    @ViewBuilder var overlayControls: (Binding<Layer<ViewContext>>, Bool) -> OverlayContent

    public init(viewModel: LiveCanvasViewModel<ViewContext>,
                @ViewBuilder viewBuilder: @escaping (Layer<ViewContext>) -> Content,
                @ViewBuilder overlayControls: @escaping (Binding<Layer<ViewContext>>, Bool) -> OverlayContent) {
        self.viewModel = viewModel
        self.viewBuilder = viewBuilder
        self.overlayControls = overlayControls
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
                        case .size(let userSize):
                            // User set size
                            frame = CGRect(origin: CGPoint(x: (size.width - userSize.width ) / 2, y: (size.height - userSize.height) / 2),
                                           size: userSize)
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
                viewBuilder(viewModel)
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
                    ControlHandle(viewModel: $vm, selected: viewModel.selected?.wrappedValue.id == vm.id, externalGeometry: geometry, overlayControls: overlayControls)
                }
                
                ForEach($viewModel.layers) { $vm in
                    if vm.selectable {
                        TapHandle(viewModel: $vm, externalGeometry: geometry) { val in
                            viewModel.select(val.id)
                        }
                    }
                }
                
                if let selected = viewModel.selected {
                    if selected.wrappedValue.movable {
                        MoveHandle(selected: selected, externalGeometry: geometry) {
                            viewModel.undoCheckpoint()
                        }
                    }
                    if selected.wrappedValue.resize != .disabled {
                        SizeHandle(selected: selected, externalGeometry: geometry) {
                           viewModel.undoCheckpoint()
                       }
                    }
                }
            }
        }
        .compositingGroup()
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

