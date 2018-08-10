//
// Created by Zap on 07.08.2018.
//

import Foundation

public struct Update: Decodable {

    public typealias ID = Int64

    public let updateId: ID

    public let message:           Message?
    public let editedMessage:     Message?
    public let channelPost:       Message?
    public let editedChannelPost: Message?
}

internal extension Update.ID {
    var next: Update.ID {
        return self.advanced(by: 1)
    }
}