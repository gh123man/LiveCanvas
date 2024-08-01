//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/29/24.
//

import Foundation
import SwiftUI

public struct ViewState<ViewContext>: Identifiable {
    
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
    
    @Published public var views: [ViewState<ViewContext>]
    @Published var selectedIndex: Int? = nil
    var size: CGSize?
    public var canvasSize: CGSize? {
        return size
    }
    
    var snapshotFunc: ((CGSize?) -> UIImage?)?
    
    public var selected: Binding<ViewState<ViewContext>>? {
        guard let selectedIndex = selectedIndex else {
            return nil
        }
        return Binding(
            get: {
                self.views[selectedIndex]
            },
            set: { newValue in
                self.views[selectedIndex] = newValue
            }
        )
    }
    
    public init(viewModels: [ViewState<ViewContext>] = []) {
        self.views = viewModels
    }
    
    public func add(_ viewModel: ViewState<ViewContext>, at position: Position = .top) {
        switch position {
        case .top:
            views.append(viewModel)
            selectedIndex = views.count - 1
        case .bottom:
            views.insert(viewModel, at: 0)
            selectedIndex = 0
        case .index(let idx):
            views.insert(viewModel, at: idx)
            selectedIndex = idx
        }
    }
    
    public func select(_ viewModel: ViewState<ViewContext>?) {
        if let viewModel = viewModel {
            selectedIndex = views.firstIndex { $0.id == viewModel.id }
        } else {
            selectedIndex = nil
        }
    }
    
    public func remove(_ viewModel: ViewState<ViewContext>) {
        if let idx = views.firstIndex(where: { $0.id == viewModel.id }) {
            if selectedIndex == idx {
                selectedIndex = nil
            }
            views.remove(at: idx)
        }
    }
    
    public func align(_ viewModel: Binding<ViewState<ViewContext>>, position: Alignment) {
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
