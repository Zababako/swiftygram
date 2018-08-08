//
// Created by Zap on 07.08.2018.
//


/// This object represents Chat
/// https://core.telegram.org/bots/api#chat

public struct Chat: Codable {

    public enum `Type`: String, Codable {
        case `private`
        case group
        case supergroup
        case channel
    }

    public typealias ID = Int64

    public let id: ID
    public let type: `Type`

    public let title:     String?
    public let username:  String?
    public let firstName: String?
    public let lastName:  String?
}
