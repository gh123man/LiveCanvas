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
    public var selectable: Bool
    public var resize: Resize

    
    public init(_ context: ViewContext, initialSize: InitialSize = .intrinsic, selectable: Bool = true, movable: Bool = true, resize: Resize = .any) {
        self.id = UUID()
        self.context = context
        self.initialSize = initialSize
        self.selectable = selectable
        self.movable = movable
        self.resize = resize
    }
}

public class LiveCanvasViewModel<ViewContext>: ObservableObject {
    
    public enum Level {
        case front
        case back
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
    
    @discardableResult
    public func add(_ viewModel: Layer<ViewContext>, at position: Level = .front) -> Binding<Layer<ViewContext>> {
        switch position {
        case .front:
            layers.append(viewModel)
            select(index: layers.count - 1)
            return get(index: layers.count - 1)
        case .back:
            layers.insert(viewModel, at: 0)
            select(index: 0)
            return get(index: 0)
        case .index(let idx):
            layers.insert(viewModel, at: idx)
            select(index: idx)
            return get(index: idx)
        }
    }
    
    private func idFor(index: Int) -> UUID {
        return layers[index].id
    }
    
    // Unsafe - this function assumes the ID exists in the layers.
    // careful internal use only
    private func indexFor(id: UUID) -> Int {
        layers.firstIndex(where: { $0.id == id })!
    }
    
    public func get(index: Int) -> Binding<Layer<ViewContext>> {
        
        // Index is unstable due to reordering so capture the ID and lookup the index
        // so returned bindings are consistent.
        let id = idFor(index: index)
        return Binding(
            get: {
                self.layers[self.indexFor(id: id)]
            },
            set: { newValue in
                self.layers[self.indexFor(id: id)] = newValue
            }
        )
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
        selected = get(index: index)
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
            viewModel.wrappedValue.frame.origin.x = size.width - viewModel.wrappedValue.frame.width
        case .top:
            viewModel.wrappedValue.frame.origin.y = 0
        case .bottom:
            viewModel.wrappedValue.frame.origin.y = size.height - viewModel.wrappedValue.frame.height
        case .horizontal:
            viewModel.wrappedValue.frame.origin.x = (size.width - viewModel.wrappedValue.frame.size.width) / 2
        case .vertical:
            viewModel.wrappedValue.frame.origin.y = (size.height - viewModel.wrappedValue.frame.size.height) / 2
        case .center:
            viewModel.wrappedValue.frame.origin.x = (size.width - viewModel.wrappedValue.frame.size.width) / 2
            viewModel.wrappedValue.frame.origin.y = (size.height - viewModel.wrappedValue.frame.size.height) / 2
        }
    }
    
    public func render(to size: CGSize? = nil) -> UIImage? {
        return snapshotFunc?(size)
    }
    
}
