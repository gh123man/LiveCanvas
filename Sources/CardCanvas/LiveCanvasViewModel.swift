//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/29/24.
//

import Foundation
import SwiftUI

struct ViewState<ViewContext>: Identifiable {
    
    enum InitialSize {
        case fill
        case intrinsic
    }
    
    enum Resize {
        case any
        case disabled
    }
    
    var frame: CGRect?
    var id: UUID
    var context: ViewContext
    var initialSize: InitialSize
    var movable: Bool
    var resize: Resize

    
    init(_ context: ViewContext, initialSize: InitialSize = .intrinsic, movable: Bool = true, resize: Resize = .any) {
        self.id = UUID()
        self.context = context
        self.initialSize = initialSize
        self.movable = movable
        self.resize = resize
    }
}

class LiveCanvasViewModel<ViewContext>: ObservableObject {
    
    enum Position {
        case top
        case bottom
        case index(Int)
    }
    
    @Published var views: [ViewState<ViewContext>]
    @Published var selectedIndex: Int? = nil
    
    var selected: Binding<ViewState<ViewContext>>? {
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
    
    init(viewModels: [ViewState<ViewContext>] = []) {
        self.views = viewModels
    }
    
    func add(_ viewModel: ViewState<ViewContext>, at position: Position = .top) {
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
    
    func select(_ viewModel: ViewState<ViewContext>?) {
        if let viewModel = viewModel {
            selectedIndex = views.firstIndex { $0.id == viewModel.id }
        } else {
            selectedIndex = nil
        }
    }
    
    func remove(_ viewModel: ViewState<ViewContext>) {
        if let idx = views.firstIndex(where: { $0.id == viewModel.id }) {
            if selectedIndex == idx {
                selectedIndex = nil
            }
            views.remove(at: idx)
        }
    }
    
}
