//
//  FloatingPoint.swift
//  Map View
//
//  Created by Robert Pugh on 2018-05-14.
//  Copyright © 2018 Attractions.io. All rights reserved.
//

extension FloatingPoint {
	var squared: Self {
		self * self
	}
	
	var degreesToRadians: Self {
		self * .pi / 180
	}
	
	var radiansToDegrees: Self {
		self * 180 / .pi
	}
	
	static var tau: Self {
		.pi * 2
	}
	
	static func % (lhs: Self, rhs: Self) -> Self {
		lhs - rhs * (lhs / rhs).rounded(.down)
	}
}
