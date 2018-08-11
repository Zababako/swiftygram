//
// Created by Zap on 07.08.2018.
//

/// This object represents a message
/// https://core.telegram.org/bots/api#message

public struct Message: Decodable {

    public typealias ID = Int64

    public let messageId: ID

    public let from: User?
    public let date: Int64
    public let chat: Chat

    public let forwardFrom:          User?
    public let forwardFromChat:      Chat?
    public let forwardFromMessageId: Message.ID?
    public let forwardSignature:     String?
    public let forwardDate:          Int64?

//    public let replyToMessage: Message? // TODO: figure out what to do with recursion
    public let editDate:       Int64?
    public let mediaGroupId:   String?

    public let authorSignature: String?
    public let text:            String?

    public let document: Document?
}
