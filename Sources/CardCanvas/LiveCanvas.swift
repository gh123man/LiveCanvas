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
    
    func canvas(size: CGSize, onPaint: (() -> ())? = nil) -> some View {
        Canvas(
            opaque: true,
            rendersAsynchronously: false
        ) { context, size in
            
            onPaint?()
            
            let rect = CGRect(origin: .zero, size: size)
            let path = Rectangle().path(in: rect)
            context.fill(path, with: .color(.white))
            
            
            
            for i in viewModel.views.indices {
                if let symbol = context.resolveSymbol(id: viewModel.views[i].id) {
                    
                    if let frame = viewModel.views[i].frame {
                        context.draw(symbol, in: CGRect(origin: frame.origin, size: frame.size))
                        
                    } else {
                        
                        let frame: CGRect
                        
                        switch viewModel.views[i].initialSize {
                        case .fill:
                            // Fill the frame
                            frame =  CGRect(x: 0,
                                            y: 0,
                                            width: size.width,
                                            height: size.height)
                        case .intrinsic:
                            // Use the views intrinsic size and center it
                            frame =  CGRect(x: (size.width - symbol.size.width) / 2,
                                            y: (size.height - symbol.size.height) / 2,
                                            width: symbol.size.width,
                                            height: symbol.size.height)
                        }
                        
                        DispatchQueue.main.async {
                            // Set initial position
                            viewModel.views[i].frame = frame
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
    }
    
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                canvas(size: geometry.size) {
                    DispatchQueue.main.async {
                        viewModel.size = geometry.size
                    }
                }
                
                ForEach($viewModel.views) { $vm in
                    TapHandle(viewModel: $vm, externalGeometry: geometry) { val in
                        viewModel.selectedIndex = viewModel.views.firstIndex { $0.id == val.id } ?? 0
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
    func snapshot() -> UIImage? {
        guard let size = viewModel.size else {
            return nil
        }
        let controller = UIHostingController(rootView: canvas(size: size).frame(width: size.width, height: size.height))
        let view = controller.view
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

