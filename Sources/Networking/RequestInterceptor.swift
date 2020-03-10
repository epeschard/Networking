//
//  RequestInterceptor.swift
//  Networking
//
//  Created by Eugene Peschard on 10/03/2020.
//

import Foundation

// MARK: - RequestInterceptor

/// Type that provides both `RequestAdapter` and `RequestRetrier` functionality.
public protocol RequestInterceptor: RequestAdapter, RequestRetrier {}

extension RequestInterceptor {
    public func adapt(_ urlRequest: URLRequest,
                      for session: Session,
                      completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(urlRequest))
    }

    public func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
}

/// A type that can inspect and optionally adapt a `URLRequest` in some manner if necessary.
public protocol RequestAdapter {
    /// Inspects and adapts the specified `URLRequest` in some manner and calls the completion handler with the Result.
    ///
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` to adapt.
    ///   - session:    The `Session` that will execute the `URLRequest`.
    ///   - completion: The completion handler that must be called when adaptation is complete.
    func adapt(_ urlRequest: URLRequest,
               for session: Session,
               completion: @escaping (Result<URLRequest, Error>) -> Void)
}

/// A type that determines whether a request should be retried after being executed by the specified session manager
/// and encountering an error.
public protocol RequestRetrier {
    /// Determines whether the `Request` should be retried by calling the `completion` closure.
    ///
    /// This operation is fully asynchronous. Any amount of time can be taken to determine whether the request needs
    /// to be retried. The one requirement is that the completion closure is called to ensure the request is properly
    /// cleaned up after.
    ///
    /// - Parameters:
    ///   - request:    `Request` that failed due to the provided `Error`.
    ///   - session:    `Session` that produced the `Request`.
    ///   - error:      `Error` encountered while executing the `Request`.
    ///   - completion: Completion closure to be executed when a retry decision has been determined.
    func retry(_ request: Request,
               for session: Session,
               dueTo error: Error,
               completion: @escaping (RetryResult) -> Void)
}

// MARK: - RetryResult

/// Outcome of determination whether retry is necessary.
public enum RetryResult {
    /// Retry should be attempted immediately.
    case retry
    /// Retry should be attempted after the associated `TimeInterval`.
    case retryWithDelay(TimeInterval)
    /// Do not retry.
    case doNotRetry
    /// Do not retry due to the associated `Error`.
    case doNotRetryWithError(Error)
}

extension RetryResult {
    var retryRequired: Bool {
        switch self {
        case .retry, .retryWithDelay: return true
        default: return false
        }
    }

    var delay: TimeInterval? {
        switch self {
        case let .retryWithDelay(delay): return delay
        default: return nil
        }
    }

    var error: Error? {
        guard case let .doNotRetryWithError(error) = self else { return nil }
        return error
    }
}

// MARK: - RequestInterceptor

final class RequestInterceptor: RequestInterceptor {
    private let storage: AccessTokenStorage

    init(storage: AccessTokenStorage) {
        self.storage = storage
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard urlRequest.url?.absoluteString.hasPrefix("https://api.authenticated.com") == true else {
            /// If the request does require authentication, we can directly return it as unmodified.
            return completion(.success(urlRequest))
        }
        var urlRequest = urlRequest

        /// Set the Authorization header value using the access token.
        urlRequest.setValue("token " + storage.accessToken, forHTTPHeaderField: "Authorization")

        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }

        refreshToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let token):
                self.storage.accessToken = token
                /// After updating the token we can safily retry the original request.
                completion(.retry)
            case .failure(let error):
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
