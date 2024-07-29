//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/29/24.
//

import Foundation
import SwiftUI

struct ViewState<ViewContext>: Identifiable {
    var frame: CGRect?
    var id: UUID
    var context: ViewContext
    init(_ context: ViewContext) {
        self.id = UUID()
        self.context = context
    }
}

class LiveCanvasViewModel<ViewContext>: ObservableObject {
    
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
    
    func add(_ viewModel: ViewState<ViewContext>) {
        views.append(viewModel)
        selectedIndex = views.count - 1
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
