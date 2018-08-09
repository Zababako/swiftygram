//
// Created by Zap on 07.08.2018.
//

import Foundation


public enum Receiver: Encodable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {

    public typealias ID = Int64

    case id(ID)
    case channelName(String)

    init?(value: Any) {

        switch value {
        case let x as Receiver.ID:
            self = .id(x)

        case let x as String:
            if let intFromString = Int64(x) {
                self = .id(intFromString)
            } else {
                self = .channelName(x)
            }

        default:
            return nil
        }
    }


    // MARK: - Encodable

    public func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()

        switch self {
        case .id(let id):
            try container.encode(id)

        case .channelName(let username):
            try container.encode(
                username.hasPrefix("@") ? username : ("@" + username)
            )
        }
    }


    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self = .channelName(value)
    }


    // MARK: - ExpressibleByIntegerLiteral

    public init(integerLiteral value: Int64) {
        self = .id(value)
    }
}

