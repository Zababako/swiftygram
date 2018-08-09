//
// Created by Zap on 07.08.2018.
//

import Foundation

enum MethodError: Error {
    case baseUrlCompositionFailure
}

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


