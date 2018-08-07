//
// Created by Zap on 07.08.2018.
//


/// This object represents a Telegram user or bot
/// https://core.telegram.org/bots/api#user

public struct User: Codable {

    public typealias ID = Int64

    public let id: ID

    public let username:  String?
    public let firstName: String?
    public let lastName:  String?
}