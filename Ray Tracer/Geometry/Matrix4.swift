//
//  Matrix4.swift
//  Map View
//
//  Created by Robert Pugh on 2021-10-29.
//  Copyright © 2021 Attractions.io. All rights reserved.
//

import simd
import QuartzCore

typealias Matrix4 = matrix_float4x4

extension Matrix4 {
	/// The identity matrix.
	static let identity = matrix_identity_float4x4
	
	static func sceneMatrix(_ matrix: CATransform3D) -> Matrix4 {
		Matrix4(
			Float4(Float(matrix.m11), Float(matrix.m12), Float(matrix.m13), Float(matrix.m14)),
			Float4(Float(matrix.m21), Float(matrix.m22), Float(matrix.m23), Float(matrix.m24)),
			Float4(Float(matrix.m31), Float(matrix.m32), Float(matrix.m33), Float(matrix.m34)),
			Float4(Float(matrix.m41), Float(matrix.m42), Float(matrix.m43), Float(matrix.m44))
		)
	}
	
	/// A transformation matrix scaling by the given vector.
	static func scale(by s: Float3) -> Matrix4 {
		Matrix4(
			Float4(s.x, 0,   0,   0),
			Float4(0,   s.y, 0,   0),
			Float4(0,   0,   s.z, 0),
			Float4(0,   0,   0,   1)
		)
	}
	
	/// A transformation matrix scaling by the given scalar.
	static func scale(by s: Float) -> Matrix4 {
		Matrix4(
			Float4(s, 0, 0, 0),
			Float4(0, s, 0, 0),
			Float4(0, 0, s, 0),
			Float4(0, 0, 0, 1)
		)
	}
	
	/// A transformation matrix rotating about the given axis by the given angle (in radians).
	static func rotation(about axis: Float3, by angle: Float) -> Matrix4 {
		let (x, y, z) = (axis.x, axis.y, axis.z)
		
		let c = cos(angle)
		let s = sin(angle)
		
		let t = 1 - c
		
		return Matrix4(
			Float4(t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
			Float4(t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
			Float4(t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
			Float4(                0,                 0,                 0, 1)
		)
	}
	
	/// A transformation matrix translating by the given vector.
	static func translation(by t: Float3) -> Matrix4 {
		Matrix4(
			Float4(1, 0, 0, 0),
			Float4(0, 1, 0, 0),
			Float4(0, 0, 1, 0),
			Float4(t, 1)
		)
	}
	
	/// A perspective projection matrix using the right-hand rule.
	static func perspectiveProjection(fieldOfView: Float, aspectRatio: Float, zNear: Float, zFar: Float) -> Matrix4 {
		let yScale = 1 / tan(fieldOfView * 0.5)
		let xScale = yScale / aspectRatio
		let zRange = zFar - zNear
		let zScale = -(zFar + zNear) / zRange
		let wzScale = -2 * zFar * zNear / zRange
		
		let x = xScale
		let y = yScale
		let z = zScale
		let w = wzScale
		
		return Matrix4(
			Float4(x, 0, 0,  0),
			Float4(0, y, 0,  0),
			Float4(0, 0, z, -1),
			Float4(0, 0, w,  0)
		)
	}
	
	/// Multiplies the two matrices.
	static func * (lhs: Matrix4, rhs: Matrix4) -> Matrix4 {
		matrix_multiply(lhs, rhs)
	}
}
