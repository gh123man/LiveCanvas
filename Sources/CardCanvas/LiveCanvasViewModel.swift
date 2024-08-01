//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/29/24.
//

import Foundation
import SwiftUI

public struct Layer<ViewContext>: Identifiable {
    
    public enum InitialSize {
        case fill
        case intrinsic
    }
    
    public enum Resize {
        case any
        case proportional
        case disabled
    }
    
    public var frame: CGRect = .null
    public var id: UUID
    public var context: ViewContext
    public var initialSize: InitialSize
    public var movable: Bool
    public var resize: Resize

    
    public init(_ context: ViewContext, initialSize: InitialSize = .intrinsic, movable: Bool = true, resize: Resize = .any) {
        self.id = UUID()
        self.context = context
        self.initialSize = initialSize
        self.movable = movable
        self.resize = resize
    }
}

public class LiveCanvasViewModel<ViewContext>: ObservableObject {
    
    public enum Position {
        case top
        case bottom
        case index(Int)
    }
    
    public enum Alignment {
        case left, right, top, bottom, horizontal, vertical, center
    }
    
    @Published public var layers: [Layer<ViewContext>]
    var size: CGSize?
    public var canvasSize: CGSize? {
        return size
    }
    
    var snapshotFunc: ((CGSize?) -> UIImage?)?
    @Published public var selected: Binding<Layer<ViewContext>>?
    
    public init(viewModels: [Layer<ViewContext>] = []) {
        self.layers = viewModels
    }
    
    public func add(_ viewModel: Layer<ViewContext>, at position: Position = .top) {
        switch position {
        case .top:
            layers.append(viewModel)
            select(index: layers.count - 1)
        case .bottom:
            layers.insert(viewModel, at: 0)
            select(index: 0)
        case .index(let idx):
            layers.insert(viewModel, at: idx)
            select(index: idx)
        }
    }
    
    public func select(_ viewModel: Binding<Layer<ViewContext>>?) {
        if let viewModel = viewModel {
            guard let index = layers.firstIndex(where: { $0.id == viewModel.id }) else {
                return
            }
            select(index: index)
        } else {
            selected = nil
        }
    }
    
    public func select(index: Int) {
        selected = Binding(
            get: {
                self.layers[index]
            },
            set: { newValue in
                self.layers[index] = newValue
            }
        )
    }
    
    public func remove(_ viewModel: Binding<Layer<ViewContext>>) {
        if let idx = layers.firstIndex(where: { $0.id == viewModel.id }) {
            if selected?.wrappedValue.id == viewModel.id {
                selected = nil
            }
            layers.remove(at: idx)
        }
    }
    
    public func align(_ viewModel: Binding<Layer<ViewContext>>, position: Alignment) {
        guard let size = size else {
            return
        }
//        guard let idx = views.firstIndex(where: { $0.id == viewModel.id }) else {
//            return
//        }
        switch position {
        case .left:
            viewModel.wrappedValue.frame.origin.x = 0
        case .right:
            viewModel.wrappedValue.frame.origin.x = viewModel.wrappedValue.frame.width
        case .top:
            viewModel.wrappedValue.frame.origin.y = 0
        case .bottom:
            viewModel.wrappedValue.frame.origin.y = viewModel.wrappedValue.frame.height
        case .horizontal:
            break
        case .vertical:
            break
        case .center:
            break
        }
    }
    
    public func render(to size: CGSize? = nil) -> UIImage? {
        return snapshotFunc?(size)
    }
    
}
