//
// Created by Zap on 11.08.2018.
//


/// This object represents a general file (as opposed to photos,
/// voice messages and audio files).
/// https://core.telegram.org/bots/api#document

public struct Document: Decodable {

    public let fileId: String

    public let thumb:    PhotoSize?
    public let fileName: String?
    public let mimeType: String?
    public let fileSize: Int64?
}


