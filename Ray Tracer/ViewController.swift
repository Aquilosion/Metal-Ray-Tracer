//
//  ViewController.swift
//  Ray Tracer
//
//  Created by Robert Pugh on 2023-04-02.
//

import Cocoa
import Metal
import MetalKit
import SceneKit

class ViewController: NSViewController {
	let device = MTLCreateSystemDefaultDevice()!
	
	let renderer: Renderer
	
	var frameIndex = 0
	
	@IBOutlet var renderView: MTKView!
	
	required init?(coder: NSCoder) {
		renderer = Renderer(device: device)
		
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		prepareRendering()
	}
	
	override func viewDidAppear() {
		view.window?.makeFirstResponder(self)
	}
	
	override func keyDown(with event: NSEvent) {
		Task {
			switch event.keyCode {
			case 13: // W
				await renderer.setCameraVelocity(z: -0.1)
				
			case 0: // A
				await renderer.setCameraVelocity(x: -0.1)

			case 1: // S
				await renderer.setCameraVelocity(z: 0.1)

			case 2: // D
				await renderer.setCameraVelocity(x: 0.1)

			default:
				break
			}
		}
	}
	
	override func keyUp(with event: NSEvent) {
		Task {
			switch event.keyCode {
			case 13: // W
				await renderer.setCameraVelocity(z: 0)
				
			case 0: // A
				await renderer.setCameraVelocity(x: 0)
				
			case 1: // S
				await renderer.setCameraVelocity(z: 0)
				
			case 2: // D
				await renderer.setCameraVelocity(x: 0)
				
			default:
				break
			}
		}
	}
}

extension ViewController {
	// Called in main queue
	private func prepareRendering() {
		renderView.device = device
		renderView.colorPixelFormat = .rgba16Float
		renderView.framebufferOnly = false
		renderView.delegate = self
		
		renderView.isPaused = true
		renderView.enableSetNeedsDisplay = true
		
		if #available(macOS 14.0, *) {
			renderView.layer!.wantsExtendedDynamicRangeContent = true
		}
	}
}

extension ViewController: MTKViewDelegate {
	func draw(in view: MTKView) {
		Task {
			await renderer.draw(size: view.drawableSize, renderPassDescriptor: view.currentRenderPassDescriptor, drawable: view.currentDrawable)
			
			view.setNeedsDisplay(.infinite)
		}
	}
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		
	}
}
