//
//  Float4.swift
//  Map View
//
//  Created by Robert Pugh on 2021-10-29.
//  Copyright © 2021 Attractions.io. All rights reserved.
//

import simd

typealias Float4 = SIMD4<Float>

extension Float4 {
	/// The first three components of the vector.
	var xyz: Float3 {
		Float3(x, y, z)
	}
}
