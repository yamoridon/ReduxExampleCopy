//
//  APIDomainError.swift
//  ReduxExampleCopy
//
//  Created by Kazuki Ohara on 2019/02/25.
//  Copyright © 2019 Kazuki Ohara. All rights reserved.
//

import Foundation
import Alamofire
import GitHubAPI
import HTTPStatusCodes

// swiftlint:disable identifier_name
let Unreachable = "Unreachable"
// swiftlint:enable identifier_name

public struct NetworkError: Error, Equatable {
    public let message: String
    public let identifier = UUID().uuidString
    public let code: Int
    public let nsError: NSError?

    internal init(_ nsError: NSError) {
        self.message = nsError.localizedDescription
        self.code = nsError.code
        self.nsError = nsError
    }

    internal init(message: String = "", code: Int = -1) {
        self.message = message
        self.code = code
        self.nsError = nil
    }

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        if lhs.identifier == rhs.identifier {
            return true
        } else {
            return lhs.code == rhs.code
        }
    }
}

public struct ResponseError: Error, Equatable {
    public let statusCode: Int
    public let data: Data?
    public let error: Error

    internal init(statusCode: Int, data: Data?, error: Error) {
        self.statusCode = statusCode
        self.data = data
        self.error = error
    }

    public static func == (lhs: ResponseError, rhs: ResponseError) -> Bool {
        if lhs.statusCode == HTTPStatusCode.badRequest.rawValue && rhs.statusCode == HTTPStatusCode.badRequest.rawValue {
            return lhs.data == rhs.data
        } else {
            return lhs.statusCode == rhs.statusCode
        }
    }

    public func decodeBadRequest<T>(_ type: T.Type) -> T? where T: Decodable {
        guard statusCode == HTTPStatusCode.badRequest.rawValue else { return nil }
        guard let data = data else { return nil }
        return GitHubAPI.CodableHelper.decode(type, from: data).decodableObj
    }

    public var networkError: NetworkError? {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return NetworkError(nsError)
        } else if let afError = error as? Alamofire.AFError {
            switch afError {
            case Alamofire.AFError.responseValidationFailed(let reason):
                switch reason {
                case .unacceptableContentType:
                    return NetworkError(message: "Unacceptable server.", code: -9999)
                default:
                    break
                }
            default:
                break
            }
        }
        return nil
    }
}

public struct UnknownError: Error, Equatable {
    public let identifier = UUID().uuidString
    public let error: Error?

    internal init(_ error: Error? = nil) {
        self.error = error
    }

    public static func == (lhs: UnknownError, rhs: UnknownError) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

public enum APIDomainError: Error, Equatable {
    case response(error: ResponseError)
    case network(error: NetworkError)
    case unknown(error: UnknownError)
    case unreachable

    public static func == (lhs: APIDomainError, rhs: APIDomainError) -> Bool {
        switch (lhs, rhs) {
        case (.response(let errorLhs), .response(let errorRhs)):
            return errorLhs == errorRhs
        case (.network(let errorLhs), .network(let errorRhs)):
            return errorLhs == errorRhs
        case (.unknown(let errorLhs), .unknown(let errorRhs)):
            return errorLhs == errorRhs
        case (.unreachable, unreachable):
            return true
        default:
            return false
        }
    }

    public enum HandleError: Error {
        case networkError
        case internalServerError
        case serviceUnavailable
        case unauthorized
        case getewayTimeout
        case badRequest
        case unknownError
    }

    public var handleError: HandleError {
        if networkError != nil {
            return .networkError
        }
        if responseError?.statusCode == HTTPStatusCode.internalServerError.rawValue {
            return .internalServerError
        }
        if responseError?.statusCode == HTTPStatusCode.serviceUnavailable.rawValue {
            return .serviceUnavailable
        }
        if responseError?.statusCode == HTTPStatusCode.unauthorized.rawValue {
            return .unauthorized
        }
        if responseError?.statusCode == HTTPStatusCode.gatewayTimeout.rawValue {
            return .getewayTimeout
        }
        if responseError?.statusCode == HTTPStatusCode.badRequest.rawValue {
            return .badRequest
        }
        return .unknownError
    }
}

extension APIDomainError {
    public var isNetworkError: Bool {
        return handleError == .networkError
    }

    public var isInternalServerError: Bool {
        return handleError == .internalServerError
    }

    public var isServiceUnavailable: Bool {
        return handleError == .serviceUnavailable
    }

    public var isUnauthorized: Bool {
        return handleError == .unauthorized
    }

    public var isGatewayTimeout: Bool {
        return handleError == .getewayTimeout
    }

    public var isBadRequest: Bool {
        return handleError == .badRequest
    }
}

extension APIDomainError {
    public var responseError: ResponseError? {
        if case .response(let error) = self {
            return error
        } else {
            return nil
        }
    }

    public var networkError: NetworkError? {
        if case .network(let error) = self {
            return error
        } else {
            return nil
        }
    }

    public var unknownError: UnknownError? {
        if case .unknown(let error) = self {
            return error
        } else {
            return nil
        }
    }
}
