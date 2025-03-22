//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/29/24.
//

import Foundation
import SwiftUI

public typealias LayerID = UUID

public struct Layer<ViewContext>: Identifiable {
    
    public enum InitialSize {
        case fill
        case fit(CGSize)
        case size(CGSize)
        case intrinsic
    }
    
    public enum Resize {
        case any
        case proportional
        case disabled
    }
    
    public var frame: CGRect
    public var clipFrame: CGRect?
    public var id: LayerID
    public var context: ViewContext
    public var initialSize: InitialSize
    public var movable: Bool
    public var selectable: Bool
    public var resize: Resize

    
    public init(_ context: ViewContext, id: UUID = UUID(), frame: CGRect = .null, clipFrame: CGRect? = nil, initialSize: InitialSize = .intrinsic, selectable: Bool = true, movable: Bool = true, resize: Resize = .any) {
        self.id = id
        self.frame = frame
        self.clipFrame = clipFrame
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
    private var unimportedLayers: LayerImport
    
    @Published public var layers: [Layer<ViewContext>] {
       didSet {
           if let id = selected?.id {
               select(id)
           }
       }
    }
    @Published public var undoStack: [[Layer<ViewContext>]] = []
    @Published public var redoStack: [[Layer<ViewContext>]] = []
    
    public var canUndo: Bool {
        return !undoStack.isEmpty
    }
    
    public var canRedo: Bool {
        return !redoStack.isEmpty
    }
    
    var size: CGSize?
    public var canvasSize: CGSize? {
        return size
    }
    
    var snapshotFunc: ((CGSize?) -> UIImage?)?
    
    @Published public var selected: Binding<Layer<ViewContext>>?
    
    public enum LayerImport {
        case absolute([Layer<ViewContext>])
        case relative([Layer<ViewContext>])
    }
    
    public init(layers: LayerImport) {
        self.layers = []
        self.unimportedLayers = layers
    }
    
    func denormalize(rect: CGRect, in size: CGSize) -> CGRect {
        if rect == .null { return rect }
        return CGRect(
            x: rect.origin.x * size.width,
            y: rect.origin.y * size.height,
            width: rect.size.width * size.width,
            height: rect.size.height * size.height
        )
    }
    
    func normalize(rect: CGRect, in size: CGSize) -> CGRect {
        if rect == .null { return rect }
        return CGRect(
            x: rect.origin.x / size.width,
            y: rect.origin.y / size.height,
            width: rect.size.width / size.width,
            height: rect.size.height / size.height
        )
    }
    
    func processRelativeLayers(size: CGSize) {
        switch unimportedLayers {
        case .absolute(let newLayers):
            self.layers = newLayers
            
        case .relative(var newLayers):
            for (i, l) in newLayers.enumerated() {
                newLayers[i].frame = denormalize(rect: l.frame, in: size)
            }
            self.layers = newLayers
        }
    }
    
    public func normalizedLayers() -> [Layer<ViewContext>] {
        guard let size = size else { return [] }
        var layers = self.layers
        for (i, layer) in layers.enumerated() {
            layers[i].frame = normalize(rect: layer.frame, in: size)
        }
        return layers
    }
    
    @discardableResult
    public func add(_ layer: Layer<ViewContext>, at position: Level = .front) -> LayerID {
        undoCheckpoint()
        switch position {
        case .front:
            layers.append(layer)
            if layer.selectable {
                select(index: layers.count - 1)
            }
            return layer.id
        case .back:
            layers.insert(layer, at: 0)
            if layer.selectable {
                select(index: 0)
            }
            return layer.id
        case .index(let idx):
            layers.insert(layer, at: idx)
            if layer.selectable {
                select(index: idx)
            }
            return layer.id
        }
    }
    
    private func indexFor(id: UUID) -> Int? {
        layers.firstIndex(where: { $0.id == id })
    }
    
    public func bindingFrom(id: LayerID) -> Binding<Layer<ViewContext>>? {
        guard let id = layers[id: id]?.id else {
            return nil
        }
        return Binding(
            get: { return self.layers[self.indexFor(id: id)!] },
            set: { newValue in
                self.layers[self.indexFor(id: id)!] = newValue
            }
        )
    }
    
    public func select(_ id: LayerID?) {
        if let id = id {
            selected = bindingFrom(id: id)
        } else {
            selected = nil
        }
    }
    
    public func select(index: Int) {
        select(layers[safe: index]?.id)
    }
    
    public func remove(_ id: LayerID) {
        guard let idx = indexFor(id: id) else {
            return
        }
        if selected?.id == id {
            selected = nil
        }
        undoCheckpoint()
        layers.remove(at: idx)
    }
    
    public func moveLayer(_ id: LayerID, position: LayerPosition) {
        guard let index = indexFor(id: id) else {
            return
        }
        
        undoCheckpoint()
            
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
    
    public func align(_ id: LayerID, to position: Alignment) {
        guard let size = size, let layer = bindingFrom(id: id) else {
            return
        }
        undoCheckpoint()
        switch position {
        case .left:
            layer.wrappedValue.frame.origin.x = 0
        case .right:
            layer.wrappedValue.frame.origin.x = size.width - layer.wrappedValue.frame.width
        case .top:
            layer.wrappedValue.frame.origin.y = 0
        case .bottom:
            layer.wrappedValue.frame.origin.y = size.height - layer.wrappedValue.frame.height
        case .horizontal:
            layer.wrappedValue.frame.origin.x = (size.width - layer.wrappedValue.frame.size.width) / 2
        case .vertical:
            layer.wrappedValue.frame.origin.y = (size.height - layer.wrappedValue.frame.size.height) / 2
        case .center:
            layer.wrappedValue.frame.origin.x = (size.width - layer.wrappedValue.frame.size.width) / 2
            layer.wrappedValue.frame.origin.y = (size.height - layer.wrappedValue.frame.size.height) / 2
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
