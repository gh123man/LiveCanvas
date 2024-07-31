//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/31/24.
//

import Foundation

extension CGSize {
    func mul(_ s: CGSize) -> CGSize {
        CGSize(width: width * s.width, height: height * s.height)
    }
}

extension CGPoint {
    func mul(_ s: CGSize) -> CGPoint {
        CGPoint(x: x * s.width, y: y * s.height)
    }
}


extension CGRect {
    func mul(_ s: CGSize) -> CGRect {
        CGRect(origin: origin.mul(s), size: size.mul(s))
    }
}
