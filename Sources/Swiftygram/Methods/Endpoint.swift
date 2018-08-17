//
//  Endpoint.swift
//  Swiftygram
//
//  Created by Zap on 08.08.2018.
//

import Foundation

typealias Endpoint = RequestableObject & DefinedObject

protocol RequestableObject {
	func request(for token: Token) throws -> URLRequest
}

protocol DefinedObject {
	var path: String { get }
}

extension DefinedObject {
	var path: String {
		let name = String(describing: type(of: self))
		return String(name.first!).lowercased() + name.dropFirst()
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

private let encoder: JSONEncoder = {
	let encoder = JSONEncoder()
	encoder.keyEncodingStrategy = .convertToSnakeCase
	return encoder
}()

extension RequestableObject where Self: DefinedObject, Self: Encodable {
	
	func request(for token: Token) throws -> URLRequest {
		
		guard let url = baseURLComponents(with: token, path: path).url else {
            throw APIMethodError.baseUrlCompositionFailure
        }
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let data = try encoder.encode(self)
		request.httpBody = data
		
		return request
	}
}

extension APIMethod.SendDocument {

    func request(for token: Token) throws -> URLRequest {

        let url = try baseURL(with: token, path: path)
        let multipartsData = try multiparts()
		
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\"\(multipartsData.boundary)\"", forHTTPHeaderField: "Content-Type")
		
        request.httpBody = try multipartsData.encode()
        return request
    }

    private func multiparts() throws -> MultipartFormData {

        var multipartData = MultipartFormData()

        switch document {
        case .reference(let fileId):
            guard let fileIdEncoded = fileId.data(using: .utf8, allowLossyConversion: true) else {
                throw APIMethodError.stringEncodingFailed(fileId)
            }
            multipartData.append(fileIdEncoded, withName: "document")
        case let .file(name, data):
            multipartData.append(data, withName: "document", fileName: name, mimeType: "application/octet-stream")
        }

        guard let receiverEncoded = chatId.data else {
            throw APIMethodError.stringEncodingFailed(String(describing: chatId))
        }
        multipartData.append(receiverEncoded, withName: "chat_id")

        if let addedThumb = thumb {
            switch addedThumb {
            case .reference(let fileId):
                guard let fileIdEncoded = fileId.data(using: .utf8, allowLossyConversion: true) else {
                    throw APIMethodError.stringEncodingFailed(fileId)
                }
                multipartData.append(fileIdEncoded, withName: "thumb")
            case let .file(name, data):
                multipartData.append(data, withName: "thumb", fileName: name, mimeType: "application/octet-stream")
            }
        }

        if let addedCaption = caption {
            guard let captionEncoded = addedCaption.data(using: .utf8, allowLossyConversion: false) else {
                throw APIMethodError.stringEncodingFailed(addedCaption)
            }
            multipartData.append(captionEncoded, withName: "caption")
        }

        // TODO: add other arguments

        return multipartData
    }
}
