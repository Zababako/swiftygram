//
// Created by Zap on 07.08.2018.
//

import Foundation

class WeakBox<T: AnyObject>: Hashable {

    weak var value: T?

    init(_ value: T) {
        self.value = value
    }


    // MARK: - Hashable

    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

func ==<T>(lhs: WeakBox<T>, rhs: WeakBox<T>) -> Bool {
    return lhs === rhs
}
