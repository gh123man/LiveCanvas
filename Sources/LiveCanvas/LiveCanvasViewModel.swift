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
        case size(CGSize)
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
    
    public enum LayerPosition {
        case up, down, front, back
        case to(index: Int)
    }
    
    public enum Alignment {
        case left, right, top, bottom, horizontal, vertical, center
    }
    
    @Published public var layers: [Layer<ViewContext>]
    @Published public var undoStack: [[Layer<ViewContext>]] = []
    @Published public var redoStack: [[Layer<ViewContext>]] = []
    
    var canUndo: Bool {
        return !undoStack.isEmpty
    }
    
    var canRedo: Bool {
        return !redoStack.isEmpty
    }

    var size: CGSize?
    public var canvasSize: CGSize? {
        return size
    }
    
    var snapshotFunc: ((CGSize?) -> UIImage?)?
    
    @Published public var selected: Binding<Layer<ViewContext>>?
    
    public init(layers: [Layer<ViewContext>] = []) {
        self.layers = layers
    }
    
    @discardableResult
    public func add(_ viewModel: Layer<ViewContext>, at position: Level = .front) -> Binding<Layer<ViewContext>> {
        undoCheckpoint()
        switch position {
        case .front:
            layers.append(viewModel)
            if viewModel.selectable {
                select(index: layers.count - 1)
            }
            return get(index: layers.count - 1)
        case .back:
            layers.insert(viewModel, at: 0)
            if viewModel.selectable {
                select(index: 0)
            }
            return get(index: 0)
        case .index(let idx):
            layers.insert(viewModel, at: idx)
            if viewModel.selectable {
                select(index: idx)
            }
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
            undoCheckpoint()
            if selected?.wrappedValue.id == viewModel.id {
                selected = nil
            }
            layers.remove(at: idx)
        }
    }
    
    public func moveLayer(_ viewModel: Binding<Layer<ViewContext>>, position: LayerPosition) {
        undoCheckpoint()
        let index = indexFor(id: viewModel.id)
        switch position {
        case .up:
            layers.moveUp(from: index)
        case .down:
            layers.moveDown(from: index)
        case .front:
            layers.moveToTop(from: index)
        case .back:
            layers.moveToBottom(from: index)
        case .to(let toIndex):
            layers.move(from: index, to: toIndex)
        }
    }
    
    public func align(_ viewModel: Binding<Layer<ViewContext>>, to position: Alignment) {
        guard let size = size else {
            return
        }
        undoCheckpoint()
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
    
    public func undoCheckpoint() {
        undoStack.append(layers)
        redoStack = []
    }
    
    public func undo() {
        selected = nil
        if let last = undoStack.popLast() {
            redoStack.append(layers)
            layers = last
        }
    }
    
    public func redo() {
        selected = nil
        if let last = redoStack.popLast() {
            undoStack.append(layers)
            layers = last
        }
    }
    
}
