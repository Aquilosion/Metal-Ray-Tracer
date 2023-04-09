//
//  Renderer.swift
//  Ray Tracer
//
//  Created by Robert Pugh on 2023-04-09.
//

import MetalKit
import SceneKit

actor Renderer {
	let device: MTLDevice
	
	var texture: MTLTexture?
	
	let scene = SCNScene(named: "Scene.scn")!
	
	var previousProjection: Projection?
	
	var frameIndex = 0
	
	var cameraVelocity: SIMD3<Float> = .zero
	
	let pipeline: MTLComputePipelineState
	let commandQueue: MTLCommandQueue
	
	init(device: MTLDevice) {
		self.device = device
		
		let library = device.makeDefaultLibrary()!
		let function = library.makeFunction(name: "generateTexture")!
		
		pipeline = try! device.makeComputePipelineState(function: function)
		
		commandQueue = device.makeCommandQueue()!
	}
	
	func setCameraVelocity(x: Float? = nil, y: Float? = nil, z: Float? = nil) {
		if let x {
			cameraVelocity.x = x
		}
		
		if let y {
			cameraVelocity.y = y
		}
		
		if let z {
			cameraVelocity.z = z
		}
	}
	
	private func recreateTexture(size: CGSize) -> MTLTexture {
		let descriptor = MTLTextureDescriptor.texture2DDescriptor(
			pixelFormat: .rgba16Float,
			width: Int(size.width),
			height: Int(size.height),
			mipmapped: false
		)
		
		descriptor.usage = [ .shaderRead, .shaderWrite ]
		
		let newTexture = device.makeTexture(descriptor: descriptor)!
		texture = newTexture
		
		return newTexture
	}
	
	func draw(size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor?, drawable: CAMetalDrawable?) {
		let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)!
		let camera = cameraNode.camera!
		
		let texture: MTLTexture
		
		if let currentTexture = self.texture, currentTexture.width == Int(size.width) && currentTexture.height == Int(size.height) {
			texture = currentTexture
		} else {
			texture = recreateTexture(size: size)
		}
		
		let viewProjection = Matrix4.perspectiveProjection(
			fieldOfView: Float(camera.fieldOfView.degreesToRadians),
			aspectRatio: Float(texture.width) / Float(texture.height),
			zNear: Float(camera.zNear),
			zFar: Float(camera.zFar)
		) * Matrix4.sceneMatrix(cameraNode.transform).inverse
		
		var projection = Projection(
			size: .init(x: Float(texture.width), y: Float(texture.height)),
			projection: viewProjection.inverse,
			defocusStrength: 10
		)
		
		if projection != previousProjection {
			previousProjection = projection
			frameIndex = 0
		}
		
		let rotationTransform = Matrix4.rotation(about: cameraNode.simdRotation.xyz, by: cameraNode.simdRotation.w)
		let transformedVelocity = cameraVelocity.transformed(by: rotationTransform)
		
		cameraNode.simdPosition += transformedVelocity
		
		defer {
			self.frameIndex += 1
		}
		
		let commandBuffer = commandQueue.makeCommandBuffer()!
		let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
		
		commandEncoder.setComputePipelineState(pipeline)
		commandEncoder.setTexture(texture, index: 0)
		
		let frameIndexBuffer = device.makeBuffer(bytes: &frameIndex, length: MemoryLayout<UInt32>.stride)
		commandEncoder.setBuffer(frameIndexBuffer, offset: 0, index: 0)
		
		let projectionBuffer = device.makeBuffer(bytes: &projection, length: MemoryLayout<Projection>.stride)
		commandEncoder.setBuffer(projectionBuffer, offset: 0, index: 1)
		
		let sphereNodes = scene.rootNode.childNodes(passingTest: { node, stop in
			if node.geometry is SCNSphere {
				return true
			}
			
			return false
		})
		
		func materialColor(_ node: SCNNode, _ key: KeyPath<SCNMaterial, SCNMaterialProperty>) -> SIMD3<Float> {
			let contents = node.geometry!.materials[0][keyPath: key].contents
			
			if let color = contents as? NSColor {
				return Float3(x: Float(color.redComponent), y: Float(color.greenComponent), z: Float(color.blueComponent))
			} else if let number = contents as? NSNumber {
				return Float3(repeating: number.floatValue)
			} else {
				fatalError()
			}
		}
		
		var spheres = sphereNodes.map { node in
			Sphere(
				position: node.simdPosition,
				radius: Float((node.geometry as! SCNSphere).radius),
				material: Material(
					diffuse: materialColor(node, \.diffuse),
					emission: materialColor(node, \.emission) * 16,
					metalness: materialColor(node, \.metalness),
					opacity: materialColor(node, \.transparent)
				)
			)
		}
		
		var sphereCount = UInt32(spheres.count)
		
		let sphereCountBuffer = device.makeBuffer(bytes: &sphereCount, length: MemoryLayout<UInt32>.stride)
		commandEncoder.setBuffer(sphereCountBuffer, offset: 0, index: 2)
		
		let sphereBuffer = device.makeBuffer(bytes: &spheres, length: MemoryLayout<Sphere>.stride * spheres.count)
		commandEncoder.setBuffer(sphereBuffer, offset: 0, index: 3)
		
		let threadGroupCount = MTLSize(width: 16, height: 16, depth: 1)
		let threadGroups = MTLSize(
			width: texture.width / threadGroupCount.width + 1,
			height: texture.height / threadGroupCount.height + 1,
			depth: 1
		)
		
		commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
		commandEncoder.endEncoding()
		
		copyPixels: if let renderPassDescriptor {
			let renderTarget = renderPassDescriptor.colorAttachments[0].texture!
			
			guard renderTarget.width == texture.width && renderTarget.height == texture.height else {
				break copyPixels
			}
			
			let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
			
			blitEncoder.copy(
				from: texture,
				sourceSlice: 0,
				sourceLevel: 0,
				sourceOrigin: MTLOrigin(),
				sourceSize: MTLSize(
					width: texture.width,
					height: texture.height,
					depth: 1
				),
				to: renderTarget,
				destinationSlice: 0,
				destinationLevel: 0,
				destinationOrigin: MTLOrigin()
			)
			
			blitEncoder.endEncoding()
		}
		
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
		
		drawable?.present()
	}
}
