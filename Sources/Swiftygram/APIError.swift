//
// Created by Zap on 07.08.2018.
//

import Foundation

public struct APIError: Error {
    let text: String?
    let code: Int?
}

extension APIError {

    init() {
        self.text = nil
        self.code = nil
    }

    init(_ text: String) {
        self.text = text
        self.code = nil
    }
}

