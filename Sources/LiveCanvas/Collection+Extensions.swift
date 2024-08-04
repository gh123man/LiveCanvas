//
//  File.swift
//  
//
//  Created by Brian Floersch on 8/3/24.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Identifiable {
    subscript(id id: Element.ID) -> Element? {
        get {
            return self.first { $0.id == id }
        }
        set {
            if let index = self.firstIndex(where: { $0.id == id }) {
                if let newValue = newValue {
                    self[index] = newValue
                } else {
                    self.remove(at: index)
                }
            } else if let newValue = newValue {
                self.append(newValue)
            }
        }
    }
}
