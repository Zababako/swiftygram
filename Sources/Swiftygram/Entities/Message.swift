//
// Created by Zap on 07.08.2018.
//

/// This object represents a message
/// https://core.telegram.org/bots/api#message

public struct Message: Codable {

    public typealias ID = Int64

    public let messageId: ID

    public let from: User?
    public let date: Int64
    public let chat: Chat
}
