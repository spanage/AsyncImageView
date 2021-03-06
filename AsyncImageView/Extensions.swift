//
//  Extensions.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/24/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

extension UIImage: NSDataConvertible {
	// init(data:) is already implemented by UIImage.

	public var data: NSData? {
		return UIImagePNGRepresentation(self)
	}
}

extension ImageResult: NSDataConvertible {
	public init?(data: NSData) {
		if let image = UIImage(data: data) {
			self.init(
				image: image,
				cacheHit: false
			)
		} else {
			return nil
		}
	}

	public var data: NSData? {
		return self.image.data
	}
}
