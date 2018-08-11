//
//  Endpoint.swift
//  Swiftygram
//
//  Created by Zap on 08.08.2018.
//

import Foundation

typealias Endpoint = RequestableObject & DefinedObject & Encodable

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

        var components = baseURLComponents(with: token, path: path)

        let jsonData = try encoder.encode(self)
        let json     = try JSONSerialization.jsonObject(with: jsonData) as! [String : Any]

        components.queryItems = json.map {
            (element) in URLQueryItem(name: element.key, value: String(describing: element.value))
        }

        guard let url = components.url else {
            throw APIMethodError.baseUrlCompositionFailure
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")

        if case .data(let data) = document {
            request.httpBody = data
        } else if case .some(.data(let data)) = thumb { // TODO: clarify how file upload is supposed
            request.httpBody = data                     //       to be working in case both document and thumb are data
        }

        return request
    }
}
