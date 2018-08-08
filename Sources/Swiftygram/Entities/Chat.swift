//
// Created by Zap on 07.08.2018.
//


/// This object represents Chat
/// https://core.telegram.org/bots/api#chat

public struct Chat: Decodable {

    public enum `Type`: String, Decodable {
        case `private`
        case group
        case supergroup
        case channel
    }

    public let id:   ReceiverID
    public let type: `Type`

    public let title:     String?
    public let username:  String?
    public let firstName: String?
    public let lastName:  String?
}
