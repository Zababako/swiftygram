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


protocol API {
    func send<T: Decodable>(request: URLRequest, onComplete: @escaping (Result<T>) -> Void)
}

private struct Response<T: Decodable>: Decodable {
    let ok:          Bool
    let result:      T?
    let description: String?
    let errorCode:   Int?
}

final internal class APIClient: API {


    // MARK: - Private properties

    private let session: URLSession

    private let decoder: JSONDecoder = {

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return decoder
    }()

    private let encoder: JSONEncoder = {

        let decoder = JSONEncoder()
        decoder.keyEncodingStrategy = .convertToSnakeCase

        return decoder
    }()


    // MARK: - Initialization / Deinitialization

    init(configuration: URLSessionConfiguration) {
        session = URLSession(configuration: configuration)
    }


    // MARK: - API

    func send<T: Decodable>(request: URLRequest, onComplete: @escaping (Result<T>) -> Void) {

        let task = session.dataTask(with: request) {
            [decoder]
            (possibleData, possibleResponse, possibleError) in

            do {

                if let error = possibleError { throw error }

                guard let data = possibleData else { throw APIError("Missing data") }

                let response = try decoder.decode(Response<T>.self, from: data)

                guard let result = response.result else {
                    throw APIError(text: response.description, code: response.errorCode)
                }

                onComplete(.success(result))
            } catch {
                onComplete(.failure(error))
            }

        }

        task.resume()
    }
}