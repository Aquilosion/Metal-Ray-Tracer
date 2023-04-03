//
//  Float2.swift
//  Map View
//
//  Created by Robert Pugh on 2021-10-31.
//  Copyright © 2021 Attractions.io. All rights reserved.
//

import simd

typealias Float2 = SIMD2<Float>

extension Float2 {
	static let zero = Float2(x: 0, y: 0)
	
	static func - (lhs: Float2, rhs: Float2) -> Float2 {
		Float2(lhs.x - rhs.x, lhs.y - rhs.y)
	}
}

/// The cross product of two vectors.
func cross(_ a: Float2, _ b: Float2) -> Float {
	(a.x * b.y) - (a.y * b.x)
}
