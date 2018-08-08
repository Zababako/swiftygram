//
// Created by Zap on 07.08.2018.
//


/// This object represents a Telegram user or bot
/// https://core.telegram.org/bots/api#user

public struct User: Decodable {

    public let id: ReceiverID

    public let username:  String?
    public let firstName: String?
    public let lastName:  String?
}