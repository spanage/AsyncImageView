//
//  RemoteImageRenderer.swift
//  AsyncImageView
//
//  Created by Nacho Soto on 11/22/15.
//  Copyright © 2015 Nacho Soto. All rights reserved.
//

import UIKit

import ReactiveCocoa
import Result

public protocol RemoteRenderDataType: RenderDataType {
    var imageURL: NSURL { get }
}

public protocol AuthenticatedRemoteRenderDataType: RemoteRenderDataType {
    var username: String { get }
    var password: String { get }
}

/// `RendererType` which downloads images from an endpoint requiring basic auth.
///
/// Note that this Renderer will ignore `RenderDataType.size` and instead
/// download the original image.
/// Consider chaining this with `ImageInflaterRenderer`.
public final class AuthenticatedRemoteImageRenderer<T: AuthenticatedRemoteRenderDataType>: RendererType {
    private let session: NSURLSession
    
    public init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
    }
    
    public func renderImageWithData(data: T) -> SignalProducer<UIImage, RemoteImageRendererError> {
        let request = NSMutableURLRequest(URL: data.imageURL)
        request.setValue(authorizationHeader(user: data.username, password: data.password), forHTTPHeaderField: "Authorization")
        return renderImageWithRequest(request, session: self.session)
    }
}

/// `RendererType` which downloads images.
///
/// Note that this Renderer will ignore `RenderDataType.size` and instead
/// download the original image.
/// Consider chaining this with `ImageInflaterRenderer`.
public final class RemoteImageRenderer<T: RemoteRenderDataType>: RendererType {
    private let session: NSURLSession
    
    public init(session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
    }
    
    public func renderImageWithData(data: T) -> SignalProducer<UIImage, RemoteImageRendererError> {
        return renderImageWithRequest(NSURLRequest(URL: data.imageURL), session: self.session)
    }
}

private func renderImageWithRequest(request: NSURLRequest, session: NSURLSession) -> SignalProducer<UIImage, RemoteImageRendererError> {
    return session.rac_dataWithRequest(request)
        .mapError(RemoteImageRendererError.LoadingError)
        .attemptMap { (data, response) in
            Result(
                (response as? NSHTTPURLResponse).map { (data, $0) },
                failWith: .InvalidResponse
            )
        }
        .flatMap(.Merge) { (data, response) -> SignalProducer<NSData, RemoteImageRendererError> in
            let statusCode = response.statusCode
            
            if statusCode >= 200 && statusCode < 300 {
                return SignalProducer(value: data)
            } else {
                return SignalProducer(error: .InvalidStatusCode(statusCode: statusCode))
            }
        }
        .observeOn(QueueScheduler())
        .flatMap(.Merge) { data in
            return SignalProducer
                .attempt {
                    return Result(
                        UIImage(data: data),
                        failWith: RemoteImageRendererError.DecodingError
                    )
            }
    }
}

private func authorizationHeader(user user: String, password: String) -> String {
    guard let data = "\(user):\(password)".dataUsingEncoding(NSUTF8StringEncoding) else { return "" }
    
    let credential = data.base64EncodedStringWithOptions([])
    
    return "Basic \(credential)"
}

public enum RemoteImageRendererError: ErrorType {
    case LoadingError(originalError: NSError)
    case InvalidResponse
    case InvalidStatusCode(statusCode: Int)
    case DecodingError
}
