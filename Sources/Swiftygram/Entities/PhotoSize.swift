//
// Created by Zap on 11.08.2018.
//

/// This object represents one size of a photo or a file / sticker thumbnail.
/// https://core.telegram.org/bots/api#photosize

public struct PhotoSize: Decodable {

    public let fileId: String

    public let width:    Int64
    public let height:   Int64
    public let fileSize: Int64?
}

