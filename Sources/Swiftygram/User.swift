//
// Created by Zap on 07.08.2018.
//

import Foundation

public struct User: Codable {

    public typealias ID = Int64

    public let id: ID

    public let username:  String?
    public let firstName: String?
    public let lastName:  String?
}