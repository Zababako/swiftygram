//
// Created by Zap on 07.08.2018.
//

import Foundation


public enum Receiver {

    public typealias ID = Int64

    case id(ID)
    case username(String)
}

public extension Receiver {

    init?(value: Any) {

        switch value {
        case let x as Receiver.ID:
            self = .id(x)

        case let x as String:
            if let intFromString = Int64(x) {
                self = .id(intFromString)
            } else {
                self = .username(x)
            }

        default:
            return nil
        }
    }
}



