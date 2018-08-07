//
// Created by Zap on 01.08.2018.
//

import Foundation

func readFromEnvironment(_ identifier: String) -> String? {

    if let value = ProcessInfo.processInfo.environment[identifier] {
        return value
    }

    if let value = try? String(contentsOfFile: identifier) {
        return value
    }

    return nil
}