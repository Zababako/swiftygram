//
// Created by Zap on 07.08.2018.
//

public enum Result<T>{
    case success(T)
    case failure(Error)
}

public extension Result {

    func map<U>(_ transformation: (T) -> U) -> Result<U> {
        switch self {
        case .failure(let error): return Result<U>.failure(error)
        case .success(let x):     return Result<U>.success(transformation(x))
        }
    }

    static func action(
        handler: @escaping (Result<T>) -> Void,
        action: (@escaping (Result<T>) -> Void) throws -> Void
    ) {
        do {
            try action(handler)
        } catch {
            handler(.failure(error))
        }
    }

    static func action(
        handler: @escaping (Result<T>) -> Void,
        action: () throws -> T
    ) {
        do {
            handler(.success(try action()))
        } catch {
            handler(.failure(error))
        }
    }
}

