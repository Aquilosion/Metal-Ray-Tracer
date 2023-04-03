//
//  SIMD3.swift
//  Map View
//
//  Created by Robert Pugh on 2022-01-10.
//  Copyright © 2022 Attractions.io. All rights reserved.
//

import simd

extension SIMD3 where Scalar == Float {
	static let up = SIMD3<Scalar>(x: 0, y: 0, z: 1)
	
	var length: Float {
		simd_length(self)
	}
}

extension SIMD3 where Scalar == Double {
	static let up = SIMD3<Scalar>(x: 0, y: 0, z: 1)
	
	var length: Double {
		simd_length(self)
	}
}
