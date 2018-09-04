//
// Created by Zap on 07.08.2018.
//

import Foundation

enum APIMethodError: Error {
    case baseUrlCompositionFailure
    case stringEncodingFailed(String)
}

struct APIMethod {

    struct GetUpdates: Requestable, Encodable, Contentable, Locatable {
        let offset:         Update.ID?
        let limit:          Int?
        let timeout:        Int?
        let allowedUpdates: [String]?

        init(
            offset:         Update.ID? = nil,
            limit:          Int?       = nil,
            timeout:        Int?       = nil,
            allowedUpdates: [String]?  = nil
        ) {
            self.offset         = offset
            self.limit          = limit
            self.timeout        = timeout
            self.allowedUpdates = allowedUpdates
        }

        // TODO: remove once convertToSnakeCase is implemented on Linux
        //       https://bugs.swift.org/browse/SR-7180
        enum CodingKeys: String, CodingKey {
            case offset
            case limit
            case timeout
            case allowedUpdates = "allowed_updates"
        }
    }

    struct GetMe: Requestable, Encodable, Contentable, Locatable {}

    struct SendMessage: Requestable, Encodable, Contentable, Locatable {

        let chatId: Receiver
        let text:   String

        let parseMode:             ParseMode?
        let disableWebPagePreview: Bool?
        let disableNotification:   Bool?
        let replyToMessageId:      Message.ID?
        let replyMarkup:           ReplyMarkup?

        // TODO: remove once convertToSnakeCase is implemented on Linux
        //       https://bugs.swift.org/browse/SR-7180
        enum CodingKeys: String, CodingKey {
            case chatId                = "chat_id"
            case text
            case parseMode             = "parse_mode"
            case disableWebPagePreview = "disable_web_page_preview"
            case disableNotification   = "disable_notification"
            case replyToMessageId      = "reply_to_message_id"
            case replyMarkup           = "reply_markup"
        }
    }

    struct SendDocument: Requestable, Contentable, Locatable {

        let chatId:   Receiver
        let document: DocumentToSend

		let thumb:   DocumentToSend?
        let caption: String?

        let parseMode:           ParseMode?
        let disableNotification: Bool?
        let replyToMessageId:    Message.ID?
        let replyMarkup:         ReplyMarkup?
    }
}

public enum DocumentToSend {
    case file(name: String, data: Data)
    case reference(String)
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

        public init(
            text:                         String,
            url:                          String? = nil,
            callbackData:                 String? = nil,
            switchInlineQuery:            String? = nil,
            switchInlineQueryCurrentChat: String? = nil,
            callbackGame:                 String? = nil,
            pay:                          Bool?   = nil
        ) {
            self.text                         = text
            self.url                          = url
            self.callbackData                 = callbackData
            self.switchInlineQuery            = switchInlineQuery
            self.switchInlineQueryCurrentChat = switchInlineQueryCurrentChat
            self.callbackGame                 = callbackGame
            self.pay                          = pay
        }

        // TODO: remove once convertToSnakeCase is implemented on Linux
        //       https://bugs.swift.org/browse/SR-7180
        enum CodingKeys: String, CodingKey {
            case text
            case url
            case callbackData                 = "callback_data"
            case switchInlineQuery            = "switch_inline_query"
            case switchInlineQueryCurrentChat = "switch_inline_query_current_chat"
            case callbackGame                 = "callback_game"
            case pay
        }
    }
}

/// https://core.telegram.org/bots/api#replykeyboardmarkup
public struct ReplyKeyboardMarkup: Encodable {
    public let keyboard:        [[KeyboardButton]]
    public let resizeKeyboard:  Bool?
    public let oneTimeKeyboard: Bool?
    public let selective:       Bool?

    public init(
        keyboard:        [[KeyboardButton]],
        resizeKeyboard:  Bool? = nil,
        oneTimeKeyboard: Bool? = nil,
        selective:       Bool? = nil
    ) {
        self.keyboard        = keyboard
        self.resizeKeyboard  = resizeKeyboard
        self.oneTimeKeyboard = oneTimeKeyboard
        self.selective       = selective
    }

    // TODO: remove once convertToSnakeCase is implemented on Linux
    //       https://bugs.swift.org/browse/SR-7180
    enum CodingKeys: String, CodingKey {
        case keyboard
        case resizeKeyboard  = "resize_keyboard"
        case oneTimeKeyboard = "one_time_keyboard"
        case selective
    }
}

/// https://core.telegram.org/bots/api#keyboardbutton
public enum KeyboardButton: Encodable {
    case plain(String)
    case requestContact(String)
    case requestLocation(String)

    public func encode(to encoder: Encoder) throws {

        switch self {
        case .plain(let text):
            var container = encoder.singleValueContainer()
            try container.encode(text)
        case .requestLocation(let text):
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(true, forKey: .requestLocation)
            try container.encode(text, forKey: .text)
        case .requestContact(let text):
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(true, forKey: .requestContact)
            try container.encode(text, forKey: .text)
        }

    }

    private enum Keys: String, CodingKey {
        case text
        case requestContact  = "request_contact"
        case requestLocation = "request_location"
    }
}

/// https://core.telegram.org/bots/api#replykeyboardremove
public struct ReplyKeyboardRemove: Encodable {
    public let removeKeyboard: Bool
    public let selective:      Bool?

    public init(removeKeyboard: Bool = true, selective: Bool? = nil) {
        self.removeKeyboard = removeKeyboard
        self.selective      = selective
    }

    // TODO: remove once convertToSnakeCase is implemented on Linux
    //       https://bugs.swift.org/browse/SR-7180
    enum CodingKeys: String, CodingKey {
        case removeKeyboard = "remove_keyboard"
        case selective
    }
}

/// https://core.telegram.org/bots/api#forcereply
public struct ForceReply: Encodable {
    public let forceReply: Bool
    public let selective:  Bool?

    public init(forceReply: Bool = true, selective: Bool? = nil) {
        self.forceReply = forceReply
        self.selective  = selective
    }

    // TODO: remove once convertToSnakeCase is implemented on Linux
    //       https://bugs.swift.org/browse/SR-7180
    enum CodingKeys: String, CodingKey {
        case forceReply = "force_reply"
        case selective
    }
}


internal extension APIMethod.SendMessage {
    init(chatId: Receiver, text: String) {
        self.init(
            chatId:                chatId,
            text:                  text,
            parseMode:             nil,
            disableWebPagePreview: nil,
            disableNotification:   nil,
            replyToMessageId:      nil,
            replyMarkup:           nil
        )
    }
}

internal extension APIMethod.SendDocument {
    init(chatId: Receiver, document: DocumentToSend) {
        self.init(
            chatId:              chatId,
            document:            document,
            thumb:               nil,
            caption:             nil,
            parseMode:           nil,
            disableNotification: nil,
            replyToMessageId:    nil,
            replyMarkup:         nil
        )
    }
}
