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

    public let replyToMessage: MessageRepliedTo?
    public let editDate:       Int64?
    public let mediaGroupId:   String?

    public let authorSignature: String?
    public let text:            String?

    public let document: Document?

    public let caption: String?
}

/// Copy of Message struct, but without replyToMessage field
/// Created to workaround recursion because of Message.replyToMessage
/// According to docs Message in replyToMessage will not contain
/// `replyToMessage` field even if it itself is a reply.

public struct MessageRepliedTo: Decodable {

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

    public let editDate:       Int64?
    public let mediaGroupId:   String?

    public let authorSignature: String?
    public let text:            String?

    public let document: Document?

    public let caption: String?
}
