//
//  SIMD2.swift
//  Map View
//
//  Created by Robert Pugh on 2022-01-10.
//  Copyright © 2022 Attractions.io. All rights reserved.
//

import simd

extension SIMD2 where Scalar == Float {
	var length: Float {
		simd_length(self)
	}
}

extension SIMD2 where Scalar == Double {
	var length: Double {
		simd_length(self)
	}
}
