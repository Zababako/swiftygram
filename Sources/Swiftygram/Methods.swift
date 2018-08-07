//
// Created by Zap on 07.08.2018.
//

import Foundation

enum Method {
    case getMe

    var name: String {
        switch self {
        case .getMe: return "getMe"
        }
    }
}

enum MethodError: Error {
    case baseUrlCompositionFailure
}

/// https://core.telegram.org/bots/api#making-requests

func composeRequest(for endpoint: Method, with token: Bot.Token) throws -> URLRequest {

    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "api.telegram.org"

    guard let base = urlComponents.url else {
        throw MethodError.baseUrlCompositionFailure
    }

    let authenticated = base.appendingPathComponent("bot\(token)")

    let located = authenticated.appendingPathComponent(endpoint.name)

    return URLRequest(url: located)
}
