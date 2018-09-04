//
//  Endpoint.swift
//  Swiftygram
//
//  Created by Zap on 08.08.2018.
//

import Foundation


/// Protocol that you need to conform to if you need to expand API coverage
///
/// There is default implementation for entities that already
/// conform to `Locatable` and `Contentable` protocols
public protocol Requestable {
	func request(for token: Token) throws -> URLRequest
}

/// URL path to endpoint (e.g. "getUpdates", "sendMessage", "getMe")
///
/// Default implementation of this protocol uses Self name with lowercased first letter
public protocol Locatable {
	var path: String { get }
}

/// Enum defining value of a `Content-type` in associated request
public enum Content {
    case json(body: Data)
    case multipart(boundary: String, body: Data)
}

/// Protocol for entities that know how they want to be sent
///
/// There is a default implementation for `Encodable` entities
public protocol Contentable {
    func content() throws -> Content
}


// Mark: - Default implementations

public extension Locatable {
    var path: String {
        let name = String(describing: type(of: self))
        return String(name.first!).lowercased() + name.dropFirst()
    }
}

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}()

public extension Contentable where Self: Encodable {
    func content() throws -> Content {
        return .json(body: try encoder.encode(self))
    }
}

public extension Requestable where Self: Contentable, Self: Locatable {

    public func request(for token: Token) throws -> URLRequest {

        let url = try baseURL(with: token, path: path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        switch try content() {
        case let .json(body):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

        case let .multipart(boundary, body):
            request.setValue("multipart/form-data; boundary=\"\(boundary)\"", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        return request
    }
}

extension APIMethod.SendDocument {

    func content() throws -> Content {
        let multipartsData = try multiparts()
        return .multipart(boundary: multipartsData.boundary, body: try multipartsData.encode())
    }

    private func multiparts() throws -> MultipartFormData {

        var multipartData = MultipartFormData()

        switch document {
        case .reference(let fileId):
            multipartData.append(
                try fileId.utf8Encoded(),
                withName: "document"
            )

        case let .file(name, data):
            multipartData.append(
                data,
                withName: "document",
                fileName: name,
                mimeType: "application/octet-stream"
            )
        }

        let receiverEncoded = try chatId.data()
        multipartData.append(receiverEncoded, withName: "chat_id")

        if let addedThumb = thumb {
            switch addedThumb {
            case .reference(let fileId):
                multipartData.append(
                    try fileId.utf8Encoded(),
                    withName: "thumb"
                )
            case let .file(name, data):
                multipartData.append(data, withName: "thumb", fileName: name, mimeType: "application/octet-stream")
            }
        }

        if let addedCaption = caption {

            multipartData.append(
                try addedCaption.utf8Encoded(),
                withName: "caption"
            )
        }

        // TODO: add other arguments

        return multipartData
    }
}


// MARK: - Private handlers

private extension String {

    func utf8Encoded() throws -> Data {
        if let encoded = data(using: .utf8, allowLossyConversion: false) {
            return encoded
        } else {
            throw APIMethodError.stringEncodingFailed(self)
        }
    }
}

/// https://core.telegram.org/bots/api#making-requests
private func baseURLComponents(with token: Token, path: String) -> URLComponents {

    var urlComponents = URLComponents()
    urlComponents.scheme             = "https"
    urlComponents.host               = "api.telegram.org"
    urlComponents.percentEncodedPath = "/bot\(token)/\(path)"

    return urlComponents
}

private func baseURL(with token: Token, path: String) throws -> URL {
    guard let url = baseURLComponents(with: token, path: path).url else {
        throw APIMethodError.baseUrlCompositionFailure
    }
    return url
}

