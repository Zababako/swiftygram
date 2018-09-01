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
                self = .channelName(Receiver.normalizedChannelName(x))
            }

        default:
            return nil
        }
    }

    func data() throws -> Data {

        let possibleData: Data?
        switch self {
        case .id(let id):            possibleData = "\(id)".data(using: .utf8, allowLossyConversion: false)
        case .channelName(let name): possibleData = name.data(using: .utf8, allowLossyConversion: false)
        }

        guard let result = possibleData else {
            throw APIMethodError.stringEncodingFailed(String(describing: self))
        }

        return result
    }

    static func normalizedChannelName(_ name: String) -> String {
        return name.hasPrefix("@") ? name : ("@" + name)
    }


    // MARK: - Encodable

    public func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()

        switch self {
        case .id(let id):
            try container.encode(id)

        case .channelName(let username):
            try container.encode(username)
        }
    }


    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self = .channelName(Receiver.normalizedChannelName(value))
    }


    // MARK: - ExpressibleByIntegerLiteral

    public init(integerLiteral value: Int64) {
        self = .id(value)
    }
}

