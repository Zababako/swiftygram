//
// Created by Zap on 01.08.2018.
//

import Foundation

public func readFromEnvironment(_ identifier: String) -> String? {

    if let value = ProcessInfo.processInfo.environment[identifier] {
        return value
    }

    if let value = try? String(contentsOfFile: identifier) {
        return value
    }

    return nil
}

extension DispatchQueue {

    func asyncAfter(
        seconds:      TimeInterval,
        qos:          DispatchQoS = .default,
        flags:        DispatchWorkItemFlags = [],
        execute work: @escaping @convention(block) () -> Swift.Void
    ) {
        asyncAfter(
            deadline: .now() + seconds,
            qos:      qos,
            flags:    flags,
            execute:  work
        )
    }
}

