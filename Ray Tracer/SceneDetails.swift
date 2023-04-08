//
//  SceneDetails.swift
//  Ray Tracer
//
//  Created by Robert Pugh on 2023-04-02.
//

import simd

struct Projection: Equatable {
	var size: SIMD2<Float>
	var projection: Matrix4
	var defocusStrength: Float
}

struct Material {
	var diffuse: SIMD3<Float>
	var emission: SIMD3<Float>
	var metalness: SIMD3<Float>
	var opacity: SIMD3<Float>
}

struct Sphere {
	var position: SIMD3<Float>
	var radius: Float
	var material: Material
}
