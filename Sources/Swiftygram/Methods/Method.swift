//
// Created by Zap on 07.08.2018.
//

import Foundation

enum APIMethodError: Error {
    case baseUrlCompositionFailure
}

struct APIMethod {

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

        let parseMode:             ParseMode?
        let disableWebPagePreview: Bool?
        let disableNotification:   Bool?
        let replyToMessageId:      Message.ID?
    }
}

internal extension Method.SendMessage {
    init(chatId: Receiver, text: String) {
        self.init(
            chatId:                chatId,
            text:                  text,
            parseMode:             nil,
            disableWebPagePreview: nil,
            disableNotification:   nil,
            replyToMessageId:      nil
        )
    }
}

/// https://core.telegram.org/bots/api#replymarkup
public enum ReplyMarkup: Encodable {
    case inlineKeyboard(InlineKeyboardMarkup)
    case replyKeyboard(ReplyKeyboardMarkup)
    case replyKeyboardRemove(ReplyKeyboardRemove)
    case forceReply(ForceReply)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .forceReply(let reply):             try container.encode(reply)
        case .inlineKeyboard(let keyboard):      try container.encode(keyboard)
        case .replyKeyboard(let keyboard):       try container.encode(keyboard)
        case .replyKeyboardRemove(let keyboard): try container.encode(keyboard)
        }
    }
}

public enum ParseMode: String, Encodable {
    case markdown
    case html
}

/// https://core.telegram.org/bots/api#inlinekeyboardmarkup
public struct InlineKeyboardMarkup: Encodable {

    public let inlineKeyboard: [[InlineKeyboardButton]]

    public struct InlineKeyboardButton: Encodable {

        public let text: String

        public let url:          String?
        public let callbackData: String?

        public let switchInlineQuery:            String?
        public let switchInlineQueryCurrentChat: String?

        public let callbackGame: String?

        public let pay: Bool?
    }
}

/// https://core.telegram.org/bots/api#replykeyboardmarkup
public struct ReplyKeyboardMarkup: Encodable {
    public let keyboard:        [[KeyboardButton]]
    public let resizeKeyboard:  Bool?
    public let oneTimeKeyboard: Bool?
    public let selective:       Bool?
}

/// https://core.telegram.org/bots/api#keyboardbutton
public struct KeyboardButton: Encodable {
    public let text:            String
    public let requestContact:  Bool?
    public let requestLocation: Bool?
}

/// https://core.telegram.org/bots/api#replykeyboardremove
public struct ReplyKeyboardRemove: Encodable {
    public let removeKeyboard: Bool = true
    public let selective:      Bool?
}

/// https://core.telegram.org/bots/api#forcereply
public struct ForceReply: Encodable {
    public let forceReply: Bool = true
    public let selective:  Bool?
}
