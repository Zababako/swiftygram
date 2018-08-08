//
// Created by Zap on 07.08.2018.
//

import Foundation


enum Method {
    case getMe
    case sendMessage(to: Receiver, text: String)
}

enum MethodError: Error {
    case baseUrlCompositionFailure
    case conflictingArguments
}

extension Method {

    func request(for token: Token, with additionalArguments: [String : Any] = [:]) throws -> URLRequest {

        let url = try composeURL(with: token)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let arguments = try coreArguments.merging(additionalArguments) {
            _, _ in throw MethodError.conflictingArguments
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: arguments)

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

        return authenticated.appendingPathComponent(name)
    }

    private var name: String {
        switch self {
        case .getMe:       return "getMe"
        case .sendMessage: return "sendMessage"
        }
    }

    private var coreArguments: [String : Any] {
        switch self {
        case     .getMe:                 return [:]
        case let .sendMessage(to, text): return [ "chat_id" : to.value, "text" : text]
        }
    }
}

private extension Receiver {
    var value: Any {
        switch self {
        case let .id(id):             return id
        case let .username(username): return username
        }
    }
}

