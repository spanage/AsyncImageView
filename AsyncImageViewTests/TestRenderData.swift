//
//  TestRenderData.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit
import ReactiveCocoa

import Quick
import Nimble

@testable import AsyncImageView

internal enum TestData: CGFloat, Hashable {
	case A = 1.0
	case B = 2.0
	case C = 3.0
}

extension TestData: ImageViewDataType {
	var data: TestData {
		return self
	}

	func renderDataWithSize(size: CGSize) -> TestRenderData {
		return RenderData(data: self.data, size: size)
	}
}

internal struct TestRenderData: RenderDataType {
	let data: TestData
	let size: CGSize

	var hashValue: Int {
		return data.hashValue * size.width.hashValue * size.height.hashValue
	}
}

internal func ==(lhs: TestRenderData, rhs: TestRenderData) -> Bool {
	return (lhs.data == rhs.data &&
			lhs.size == rhs.size)
}

internal final class TestRenderer: RendererType {
	var renderedImages: Atomic<[TestRenderData]> = Atomic([])

	func renderImageWithData(data: TestRenderData) -> UIImage {
		let size = data.size

		assert(size.width > 0 && size.height > 0, "Should not attempt to render with invalid size: \(size)")

		self.renderedImages.modify { $0 + [data] }

		UIGraphicsBeginImageContextWithOptions(size, true, data.data.rawValue)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}
}

internal func verifyImage(@autoclosure(escaping) image: () -> UIImage?, withSize size: CGSize, data: TestData) {
	expect(expression: image).toNotEventually(beNil())

	guard let image = image() else { return }

	expect(image.size) == size
	expect(image.scale) == data.rawValue
}