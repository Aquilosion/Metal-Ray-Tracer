//
//  Float3.swift
//  Map View
//
//  Created by Robert Pugh on 2021-10-29.
//  Copyright © 2021 Attractions.io. All rights reserved.
//

import simd

typealias Float3 = SIMD3<Float>

extension Float3 {
	/// The vector normalised such that it has a length of 1.
	var normalized: Float3 {
		normalize(self)
	}
	
	/// The first two components of the vector.
	var xy: Float2 {
		Float2(x, y)
	}
	
	/// The vector transformed by the given transformation matrix.
	func transformed(by matrix: Matrix4) -> Float3 {
		let transformVector = Float4(self, 1)
		let transformed = matrix * transformVector
		let division = transformed / transformed.w
		
		return division.xyz
	}
	
	/// The angle between this vector and the other vector.
	func angle(to other: Float3) -> Float {
		acos(dot(self, other) / (self.length * other.length))
	}
}

/// The cross product of two vectors.
func cross(_ a: Float3, _ b: Float3) -> Float3 {
	simd_cross(a, b)
}

/// The dot product of two vectors.
func dot(_ a: Float3, _ b: Float3) -> Float {
	simd_dot(a, b)
}
