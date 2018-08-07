//
// Created by Zap on 07.08.2018.
//

enum Result<T>{
    case success(T)
    case failure(Error)
}

extension Result {

    func map<U>(_ transformation: (T) -> U) -> Result<U> {
        switch self {
        case .failure(let error): return Result<U>.failure(error)
        case .success(let x):     return Result<U>.success(transformation(x))
        }
    }
}

