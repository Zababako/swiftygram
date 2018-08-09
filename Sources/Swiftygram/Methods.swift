//
// Created by Zap on 07.08.2018.
//

import Foundation

enum MethodError: Error {
    case baseUrlCompositionFailure
}

typealias Endpoint = RequestableObject & DefinedObject & Encodable

struct Method {

    struct GetUpdates: Endpoint {
        let offset:         Update.ID?
        let limit:          Int?
        let timeout:        Int?
        let allowedUpdates: [String]?
    }

    struct GetMe: Endpoint {}

    struct SendMessage: Endpoint {
        let chatId: Receiver
        let text:   String
    }
}

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

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}()

extension RequestableObject where Self: DefinedObject, Self: Encodable {

    func request(for token: Token) throws -> URLRequest {

        let url = try composeURL(with: token)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data = try encoder.encode(self)
        request.httpBody = data

        return request
    }

    /// https://core.telegram.org/bots/api#making-requests
    private func composeURL(with token: Token) throws -> URL {

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host   = "api.telegram.org"

        guard let base = urlComponents.url else {
            throw MethodError.baseUrlCompositionFailure
        }

        let authenticated = base.appendingPathComponent("bot\(token)")

        return authenticated.appendingPathComponent(path)
    }
}


