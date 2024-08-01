//
//  File.swift
//  
//
//  Created by Brian Floersch on 8/1/24.
//

import Foundation
extension Array {
    mutating func moveUp(from index: Int) {
        move(from: index, to: index + 1)
    }

    mutating func moveDown(from index: Int) {
        move(from: index, to: index - 1)
    }

    mutating func moveToBottom(from index: Int) {
        move(from: index, to: 0)
    }

    mutating func moveToTop(from index: Int) {
        guard index >= 0 && index < self.count else { return }
        let element = self.remove(at: index)
        self.append(element)
    }
    
    mutating func move(from: Int, to: Int) {
        guard from >= 0 && from < self.count else { return }
        guard to >= 0 && to < self.count else { return }
        let element = self.remove(at: from)
        self.insert(element, at: to)
    }
}
