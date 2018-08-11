//
// Created by Zap on 07.08.2018.
//

public enum Result<T>{
    case success(T)
    case failure(Error)
}

public extension Result {

    func map<U>(_ transformation: (T) throws -> U) rethrows -> Result<U> {
        switch self {
        case .failure(let error): return Result<U>.failure(error)
        case .success(let x):     return Result<U>.success(try transformation(x))
        }
    }

    func choose<U>(ifSuccess sValue: U, ifFailure fValue: U) -> U {
        switch self {
        case .success: return sValue
        case .failure: return fValue
        }
    }

    @discardableResult
    func onSuccess(handler: (T) throws -> Void) rethrows -> Result<T> {
        if case .success(let x) = self { try handler(x) }
        return self
    }

    @discardableResult
    func onFailure(handler: (Error) throws -> Void) rethrows -> Result<T> {
        if case .failure(let error) = self { try handler(error) }
        return self
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

