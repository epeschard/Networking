//
//  Agent.swift
//  Networking
//
//  Created by Vadim Bulavin on 25.11.2019.
//  Copyright © 2019 Vadim Bulavin. All rights reserved.
//

import Foundation

struct Agent {
    struct Response<T> {
        let value: T
        let response: URLResponse
    }
}

enum AgentError: Error {
    case type1
    case type2
}

#if canImport(Combine)
import Combine

extension Agent {
    @available(OSX 10.15, iOS 13, watchOS 6, *)
    func run<T: Decodable>(_ request: URLRequest,
                           _ decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<Response<T>, Error> {
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .tryMap { result -> Response<T> in
                let value = try decoder.decode(T.self, from: result.data)
                return Response(value: value, response: result.response)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
#else
extension Agent {
    func run<T: Decodable>(_ request: URLRequest,
                           _ decoder: JSONDecoder = JSONDecoder()) -> Result<Response<T>, AgentError> {
            URLSession.shared.dataTask(with: request) {
                data, urlResponse, error in
                if let error = error {
                    return .failure(.type1)
                }
                guard
                    let data = data,
                    let urlResponse = urlResponse else {
                        return .failure(.type2)
                }
                let value = try decoder.decode(T.self,
                                               from: data)
                let response = Response(value: value,
                                        response: urlResponse)
                return .success(response)
            }
    }
}
#endif
